#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


DESIGN_SIZE = (540, 960)
STATE_RECT = (0, 840, 540, 960)
CAPSULE_RECT = (34, 22, 506, 100)
SELECTION_SOURCE_RECT = (54, 0, 182, 112)
CAPSULE_SAMPLE_RANGES = (
    (184, 224),
    (320, 360),
    (454, 486),
)
FOREGROUND_BOXES = {
    "start": {
        "icon": (92, 16, 144, 64),
        "text": (94, 72, 142, 98),
    },
    "character": {
        "icon": (230, 8, 310, 64),
        "text": (235, 65, 305, 99),
    },
    "compendium": {
        "icon": (368, 8, 448, 64),
        "text": (374, 65, 442, 99),
    },
}


def _rounded_rect_mask(
    size: tuple[int, int],
    rect: tuple[int, int, int, int],
    radius: int,
    inset: int = 0,
) -> Image.Image:
    scale = 4
    left, top, right, bottom = rect
    left += inset
    top += inset
    right -= inset
    bottom -= inset
    mask = Image.new("L", (size[0] * scale, size[1] * scale), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (left * scale, top * scale, right * scale, bottom * scale),
        radius=max(0, radius - inset) * scale,
        fill=255,
    )
    return mask.resize(size, Image.Resampling.LANCZOS)


def _ellipse_mask(size: tuple[int, int]) -> Image.Image:
    scale = 4
    mask = Image.new("L", (size[0] * scale, size[1] * scale), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse(
        (0, 0, size[0] * scale - 1, size[1] * scale - 1),
        fill=255,
    )
    return mask.resize(size, Image.Resampling.LANCZOS)


def _foreground_layer(
    image: Image.Image,
    box: tuple[int, int, int, int],
    page_id: str,
    part: str,
) -> Image.Image:
    crop = image.crop(box).convert("RGBA")
    pixels = np.asarray(crop).astype(np.float32)
    rgb = pixels[..., :3]
    red, green, blue = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    luminance = red * 0.299 + green * 0.587 + blue * 0.114
    if page_id == "character" and part == "icon":
        warm = (red > 62.0) & (green > 54.0) & (red + green > blue * 1.35)
        bright = luminance > 74.0
        strength = np.clip((luminance - 52.0) / 70.0, 0.0, 1.0)
        mask = warm & bright
    else:
        warm = (red > 104.0) & (green > 88.0) & (red > blue * 0.72)
        bright = luminance > 100.0
        strength = np.clip((luminance - 82.0) / 78.0, 0.0, 1.0)
        mask = warm & bright
    alpha = np.where(mask, np.maximum(0.38, strength), 0.0) * 255.0
    for global_y in range(20, 25):
        local_y = global_y - box[1]
        if local_y < 0 or local_y >= alpha.shape[0]:
            continue
        alpha[local_y] = 0.0
    for global_y in range(96, 100):
        local_y = global_y - box[1]
        if 0 <= local_y < alpha.shape[0]:
            alpha[local_y] = 0.0
    alpha_image = Image.fromarray(alpha.astype(np.uint8), mode="L").filter(
        ImageFilter.GaussianBlur(0.45)
    )
    result = crop.copy()
    result.putalpha(alpha_image)
    return result


def _selection_without_content(image: Image.Image) -> Image.Image:
    selection = image.crop(SELECTION_SOURCE_RECT).convert("RGBA")
    source = np.asarray(selection).astype(np.float32)
    clean = source.copy()
    height, width = source.shape[:2]
    center = np.array([(width - 1) * 0.5, (height - 1) * 0.5])
    local_boxes = [
        (30, 8, 98, 68),
        (29, 65, 99, 103),
        (32, 18, 96, 27),
    ]
    mask = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(mask)
    for box in local_boxes:
        draw.rounded_rectangle(box, radius=8, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(3.0))
    mask_array = np.asarray(mask).astype(np.float32) / 255.0
    yy, xx = np.mgrid[0:height, 0:width]
    radius_map = np.sqrt((xx - center[0]) ** 2 + (yy - center[1]) ** 2)
    content_mask = np.zeros((height, width), dtype=bool)
    for left, top, right, bottom in local_boxes:
        content_mask[top:bottom, left:right] = True
    radial_colors: dict[int, np.ndarray] = {}
    maximum_radius = int(np.ceil(np.max(radius_map)))
    for radius in range(maximum_radius + 1):
        ring = np.abs(radius_map - float(radius)) <= 1.25
        ring &= ~content_mask
        ring &= source[..., 3] > 20
        samples = source[ring]
        if samples.size == 0:
            radial_colors[radius] = np.array([9.0, 99.0, 111.0, 255.0])
            continue
        luminance = (
            samples[:, 0] * 0.299
            + samples[:, 1] * 0.587
            + samples[:, 2] * 0.114
        )
        samples = samples[luminance < 185.0]
        if samples.size == 0:
            samples = source[ring]
        radial_colors[radius] = np.median(samples, axis=0)
    radial_fill = source.copy()
    for y in range(height):
        for x in range(width):
            radius = min(maximum_radius, int(round(radius_map[y, x])))
            radial_fill[y, x] = radial_colors[radius]
    blend = mask_array[..., None]
    clean = source * (1.0 - blend) + radial_fill * blend
    result = Image.fromarray(np.clip(clean, 0, 255).astype(np.uint8), mode="RGBA")
    shape_alpha = _ellipse_mask(result.size)
    original_alpha = np.asarray(result.getchannel("A"), dtype=np.uint16)
    ellipse_alpha = np.asarray(shape_alpha, dtype=np.uint16)
    result.putalpha(
        Image.fromarray(
            ((original_alpha * ellipse_alpha) // 255).astype(np.uint8),
            mode="L",
        )
    )
    return result


def _capsule_fill(reference: Image.Image, background: Image.Image) -> Image.Image:
    reference_pixels = np.asarray(reference.convert("RGB"), dtype=np.float32)
    background_pixels = np.asarray(background.convert("RGB"), dtype=np.float32)
    fill_pixels = background_pixels.copy()
    left, top, right, bottom = CAPSULE_RECT
    sample_x = np.concatenate(
        [np.arange(start, end) for start, end in CAPSULE_SAMPLE_RANGES]
    )
    for y in range(top, bottom):
        reference_row = reference_pixels[y, sample_x]
        background_row = background_pixels[y, sample_x]
        reference_median = np.median(reference_row, axis=0)
        background_median = np.median(background_row, axis=0)
        background_variation = (
            background_pixels[y, left:right] - background_median
        ) * 0.18
        fill_pixels[y, left:right] = np.clip(
            reference_median + background_variation,
            0.0,
            255.0,
        )
    fill = Image.fromarray(fill_pixels.astype(np.uint8), mode="RGB").convert("RGBA")
    fill.putalpha(_rounded_rect_mask(reference.size, CAPSULE_RECT, 39, 1))
    return fill


def _clean_base(reference: Image.Image, background: Image.Image) -> Image.Image:
    result = background.copy().convert("RGBA")
    shadow_mask = _rounded_rect_mask(reference.size, CAPSULE_RECT, 39)
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(5.0))
    shadow = Image.new("RGBA", reference.size, (0, 10, 19, 0))
    shadow.putalpha(shadow_mask.point(lambda value: int(value * 0.46)))
    result.alpha_composite(shadow, (0, 3))
    result.alpha_composite(_capsule_fill(reference, background))
    outer_mask = _rounded_rect_mask(reference.size, CAPSULE_RECT, 39)
    inner_mask = _rounded_rect_mask(reference.size, CAPSULE_RECT, 39, 2)
    border_alpha = np.clip(
        np.asarray(outer_mask, dtype=np.int16)
        - np.asarray(inner_mask, dtype=np.int16),
        0,
        255,
    ).astype(np.uint8)
    border = Image.new("RGBA", reference.size, (232, 184, 77, 0))
    border.putalpha(Image.fromarray(border_alpha, mode="L"))
    result.alpha_composite(border)
    highlight_outer = _rounded_rect_mask(reference.size, CAPSULE_RECT, 39, 3)
    highlight_inner = _rounded_rect_mask(reference.size, CAPSULE_RECT, 39, 4)
    highlight_alpha = np.clip(
        np.asarray(highlight_outer, dtype=np.int16)
        - np.asarray(highlight_inner, dtype=np.int16),
        0,
        255,
    ).astype(np.uint8)
    highlight_alpha = (highlight_alpha.astype(np.float32) * 0.32).astype(np.uint8)
    highlight = Image.new("RGBA", reference.size, (255, 229, 156, 0))
    highlight.putalpha(Image.fromarray(highlight_alpha, mode="L"))
    result.alpha_composite(highlight)
    return result


def _variant_base(reference: Image.Image, reconstructed: Image.Image) -> Image.Image:
    left, top, right, bottom = SELECTION_SOURCE_RECT
    removal_mask = Image.new("L", reference.size, 0)
    draw = ImageDraw.Draw(removal_mask)
    draw.ellipse((left - 8, top - 8, right + 8, bottom + 8), fill=255)
    removal_mask = removal_mask.filter(ImageFilter.GaussianBlur(3.0))
    return Image.composite(reconstructed, reference, removal_mask)


def _paste_layer(canvas: Image.Image, layer: Image.Image, box: tuple[int, int, int, int]) -> None:
    canvas.alpha_composite(layer, (box[0], box[1]))


def generate(source_path: Path, background_path: Path, output_dir: Path) -> list[Path]:
    source = Image.open(source_path).convert("RGBA")
    background_source = Image.open(background_path).convert("RGBA")
    logical = source.resize(DESIGN_SIZE, Image.Resampling.BILINEAR)
    background_logical = background_source.resize(DESIGN_SIZE, Image.Resampling.BILINEAR)
    state_source = logical.crop(STATE_RECT).convert("RGBA")
    state_background = background_logical.crop(STATE_RECT).convert("RGBA")
    output_dir.mkdir(parents=True, exist_ok=True)
    for page_id in ["start", "character", "compendium"]:
        legacy_path = output_dir / f"bottom_bar_{page_id}.png"
        legacy_path.unlink(missing_ok=True)
        Path(f"{legacy_path}.import").unlink(missing_ok=True)
    foreground = {}
    for page_id, boxes in FOREGROUND_BOXES.items():
        foreground[page_id] = {
            "icon": _foreground_layer(
                state_source,
                boxes["icon"],
                page_id,
                "icon",
            ),
            "text": _foreground_layer(
                state_source,
                boxes["text"],
                page_id,
                "text",
            ),
        }
    reconstructed_base = _clean_base(state_source, state_background)
    variant_base = _variant_base(state_source, reconstructed_base)
    for foreground_page_id, layers in foreground.items():
        _paste_layer(
            variant_base,
            layers["icon"],
            FOREGROUND_BOXES[foreground_page_id]["icon"],
        )
        _paste_layer(
            variant_base,
            layers["text"],
            FOREGROUND_BOXES[foreground_page_id]["text"],
        )
    base_path = output_dir / "bottom_bar_base.png"
    variant_base.save(base_path)
    selection_path = output_dir / "bottom_bar_selection.png"
    _selection_without_content(state_source).save(selection_path)
    outputs = [base_path, selection_path]
    for page_id, layers in foreground.items():
        content = Image.new("RGBA", state_source.size, (0, 0, 0, 0))
        _paste_layer(content, layers["icon"], FOREGROUND_BOXES[page_id]["icon"])
        _paste_layer(content, layers["text"], FOREGROUND_BOXES[page_id]["text"])
        output_path = output_dir / f"bottom_bar_content_{page_id}.png"
        content.save(output_path)
        outputs.append(output_path)
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("assets/art/ui/home/star_tide_home_reference.png"),
    )
    parser.add_argument(
        "--background",
        type=Path,
        default=Path("assets/art/ui/home/star_harbor_background.png"),
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("assets/art/ui/navigation"),
    )
    args = parser.parse_args()
    outputs = generate(args.source, args.background, args.output_dir)
    for output in outputs:
        print(output)


if __name__ == "__main__":
    main()
