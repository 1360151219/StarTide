#!/usr/bin/env python3

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser(description="Trim transparent padding and resize a generated game asset.")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--max-size", type=int, required=True)
    parser.add_argument("--padding", type=float, default=0.04)
    args = parser.parse_args()

    image = Image.open(args.input).convert("RGBA")
    alpha = image.getchannel("A")
    bounds = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if bounds is None:
        raise ValueError(f"No visible pixels in {args.input}")

    left, top, right, bottom = bounds
    padding = max(2, round(max(right - left, bottom - top) * args.padding))
    bounds = (
        max(0, left - padding),
        max(0, top - padding),
        min(image.width, right + padding),
        min(image.height, bottom + padding),
    )
    image = image.crop(bounds)

    scale = min(1.0, args.max_size / max(image.size))
    if scale < 1.0:
        image = image.resize(
            (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
            Image.Resampling.LANCZOS,
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output, optimize=True)
    print(f"{args.output}: {image.width}x{image.height}")


if __name__ == "__main__":
    main()
