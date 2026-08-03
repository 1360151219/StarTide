#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_ROOT = ROOT / "design" / "ui_psd"
BUILD_ROOT = OUTPUT_ROOT / "build"
SCREEN_ROOT = OUTPUT_ROOT / "screens"
LAYER_ROOT = BUILD_ROOT / "layers"

WIDTH = 540
HEIGHT = 960
GUTTER = 72
GRID_COLUMNS = 3

COLORS = {
    "night": "#002A3A",
    "night_alpha": (0, 42, 58, 238),
    "glass": (0, 42, 58, 235),
    "glass_soft": (5, 62, 72, 220),
    "glass_light": (18, 86, 92, 215),
    "cream": "#FFF5D7",
    "cream_soft": "#FFFAEE",
    "paper": "#F5E7C7",
    "paper_light": "#FFF7E7",
    "ink": "#183640",
    "ink_muted": "#456978",
    "teal": "#087E8B",
    "teal_bright": "#23A5A7",
    "cyan": "#50D8D0",
    "gold": "#E8B84D",
    "gold_light": "#FFE59C",
    "gold_dark": "#8B571B",
    "orange": "#F5760A",
    "orange_dark": "#B74A08",
    "coral": "#F05C5C",
    "green": "#61B74D",
    "locked": "#61706E",
    "white": "#FFFFFF",
}

FONT_SANS = ROOT / "assets" / "fonts" / "NotoSansSC-Regular.otf"
FONT_SANS_BOLD = ROOT / "assets" / "fonts" / "NotoSansSC-VariableFont_wght.ttf"
FONT_SERIF = Path("/System/Library/Fonts/Supplemental/Songti.ttc")

ASSETS = {
    "home_reference": ROOT / "assets" / "art" / "ui" / "home" / "star_tide_home_reference.png",
    "home_background": ROOT / "assets" / "art" / "ui" / "home" / "star_harbor_background.png",
    "meadow_medallion": ROOT / "assets" / "art" / "ui" / "home" / "biome_meadow_medallion.png",
    "primary_button": ROOT / "assets" / "art" / "ui" / "home" / "primary_button_frame.png",
    "warden_idle": ROOT / "assets" / "generated" / "hero_chibi" / "star_warden" / "idle.png",
    "warden_victory": ROOT / "assets" / "generated" / "hero_chibi" / "star_warden" / "victory.png",
    "ember_idle": ROOT / "assets" / "generated" / "hero_chibi" / "ember_ranger" / "idle.png",
    "ember_victory": ROOT / "assets" / "generated" / "hero_chibi" / "ember_ranger" / "victory.png",
    "grub": ROOT / "assets" / "art" / "enemies" / "green_grub.png",
    "slime": ROOT / "assets" / "art" / "enemies" / "starblight_slime.png",
    "bat": ROOT / "assets" / "art" / "enemies" / "duskwing_bat.png",
    "brute": ROOT / "assets" / "art" / "enemies" / "meteor_brute.png",
    "star_lance": ROOT / "assets" / "art" / "skills" / "star_lance.png",
    "frost_tide": ROOT / "assets" / "art" / "skills" / "frost_tide.png",
    "sun_orbit": ROOT / "assets" / "art" / "skills" / "sun_orbit.png",
    "ember_volley": ROOT / "assets" / "art" / "skills" / "ember_volley.png",
    "phoenix_heart": ROOT / "assets" / "art" / "skills" / "phoenix_heart.png",
    "meteor_rain": ROOT / "assets" / "art" / "skills" / "meteor_rain.png",
    "heart": ROOT / "assets" / "art" / "pickups" / "healing_heart.png",
    "magnet": ROOT / "assets" / "art" / "pickups" / "magnet_charm.png",
    "xp": ROOT / "assets" / "art" / "pickups" / "experience_shard.png",
    "weapon": ROOT / "assets" / "generated" / "equipment" / "apprentice_starwand.png",
    "armor": ROOT / "assets" / "generated" / "equipment" / "meadow_guard.png",
    "charm": ROOT / "assets" / "generated" / "equipment" / "windbell_charm.png",
    "victory_crest": ROOT / "assets" / "generated" / "ui" / "victory_crest.png",
    "gameplay_meadow": ROOT / "preview" / "biome_meadow.png",
}


def rgba(value: str | tuple[int, int, int, int], alpha: int | None = None):
    if isinstance(value, tuple):
        if alpha is None:
            return value
        return value[:3] + (alpha,)
    value = value.lstrip("#")
    if len(value) == 6:
        result = tuple(int(value[index:index + 2], 16) for index in (0, 2, 4)) + (255,)
    else:
        result = tuple(int(value[index:index + 2], 16) for index in (0, 2, 4, 6))
    if alpha is not None:
        return result[:3] + (alpha,)
    return result


def font(size: int, bold: bool = False, serif: bool = False):
    path = FONT_SERIF if serif else (FONT_SANS_BOLD if bold else FONT_SANS)
    return ImageFont.truetype(str(path), size=size)


def ensure_dirs():
    if BUILD_ROOT.exists():
        shutil.rmtree(BUILD_ROOT)
    LAYER_ROOT.mkdir(parents=True, exist_ok=True)
    SCREEN_ROOT.mkdir(parents=True, exist_ok=True)


def fit_asset(path: Path, width: int, height: int, crop_alpha: bool = True):
    source = Image.open(path).convert("RGBA")
    if crop_alpha:
        bbox = source.getchannel("A").getbbox()
        if bbox:
            source = source.crop(bbox)
    source.thumbnail((max(1, width), max(1, height)), Image.Resampling.LANCZOS)
    return source


def cover_asset(path: Path, width: int, height: int):
    source = Image.open(path).convert("RGBA")
    scale = max(width / source.width, height / source.height)
    target = source.resize((round(source.width * scale), round(source.height * scale)), Image.Resampling.LANCZOS)
    left = max(0, (target.width - width) // 2)
    top = max(0, (target.height - height) // 2)
    return target.crop((left, top, left + width, top + height))


def rounded_panel_image(box, fill, outline=None, radius=22, width=2, shadow=True):
    left, top, right, bottom = box
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    if shadow:
        shadow_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(shadow_layer)
        draw.rounded_rectangle((left + 1, top + 7, right + 1, bottom + 7), radius=radius, fill=(0, 14, 25, 92))
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(8))
        image.alpha_composite(shadow_layer)
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(box, radius=radius, fill=rgba(fill), outline=rgba(outline) if outline else None, width=width)
    if outline:
        inset = 4
        draw.rounded_rectangle(
            (left + inset, top + inset, right - inset, bottom - inset),
            radius=max(1, radius - inset),
            outline=rgba(COLORS["gold_light"], 88),
            width=1,
        )
    return image


def line_layer(points, fill, width=2, joint="curve"):
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    ImageDraw.Draw(image).line(points, fill=rgba(fill), width=width, joint=joint)
    return image


def star_polygon(center, outer_radius, inner_radius, points=4):
    result = []
    start = -math.pi / 2
    for index in range(points * 2):
        radius = outer_radius if index % 2 == 0 else inner_radius
        angle = start + index * math.pi / points
        result.append((
            center[0] + math.cos(angle) * radius,
            center[1] + math.sin(angle) * radius,
        ))
    return result


def icon_layer(icon_id: str, center, size: int, color, accent=None):
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    x, y = center
    primary = rgba(color)
    secondary = rgba(accent or color)
    line_width = max(2, round(size * 0.07))
    if icon_id == "star":
        draw.polygon(star_polygon(center, size * 0.48, size * 0.16, 4), fill=primary)
    elif icon_id == "music":
        draw.line((x + size * 0.12, y - size * 0.32, x + size * 0.12, y + size * 0.22), fill=primary, width=line_width)
        draw.line((x + size * 0.12, y - size * 0.32, x + size * 0.34, y - size * 0.40), fill=primary, width=line_width)
        draw.ellipse((x - size * 0.12, y + size * 0.12, x + size * 0.14, y + size * 0.36), fill=primary)
    elif icon_id == "pause":
        bar_width = size * 0.16
        draw.rounded_rectangle((x - size * 0.28, y - size * 0.34, x - size * 0.28 + bar_width, y + size * 0.34), radius=bar_width * 0.35, fill=primary)
        draw.rounded_rectangle((x + size * 0.12, y - size * 0.34, x + size * 0.12 + bar_width, y + size * 0.34), radius=bar_width * 0.35, fill=primary)
    elif icon_id == "play":
        draw.polygon([(x - size * 0.22, y - size * 0.32), (x - size * 0.22, y + size * 0.32), (x + size * 0.34, y)], fill=primary)
    elif icon_id == "expedition":
        draw.arc((x - size * 0.34, y - size * 0.36, x + size * 0.34, y + size * 0.32), 190, 350, fill=primary, width=line_width)
        draw.line((x - size * 0.28, y + size * 0.02, x - size * 0.28, y + size * 0.35), fill=primary, width=line_width)
        draw.line((x + size * 0.28, y + size * 0.02, x + size * 0.28, y + size * 0.35), fill=primary, width=line_width)
        draw.line((x - size * 0.36, y + size * 0.35, x + size * 0.36, y + size * 0.35), fill=primary, width=line_width)
        draw.polygon(star_polygon((x, y + size * 0.04), size * 0.17, size * 0.06, 4), fill=secondary)
    elif icon_id == "character":
        draw.ellipse((x - size * 0.16, y - size * 0.34, x + size * 0.16, y - size * 0.02), outline=primary, width=line_width)
        draw.arc((x - size * 0.32, y - size * 0.02, x + size * 0.32, y + size * 0.46), 190, 350, fill=primary, width=line_width)
        draw.polygon(star_polygon((x + size * 0.28, y - size * 0.22), size * 0.11, size * 0.04, 4), fill=secondary)
    elif icon_id == "compendium":
        draw.line((x, y - size * 0.28, x, y + size * 0.34), fill=primary, width=line_width)
        draw.line([(x, y - size * 0.24), (x - size * 0.34, y - size * 0.32), (x - size * 0.34, y + size * 0.26), (x, y + size * 0.34)], fill=primary, width=line_width)
        draw.line([(x, y - size * 0.24), (x + size * 0.34, y - size * 0.32), (x + size * 0.34, y + size * 0.26), (x, y + size * 0.34)], fill=primary, width=line_width)
    return image


class Screen:
    def __init__(self, screen_id: str, title: str, inherits: list[str] | None = None):
        self.screen_id = screen_id
        self.title = title
        self.inherits = list(inherits or [])
        self.layers: list[dict] = []
        self.composite = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        self._layer_index = 0

    def add(self, name: str, image: Image.Image, category: str, text_data=None, hidden=False):
        if image.size != (WIDTH, HEIGHT):
            raise ValueError(f"layer {name} must be {WIDTH}x{HEIGHT}, got {image.size}")
        self.composite = Image.alpha_composite(self.composite, image)
        alpha = image.getchannel("A")
        bbox = alpha.getbbox()
        if not bbox:
            return
        cropped = image.crop(bbox)
        self._layer_index += 1
        filename = f"{self.screen_id}_{self._layer_index:03d}.png"
        path = LAYER_ROOT / filename
        cropped.save(path, optimize=True)
        layer = {
            "name": name,
            "category": category,
            "path": str(path.relative_to(ROOT)),
            "left": bbox[0],
            "top": bbox[1],
            "hidden": hidden,
        }
        if text_data:
            layer["text"] = text_data
        self.layers.append(layer)

    def add_background(self, path: Path, name="背景/星港", darken=0.0, blur=0.0):
        image = cover_asset(path, WIDTH, HEIGHT)
        if blur > 0:
            image = image.filter(ImageFilter.GaussianBlur(blur))
        if darken > 0:
            overlay = Image.new("RGBA", image.size, (0, 12, 24, round(255 * darken)))
            image = Image.alpha_composite(image, overlay)
        self.add(name, image, "01_背景")

    def add_overlay(self, name: str, color, category="02_氛围"):
        image = Image.new("RGBA", (WIDTH, HEIGHT), rgba(color))
        self.add(name, image, category)

    def add_panel(self, name: str, box, fill, outline=None, radius=22, width=2, category="03_组件", shadow=True):
        self.add(name, rounded_panel_image(box, fill, outline, radius, width, shadow), category)

    def add_text(
        self,
        name: str,
        text: str,
        x: int,
        y: int,
        size: int,
        fill,
        width: int | None = None,
        align: str = "left",
        bold: bool = False,
        serif: bool = False,
        stroke_width: int = 0,
        stroke_fill=None,
        category="05_文字",
        editable=True,
        line_spacing=6,
    ):
        image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        text_font = font(size, bold=bold, serif=serif)
        actual_width = width if width else max(1, WIDTH - x)
        bbox = draw.multiline_textbbox((0, 0), text, font=text_font, spacing=line_spacing, align=align, stroke_width=stroke_width)
        text_width = bbox[2] - bbox[0]
        if align == "center":
            draw_x = x + (actual_width - text_width) / 2
        elif align == "right":
            draw_x = x + actual_width - text_width
        else:
            draw_x = x
        draw.multiline_text(
            (draw_x, y),
            text,
            font=text_font,
            fill=rgba(fill),
            spacing=line_spacing,
            align=align,
            stroke_width=stroke_width,
            stroke_fill=rgba(stroke_fill) if stroke_fill else None,
        )
        text_data = None
        if editable:
            color = rgba(fill)
            text_data = {
                "value": text,
                "font": "STSongti-SC-Bold" if serif and bold else (
                    "STSongti-SC-Regular" if serif else ("NotoSansSC-Bold" if bold else "NotoSansSC-Regular")
                ),
                "fontSize": size,
                "fillColor": {"r": color[0], "g": color[1], "b": color[2]},
                "justification": align,
                "transformX": round(draw_x),
                "transformY": y,
            }
        self.add(name, image, category, text_data=text_data)

    def add_image(self, name: str, path: Path, box, category="04_内容", crop_alpha=True, opacity=1.0):
        left, top, right, bottom = box
        asset = fit_asset(path, right - left, bottom - top, crop_alpha=crop_alpha)
        if opacity < 1:
            asset.putalpha(asset.getchannel("A").point(lambda value: round(value * opacity)))
        image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        x = left + (right - left - asset.width) // 2
        y = top + (bottom - top - asset.height) // 2
        image.alpha_composite(asset, (x, y))
        self.add(name, image, category)

    def add_circle(self, name, center, radius, fill, outline=None, width=2, category="03_组件"):
        image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        x, y = center
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=rgba(fill), outline=rgba(outline) if outline else None, width=width)
        self.add(name, image, category)

    def add_line(self, name, points, fill, width=2, category="03_组件"):
        self.add(name, line_layer(points, fill, width), category)

    def add_icon(self, name, icon_id, center, size, color, accent=None, category="04_内容"):
        self.add(name, icon_layer(icon_id, center, size, color, accent), category)

    def save(self):
        target = SCREEN_ROOT / f"{self.screen_id}_{self.title}.png"
        self.composite.convert("RGB").save(target, quality=95)
        return target

    def manifest(self):
        return {
            "id": self.screen_id,
            "title": self.title,
            "width": WIDTH,
            "height": HEIGHT,
            "inherits": self.inherits,
            "layers": self.layers,
        }


HOME_COMPONENT_LIBRARY_ID = "01"
COMMON_COMPONENTS = [
    "01/星潮色彩与字体",
    "01/深青玻璃面板",
    "01/象牙纸张面板",
    "01/金色双描边",
]


def inner_screen(screen_id: str, title: str, *components: str):
    inherited_components = COMMON_COMPONENTS + [f"{HOME_COMPONENT_LIBRARY_ID}/{component}" for component in components]
    return Screen(
        screen_id,
        title,
        inherits=list(dict.fromkeys(inherited_components)),
    )


def add_sound_button(screen: Screen):
    screen.add_panel("声音/胶囊", (398, 20, 516, 66), COLORS["glass"], COLORS["gold"], 23, 2, shadow=True)
    screen.add_icon("声音/音乐图标", "music", (423, 43), 24, COLORS["cream"])
    screen.add_text("声音/文字", "声音", 438, 29, 17, COLORS["cream"], width=64, align="center", bold=True)


def add_primary_action(screen: Screen, name: str, label: str, box, category="03_组件"):
    screen.add_panel(f"{name}/底板", box, COLORS["orange"], COLORS["gold_light"], 22, 2, category)
    screen.add_text(
        f"{name}/文字",
        label,
        box[0],
        box[1] + max(8, (box[3] - box[1] - 30) // 2),
        20,
        COLORS["cream"],
        width=box[2] - box[0],
        align="center",
        bold=True,
        serif=True,
        stroke_width=1,
        stroke_fill=COLORS["orange_dark"],
        category=category,
    )


def add_small_header(screen: Screen, title: str, subtitle: str):
    add_sound_button(screen)
    screen.add_text("页头/标题", title, 28, 46, 42, COLORS["gold_light"], width=360, bold=True, serif=True, stroke_width=1, stroke_fill=COLORS["gold_dark"])
    screen.add_text("页头/副标题", subtitle, 30, 104, 15, COLORS["cream"], width=360, bold=True, stroke_width=1, stroke_fill=COLORS["teal"])
    screen.add_line("页头/左侧星线", [(32, 140), (246, 140)], rgba(COLORS["gold"], 150), 1, "03_组件")
    screen.add_line("页头/右侧星线", [(294, 140), (508, 140)], rgba(COLORS["gold"], 150), 1, "03_组件")
    screen.add_icon("页头/中心星", "star", (270, 140), 18, COLORS["gold_light"], category="03_组件")


def add_bottom_dock(screen: Screen, selected: str):
    screen.add_panel("全局BottomBar/悬浮底座", (36, 864, 504, 940), COLORS["glass"], COLORS["gold"], 38, 2, "06_导航", True)
    centers = [114, 270, 426]
    ids = [("expedition", "远征"), ("character", "角色"), ("compendium", "图鉴")]
    screen.add_line("全局BottomBar/左侧分栏", [(192, 875), (192, 929)], rgba(COLORS["gold_light"], 40), 1, "06_导航")
    screen.add_line("全局BottomBar/右侧分栏", [(348, 875), (348, 929)], rgba(COLORS["gold_light"], 40), 1, "06_导航")
    for index, (tab_id, label) in enumerate(ids):
        active = tab_id == selected
        if active:
            screen.add_circle(f"全局BottomBar/{label}/选中外徽记", (centers[index], 889), 48, rgba(COLORS["glass"], 252), COLORS["gold_light"], 2, "06_导航")
            screen.add_circle(f"全局BottomBar/{label}/选中内徽记", (centers[index], 889), 41, rgba(COLORS["teal"], 238), COLORS["gold"], 2, "06_导航")
            screen.add_circle(f"全局BottomBar/{label}/选中辉光", (centers[index], 889), 34, rgba(COLORS["teal_bright"], 42), rgba(COLORS["gold_light"], 110), 1, "06_导航")
        screen.add_icon(
            f"全局BottomBar/{label}/图标",
            tab_id,
            (centers[index], 879 if active else 881),
            44 if active else 32,
            COLORS["cream"] if active else COLORS["gold"],
            COLORS["gold_light"],
            "06_导航",
        )
        screen.add_text(
            f"全局BottomBar/{label}/文字",
            label,
            centers[index] - 52,
            910,
            18,
            COLORS["gold_light"] if active else COLORS["gold"],
            width=104,
            align="center",
            bold=True,
            stroke_width=1 if active else 0,
            stroke_fill=COLORS["gold_dark"],
            category="06_导航",
        )


def add_ornament(screen: Screen, y: int):
    screen.add_line("装饰/左侧星线", [(64, y), (206, y)], rgba(COLORS["gold"], 170), 1, "02_氛围")
    screen.add_line("装饰/右侧星线", [(334, y), (476, y)], rgba(COLORS["gold"], 170), 1, "02_氛围")
    screen.add_icon("装饰/中心星", "star", (270, y), 22, COLORS["gold_light"], category="02_氛围")


def build_locked_home():
    screen = Screen("00", "首页锁定基准")
    reference = Image.open(ASSETS["home_reference"]).convert("RGBA")
    reference = reference.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    screen.add("锁定首页/整图基准（禁止重绘）", reference, "00_锁定基准")
    return screen


def build_home_component_library():
    screen = Screen("01", "首页组件库")
    screen.add_background(ASSETS["home_background"], darken=0.42, blur=0.8)
    screen.add_overlay("氛围/深蓝渐隐", (2, 18, 31, 72))
    add_sound_button(screen)
    screen.add_text("组件库/标题", "首页组件库", 28, 34, 34, COLORS["gold_light"], width=340, bold=True, serif=True, stroke_width=1, stroke_fill=COLORS["gold_dark"])
    screen.add_text("组件库/说明", "00 锁定首页的可实施组件 · 内页统一继承", 30, 86, 13, COLORS["cream"], width=450, bold=True)
    add_ornament(screen, 122)
    screen.add_panel("首页组件/关卡标题牌", (48, 148, 492, 238), COLORS["paper_light"], COLORS["gold"], 24)
    screen.add_text("首页组件/关卡标题", "风铃草原", 70, 162, 27, COLORS["ink"], width=400, align="center", bold=True, serif=True)
    screen.add_text("首页组件/关卡说明", "新手远征 · 坚持90秒", 70, 203, 14, COLORS["teal"], width=400, align="center", bold=True)
    screen.add_panel("首页组件/远征简报", (48, 266, 492, 406), COLORS["paper_light"], COLORS["gold"], 22)
    screen.add_text("首页组件/推荐战力", "推荐战力 1000", 70, 286, 16, COLORS["ink"], width=180, align="center", bold=True)
    screen.add_text("首页组件/当前战力", "当前战力 1000", 290, 286, 16, COLORS["teal"], width=180, align="center", bold=True)
    screen.add_line("首页组件/远征简报分隔线", [(78, 330), (462, 330)], rgba(COLORS["gold_dark"], 110), 1)
    screen.add_text("首页组件/首通标题", "首通奖励", 70, 350, 15, COLORS["ink"], width=180, align="center", bold=True)
    screen.add_text("首页组件/首通奖励", "萤翼航标 ×1", 290, 350, 15, COLORS["teal"], width=180, align="center", bold=True)
    screen.add_panel("首页组件/深青玻璃信息卡", (48, 432, 492, 540), COLORS["glass_soft"], COLORS["gold"], 22)
    screen.add_text("首页组件/玻璃卡标题", "深青玻璃面板", 70, 450, 20, COLORS["gold_light"], width=400, align="center", bold=True, serif=True)
    screen.add_text("首页组件/玻璃卡说明", "用于角色舞台、构筑和弹窗；正文保持 14px 以上", 70, 488, 14, COLORS["cream"], width=400, align="center", bold=True)
    add_primary_action(screen, "首页组件/主行动按钮", "踏入星门", (94, 568, 446, 630))
    screen.add_panel("首页组件/次行动按钮", (94, 650, 264, 700), COLORS["glass_soft"], COLORS["gold"], 20)
    screen.add_text("首页组件/次行动按钮文字", "调整角色", 94, 662, 16, COLORS["cream"], width=170, align="center", bold=True)
    screen.add_panel("首页组件/选中状态", (282, 650, 446, 700), COLORS["teal"], COLORS["gold"], 20)
    screen.add_text("首页组件/选中状态文字", "当前选中", 282, 662, 16, COLORS["cream"], width=164, align="center", bold=True)
    screen.add_text("组件库/继承说明", "内页复用：声音胶囊、纸张/玻璃面板、主行动按钮、选中态与 BottomBar", 40, 738, 12, COLORS["gold_light"], width=460, align="center", bold=True)
    add_bottom_dock(screen, "expedition")
    return screen


def add_character_navigation(screen: Screen, selected_section: str, power_text="当前战力 1000"):
    screen.add_panel("角色选择器/底座", (30, 154, 246, 196), COLORS["glass"], COLORS["gold"], 20, 2, "03_组件", True)
    screen.add_image("角色选择器/头像", ASSETS["warden_idle"], (38, 158, 76, 192), "04_内容")
    screen.add_text("角色选择器/名称", "星潮守望者", 80, 164, 15, COLORS["cream"], width=124, bold=True)
    screen.add_text("角色选择器/更换", "更换", 200, 165, 12, COLORS["gold_light"], width=34, align="right", bold=True)
    screen.add_panel("角色选择器/战力胶囊/底座", (354, 154, 510, 196), COLORS["paper_light"], COLORS["gold"], 20, 2, "03_组件", True)
    screen.add_text("角色选择器/战力胶囊/文字", power_text, 354, 164, 15, COLORS["teal"], width=156, align="center", bold=True)
    for index, label in enumerate(["状态", "装备", "技能"]):
        left = 32 + index * 164
        active = label == selected_section
        screen.add_panel(
            f"角色页签/{label}",
            (left, 206, left + 148, 254),
            COLORS["teal"] if active else COLORS["paper_light"],
            COLORS["gold"],
            20,
            2,
            "03_组件",
            True,
        )
        screen.add_text(
            f"角色页签/{label}/文字",
            label,
            left,
            217,
            17,
            COLORS["cream"] if active else COLORS["ink"],
            width=148,
            align="center",
            bold=True,
        )


def build_character_status():
    screen = inner_screen("02", "角色状态", "声音胶囊", "角色页签", "BottomBar")
    screen.add_background(ASSETS["home_background"], darken=0.18, blur=0.4)
    add_small_header(screen, "星潮守望者", "角色中心 · 查看成长与战力")
    add_character_navigation(screen, "状态")
    screen.add_panel("状态/主玻璃容器", (20, 266, 520, 826), COLORS["glass"], COLORS["gold"], 28)
    screen.add_circle("状态/角色星环", (174, 398), 110, rgba(COLORS["teal"], 62), rgba(COLORS["gold_light"], 170), 2)
    screen.add_circle("状态/角色内环", (174, 398), 88, (0, 0, 0, 0), rgba(COLORS["cyan"], 125), 1)
    screen.add_image("状态/角色立绘", ASSETS["warden_idle"], (82, 282, 266, 510), "04_内容")
    screen.add_text("状态/英雄名", "星潮守望者", 286, 300, 26, COLORS["gold_light"], width=196, bold=True, serif=True)
    screen.add_text("状态/称号", "星象术士 · 星潮结界", 288, 342, 16, COLORS["cyan"], width=190, bold=True)
    screen.add_text("状态/等级", "英雄等级  Lv.1", 288, 382, 18, COLORS["cream"], width=190, bold=True)
    screen.add_panel("状态/战力徽记", (286, 424, 484, 486), COLORS["glass_soft"], COLORS["gold"], 26)
    screen.add_text("状态/战力数值", "战力  1000", 286, 437, 25, COLORS["gold_light"], width=198, align="center", bold=True)
    screen.add_panel("状态/成长纸张", (40, 528, 500, 804), COLORS["paper_light"], COLORS["gold"], 24)
    screen.add_text("状态/成长标题", "英雄状态", 60, 548, 22, COLORS["ink"], bold=True, serif=True)
    stats = [
        ("最大生命", "100", 60, 596),
        ("移动速度", "230", 278, 596),
        ("技能伤害", "+0.0%", 60, 650),
        ("可用技能点", "0", 278, 650),
    ]
    for label, value, x, y in stats:
        screen.add_text(f"状态/属性/{label}", label, x, y, 15, COLORS["ink_muted"], width=116, bold=True)
        screen.add_text(f"状态/属性/{label}/数值", value, x + 116, y - 2, 19, COLORS["teal"], width=78, align="right", bold=True)
    screen.add_line("状态/成长分隔线", [(60, 706), (480, 706)], rgba(COLORS["gold_dark"], 100), 1)
    screen.add_text("状态/经验标题", "英雄经验", 60, 724, 15, COLORS["ink"], bold=True)
    screen.add_text("状态/经验值", "0 / 100", 380, 724, 15, COLORS["teal"], width=100, align="right", bold=True)
    screen.add_panel("状态/经验槽底", (60, 758, 480, 770), rgba(COLORS["night"], 90), None, 6, 0, shadow=False)
    screen.add_panel("状态/经验槽", (60, 758, 168, 770), COLORS["orange"], None, 6, 0, shadow=False)
    add_bottom_dock(screen, "character")
    return screen


def build_character_equipment():
    screen = inner_screen("03", "角色装备", "声音胶囊", "角色页签", "BottomBar")
    screen.add_background(ASSETS["home_background"], darken=0.18, blur=0.4)
    add_small_header(screen, "星潮守望者", "角色中心 · 配置装备提升战力")
    add_character_navigation(screen, "装备")
    screen.add_panel("装备/主玻璃容器", (20, 266, 520, 826), COLORS["glass"], COLORS["gold"], 28)
    screen.add_circle("装备/角色星环", (270, 390), 104, rgba(COLORS["teal"], 65), rgba(COLORS["gold_light"], 170), 2)
    screen.add_image("装备/角色立绘", ASSETS["warden_idle"], (178, 278, 362, 500), "04_内容")
    slots = [
        ("武器", ASSETS["weapon"], (42, 292, 130, 394), "启程星杖"),
        ("护甲", ASSETS["armor"], (410, 292, 498, 394), "风铃护衣"),
        ("饰品", ASSETS["charm"], (410, 412, 498, 514), "风铃叶坠"),
    ]
    for label, asset, box, item_name in slots:
        screen.add_panel(f"装备槽/{label}/底板", box, COLORS["paper_light"], COLORS["gold"], 18, 2)
        screen.add_text(f"装备槽/{label}/标签", label, box[0], box[1] + 7, 12, COLORS["teal"], width=box[2] - box[0], align="center", bold=True)
        screen.add_image(f"装备槽/{label}/图标", asset, (box[0] + 16, box[1] + 24, box[2] - 16, box[3] - 25), "04_内容")
        screen.add_text(f"装备槽/{label}/名称", item_name, box[0], box[3] - 24, 12, COLORS["ink"], width=box[2] - box[0], align="center", bold=True)
    screen.add_panel("装备/背包纸张", (36, 536, 504, 806), COLORS["paper_light"], COLORS["gold"], 24)
    screen.add_text("装备/背包标题", "装备背包", 56, 554, 21, COLORS["ink"], bold=True, serif=True)
    screen.add_text("装备/背包数量", "3 / 30", 408, 558, 14, COLORS["ink_muted"], width=72, align="right", bold=True)
    for index, label in enumerate(["全部", "武器", "护甲", "饰品"]):
        left = 52 + index * 112
        active = index == 0
        screen.add_panel(
            f"装备/筛选/{label}",
            (left, 594, left + 100, 634),
            COLORS["teal"] if active else COLORS["cream_soft"],
            COLORS["gold"],
            17,
            1,
            "03_组件",
            False,
        )
        screen.add_text(f"装备/筛选/{label}/文字", label, left, 603, 13, COLORS["cream"] if active else COLORS["ink"], width=100, align="center", bold=True)
    inventory = [
        ("启程星杖", ASSETS["weapon"]),
        ("风铃护衣", ASSETS["armor"]),
        ("风铃叶坠", ASSETS["charm"]),
    ]
    for index, (label, asset) in enumerate(inventory):
        left = 52 + index * 148
        screen.add_panel(f"装备/背包卡/{label}", (left, 650, left + 132, 786), COLORS["cream_soft"], COLORS["gold"], 18, 2)
        screen.add_text(f"装备/背包卡/{label}/品质", "普通  +0", left + 8, 660, 13, COLORS["teal"], width=116, bold=True)
        screen.add_image(f"装备/背包卡/{label}/图标", asset, (left + 28, 680, left + 104, 744), "04_内容")
        screen.add_text(f"装备/背包卡/{label}/名称", label, left + 6, 752, 15, COLORS["ink"], width=120, align="center", bold=True)
    add_bottom_dock(screen, "character")
    return screen


def build_character_skills():
    screen = inner_screen("04", "角色技能", "声音胶囊", "角色页签", "BottomBar")
    screen.add_background(ASSETS["home_background"], darken=0.2, blur=0.5)
    add_small_header(screen, "星潮守望者", "角色中心 · 培养专属技能")
    add_character_navigation(screen, "技能", "当前战力 1000")
    screen.add_panel("技能/主玻璃容器", (20, 266, 520, 826), COLORS["glass"], COLORS["gold"], 28)
    screen.add_text("技能/标题", "星潮结界", 44, 286, 26, COLORS["gold_light"], bold=True, serif=True)
    screen.add_text("技能/点数", "可用技能点  3", 330, 292, 16, COLORS["cyan"], width=150, align="right", bold=True)
    screen.add_text("技能/说明", "永久训练最高 3 级 · 不提前解锁局内终极技能", 44, 328, 15, COLORS["cream"], width=432, bold=True)
    nodes = [
        ("星辉强化", "伤害与治疗 +4%", ASSETS["star_lance"], 386, 1),
        ("潮汐扩张", "范围 +10%", ASSETS["frost_tide"], 520, 2),
        ("星轮共鸣", "命中间隔 -4%", ASSETS["sun_orbit"], 654, 0),
    ]
    screen.add_line("技能/连接线", [(98, 418), (98, 686)], rgba(COLORS["gold"], 180), 4)
    for title, effect, asset, y, level in nodes:
        screen.add_circle(f"技能节点/{title}/外环", (98, y + 26), 43, rgba(COLORS["teal"], 220), COLORS["gold"] if level else COLORS["locked"], 3)
        screen.add_image(f"技能节点/{title}/图标", asset, (68, y - 4, 128, y + 56), "04_内容", opacity=1.0 if level else 0.48)
        screen.add_panel(f"技能节点/{title}/详情", (156, y - 14, 486, y + 76), COLORS["paper_light"], COLORS["gold"], 18, 2)
        screen.add_text(f"技能节点/{title}/名称", title, 176, y, 19, COLORS["ink"], bold=True)
        screen.add_text(f"技能节点/{title}/效果", effect, 176, y + 34, 16, COLORS["ink_muted"], bold=True)
        screen.add_text(f"技能节点/{title}/等级", f"训练 {level}/3", 348, y + 1, 14, COLORS["teal"], width=116, align="right", bold=True)
        button_fill = COLORS["orange"] if level < 3 else COLORS["locked"]
        button_text = f"培养 · {level + 1}点" if level < 3 else "已满级"
        screen.add_panel(f"技能节点/{title}/按钮", (344, y + 38, 466, y + 68), button_fill, COLORS["gold_light"], 13, 1, "03_组件", False)
        screen.add_text(f"技能节点/{title}/按钮文字", button_text, 344, y + 43, 13, COLORS["cream"], width=122, align="center", bold=True)
    screen.add_text("技能/成长提示", "训练结果将计入英雄战力", 46, 780, 14, COLORS["gold_light"], width=238, bold=True)
    screen.add_panel("技能/重置按钮", (318, 770, 486, 808), COLORS["glass_soft"], COLORS["gold"], 17, 1)
    screen.add_text("技能/重置文字", "免费重置技能点", 318, 779, 14, COLORS["cream"], width=168, align="center", bold=True)
    add_bottom_dock(screen, "character")
    return screen


def build_compendium():
    screen = inner_screen("05", "星潮图鉴", "声音胶囊", "分类胶囊", "BottomBar")
    screen.add_background(ASSETS["home_background"], darken=0.18, blur=0.4)
    add_small_header(screen, "星潮图鉴", "远征收藏册 · 随旅程逐步发现世界")
    categories = [("英雄", "2/2"), ("怪物", "2/4"), ("道具", "2/5"), ("技能", "2/6"), ("遗物", "1/6")]
    for index, (label, progress) in enumerate(categories):
        left = 24 + index * 99
        active = label == "怪物"
        screen.add_panel(
            f"图鉴/分类/{label}",
            (left, 158, left + 91, 206),
            COLORS["orange"] if active else COLORS["cream_soft"],
            COLORS["gold"],
            18,
            2 if active else 1,
            "03_组件",
            False,
        )
        screen.add_text(f"图鉴/分类/{label}/文字", f"{label} {progress}", left, 171, 13, COLORS["cream"] if active else COLORS["ink"], width=91, align="center", bold=True)
    screen.add_panel("图鉴/主玻璃容器", (20, 218, 520, 826), COLORS["glass"], COLORS["gold"], 28)
    screen.add_text("图鉴/进度", "怪物图鉴  ·  已发现 2 / 4", 40, 236, 16, COLORS["gold_light"], width=260, bold=True)
    screen.add_text("图鉴/提示", "点击卡片查看记录", 338, 238, 14, COLORS["cyan"], width=142, align="right", bold=True)
    cards = [
        ("张姐蛆", "翠绒毛虫 · 一级魔物", ASSETS["grub"], True),
        ("星蚀史莱姆", "基础魔物", ASSETS["slime"], True),
        ("暮翼蝠", "第二关发现", ASSETS["bat"], False),
        ("陨岩巨怪", "第三关发现", ASSETS["brute"], False),
    ]
    for index, (name, subtitle, asset, discovered) in enumerate(cards):
        col = index % 2
        row = index // 2
        left = 34 + col * 244
        top = 274 + row * 258
        fill = COLORS["cream_soft"] if discovered else "#D7DDCF"
        outline = COLORS["gold"] if discovered else COLORS["locked"]
        screen.add_panel(f"图鉴卡/{name}/底板", (left, top, left + 228, top + 242), fill, outline, 20, 2)
        if discovered:
            screen.add_image(f"图鉴卡/{name}/图像", asset, (left + 34, top + 16, left + 194, top + 142), "04_内容")
            screen.add_text(f"图鉴卡/{name}/名称", name, left + 16, top + 154, 22, COLORS["ink"], width=196, align="center", bold=True)
            screen.add_text(f"图鉴卡/{name}/说明", subtitle, left + 16, top + 194, 15, COLORS["teal"], width=196, align="center", bold=True)
        else:
            screen.add_image(f"图鉴卡/{name}/剪影", asset, (left + 44, top + 22, left + 184, top + 142), "04_内容", opacity=0.18)
            screen.add_text(f"图鉴卡/{name}/锁", "?", left + 168, top + 20, 23, COLORS["cream"], width=42, align="center", bold=True, editable=False)
            screen.add_text(f"图鉴卡/{name}/未发现", "尚未发现", left + 16, top + 154, 22, COLORS["locked"], width=196, align="center", bold=True)
            screen.add_text(f"图鉴卡/{name}/线索", f"线索：{subtitle}", left + 16, top + 196, 15, COLORS["ink_muted"], width=196, align="center", bold=True)
    add_bottom_dock(screen, "compendium")
    return screen


def gameplay_world():
    source = Image.open(ASSETS["gameplay_meadow"]).convert("RGBA")
    crop = source.crop((0, 145, source.width, source.height))
    return cover_asset_from_image(crop, WIDTH, HEIGHT)


def cover_asset_from_image(source: Image.Image, width: int, height: int):
    scale = max(width / source.width, height / source.height)
    target = source.resize((round(source.width * scale), round(source.height * scale)), Image.Resampling.LANCZOS)
    left = max(0, (target.width - width) // 2)
    top = max(0, (target.height - height) // 2)
    return target.crop((left, top, left + width, top + height))


def add_game_hud(screen: Screen):
    screen.add_panel("HUD/顶部玻璃条", (14, 18, 526, 100), COLORS["glass"], COLORS["gold"], 22)
    screen.add_text("HUD/等级", "LV.4", 32, 28, 19, COLORS["gold_light"], bold=True)
    screen.add_text("HUD/计时与击败", "01:12   ·   击败 42", 220, 28, 16, COLORS["cream"], width=232, align="right", bold=True)
    screen.add_panel("HUD/暂停按钮", (462, 28, 510, 80), COLORS["teal"], COLORS["gold"], 21, 2, shadow=False)
    screen.add_icon("HUD/暂停图标", "pause", (486, 54), 24, COLORS["cream"])
    screen.add_panel("HUD/生命槽底", (32, 65, 448, 82), rgba(COLORS["night"], 230), COLORS["gold_dark"], 8, 1, shadow=False)
    screen.add_panel("HUD/生命槽", (36, 69, 364, 78), COLORS["coral"], None, 4, 0, shadow=False)
    screen.add_text("HUD/生命文字", "生命 78 / 100", 298, 52, 12, COLORS["cream"], width=140, align="right", bold=True)
    screen.add_panel("HUD/经验槽底", (32, 88, 448, 94), rgba(COLORS["night"], 230), None, 3, 0, shadow=False)
    screen.add_panel("HUD/经验槽", (32, 88, 260, 94), COLORS["cyan"], None, 3, 0, shadow=False)
    screen.add_panel("HUD/阶段提示", (112, 116, 428, 160), COLORS["paper_light"], COLORS["gold"], 18)
    screen.add_text("HUD/阶段文字", "风铃草原 · 星潮涌动", 112, 126, 17, COLORS["ink"], width=316, align="center", bold=True, serif=True)
    screen.add_panel("HUD/技能托盘", (232, 838, 516, 926), COLORS["paper_light"], COLORS["gold"], 22)
    screen.add_text("HUD/自动技能标签", "自动技能", 244, 844, 10, COLORS["teal"], width=62, align="center", bold=True)
    skill_assets = [ASSETS["star_lance"], ASSETS["frost_tide"], ASSETS["sun_orbit"]]
    for index, asset in enumerate(skill_assets):
        center_x = 326 + index * 82
        screen.add_circle(f"HUD/技能{index + 1}/状态底座", (center_x, 880), 31, COLORS["glass_soft"], COLORS["gold"] if index == 0 else COLORS["locked"], 2)
        screen.add_image(f"HUD/技能{index + 1}/图标", asset, (center_x - 25, 855, center_x + 25, 905), "04_内容", opacity=1.0 if index == 0 else 0.38)
        screen.add_text(f"HUD/技能{index + 1}/等级", "Lv.2" if index == 0 else "Lv.1", center_x - 24, 906, 9, COLORS["teal"], width=48, align="center", bold=True)
    screen.add_circle("HUD/摇杆/外环", (90, 866), 62, rgba(COLORS["glass"], 155), rgba(COLORS["gold_light"], 160), 2)
    screen.add_circle("HUD/摇杆/内环", (90, 866), 33, rgba(COLORS["teal"], 220), COLORS["cyan"], 2)
    screen.add_icon("HUD/摇杆/星标", "star", (90, 866), 34, COLORS["cream"])
    screen.add_text("HUD/教学提示", "拖动左下摇杆移动 · 技能会自动释放", 116, 934, 12, COLORS["cream"], width=390, align="center", bold=True, stroke_width=1, stroke_fill=COLORS["night"])


def build_gameplay():
    screen = inner_screen("06", "战斗HUD", "深青玻璃面板", "金色双描边")
    screen.add("战场/风铃草原", gameplay_world(), "01_背景")
    screen.add_overlay("战场/可读性薄雾", (0, 18, 20, 20), "02_氛围")
    add_game_hud(screen)
    return screen


def build_pause():
    screen = inner_screen("07", "暂停弹窗", "象牙纸张面板", "主行动按钮", "深青玻璃面板")
    screen.add("战场/暂停背景", gameplay_world().filter(ImageFilter.GaussianBlur(1.2)), "01_背景")
    screen.add_overlay("遮罩/暗化", (1, 11, 18, 178), "02_氛围")
    screen.add_panel("弹窗/主纸张", (40, 98, 500, 856), COLORS["paper_light"], COLORS["gold"], 30)
    screen.add_text("弹窗/眉题", "星潮暂歇", 88, 124, 14, COLORS["teal"], width=364, align="center", bold=True)
    screen.add_text("弹窗/标题", "冒险暂停", 88, 154, 30, COLORS["ink"], width=364, align="center", bold=True, serif=True)
    screen.add_text("弹窗/说明", "星潮已经停住，准备好继续出发", 88, 202, 13, COLORS["ink_muted"], width=364, align="center")
    add_primary_action(screen, "弹窗/继续按钮", "继续冒险", (72, 244, 468, 310))
    screen.add_icon("弹窗/继续图标", "play", (178, 278), 24, COLORS["cream"])
    screen.add_panel("弹窗/构筑玻璃卡", (72, 338, 468, 610), COLORS["glass"], COLORS["gold"], 22)
    screen.add_text("弹窗/构筑标题", "本局构筑", 96, 360, 19, COLORS["gold_light"], bold=True, serif=True)
    screen.add_text("弹窗/构筑类别", "技能与遗物", 330, 365, 11, COLORS["cyan"], width=114, align="right", bold=True)
    build_items = [
        ("星矛", ASSETS["star_lance"], "II"),
        ("霜潮", ASSETS["frost_tide"], "I"),
        ("日冕", ASSETS["sun_orbit"], "I"),
    ]
    for index, (label, asset, level) in enumerate(build_items):
        left = 96 + index * 112
        screen.add_panel(f"弹窗/构筑/{label}/底板", (left, 410, left + 88, 512), COLORS["paper_light"], COLORS["teal_bright"], 16, 1, shadow=False)
        screen.add_image(f"弹窗/构筑/{label}/图标", asset, (left + 16, 422, left + 72, 478), "04_内容")
        screen.add_text(f"弹窗/构筑/{label}/等级", f"{label} {level}", left, 486, 10, COLORS["ink"], width=88, align="center", bold=True)
    screen.add_text("弹窗/构筑说明", "剩余重抽 1 次 · 继续战斗，收集星辉完善组合", 96, 548, 11, COLORS["cream"], width=348, align="center")
    screen.add_text("弹窗/声音提示", "需要调整听感？", 80, 644, 12, COLORS["ink_muted"], width=180)
    screen.add_panel("弹窗/声音按钮", (350, 632, 468, 678), COLORS["glass_soft"], COLORS["gold"], 20, 1)
    screen.add_icon("弹窗/声音图标", "music", (378, 655), 22, COLORS["cream"])
    screen.add_text("弹窗/声音文字", "声音", 390, 643, 14, COLORS["cream"], width=68, align="center", bold=True)
    screen.add_panel("弹窗/大厅按钮", (72, 714, 468, 772), COLORS["cream_soft"], COLORS["teal_bright"], 20)
    screen.add_text("弹窗/大厅文字", "返回关卡大厅", 72, 730, 16, COLORS["ink"], width=396, align="center", bold=True)
    screen.add_text("弹窗/大厅说明", "返回大厅将结束本次远征", 72, 790, 11, COLORS["ink_muted"], width=396, align="center")
    return screen


def build_upgrade():
    screen = inner_screen("08", "升级三选一", "深青玻璃面板", "选中状态")
    screen.add("战场/升级背景", gameplay_world().filter(ImageFilter.GaussianBlur(1.4)), "01_背景")
    screen.add_overlay("遮罩/深蓝", (1, 10, 25, 212), "02_氛围")
    screen.add_text("升级/眉题", "星辉汇聚", 40, 48, 14, COLORS["cyan"], width=460, align="center", bold=True)
    screen.add_text("升级/标题", "等级 2 · 选择强化", 40, 78, 30, COLORS["gold_light"], width=460, align="center", bold=True, serif=True, stroke_width=1, stroke_fill=COLORS["gold_dark"])
    screen.add_text("升级/说明", "选择 1 项强化，构筑只属于你的流派", 40, 124, 13, COLORS["cream"], width=460, align="center")
    choices = [
        ("终极 · 时凝星海 III", "超大范围冻结，造成重击并大幅减速", ASSETS["frost_tide"], COLORS["gold"]),
        ("终极 · 日冕圣环 III", "四颗巨大日轮高速环绕，持续绞杀", ASSETS["sun_orbit"], COLORS["orange"]),
        ("流光步", "移动速度永久 +12%", ASSETS["magnet"], COLORS["cyan"]),
    ]
    for index, (title, description, asset, accent) in enumerate(choices):
        top = 180 + index * 206
        screen.add_panel(f"升级卡/{title}/底板", (34, top, 506, top + 174), COLORS["glass"], accent, 24, 2)
        screen.add_circle(f"升级卡/{title}/图标底", (98, top + 70), 45, rgba(COLORS["teal"], 210), accent, 2)
        screen.add_image(f"升级卡/{title}/图标", asset, (60, top + 32, 136, top + 108), "04_内容")
        screen.add_text(f"升级卡/{title}/名称", title, 166, top + 30, 17, COLORS["cream"], width=312, bold=True)
        screen.add_text(f"升级卡/{title}/说明", description, 166, top + 68, 13, COLORS["gold_light"] if index < 2 else COLORS["cream"], width=306, bold=index < 2)
        tag = "终极进化" if index < 2 else "永久增益"
        screen.add_panel(f"升级卡/{title}/标签", (166, top + 118, 270, top + 148), rgba(accent, 230), COLORS["gold_light"], 13, 1, shadow=False)
        screen.add_text(f"升级卡/{title}/标签文字", tag, 166, top + 124, 11, COLORS["night"], width=104, align="center", bold=True)
        screen.add_text(f"升级卡/{title}/选择提示", "点击选择  >", 354, top + 124, 12, COLORS["cyan"], width=118, align="right", bold=True)
    screen.add_panel("升级/重绘按钮", (178, 820, 362, 870), COLORS["glass_soft"], COLORS["gold"], 20)
    screen.add_text("升级/重绘文字", "重绘选择 · 剩余1次", 178, 833, 13, COLORS["cream"], width=184, align="center", bold=True)
    screen.add_text("升级/底部提示", "暂停期间战斗与敌方弹体完全冻结", 40, 904, 11, COLORS["cream"], width=460, align="center")
    return screen


def build_result():
    screen = inner_screen("09", "胜利结算", "象牙纸张面板", "主行动按钮", "深青玻璃面板")
    screen.add_background(ASSETS["home_background"], darken=0.28, blur=0.8)
    screen.add_overlay("氛围/金色辉光", (40, 65, 5, 34), "02_氛围")
    screen.add_panel("结算/主纸张", (34, 66, 506, 820), COLORS["paper_light"], COLORS["gold"], 30)
    screen.add_text("结算/眉题", "星门凯旋", 80, 92, 14, COLORS["teal"], width=380, align="center", bold=True)
    screen.add_text("结算/标题", "远征完成", 80, 124, 32, COLORS["ink"], width=380, align="center", bold=True, serif=True)
    screen.add_circle("结算/英雄舞台外环", (270, 272), 100, rgba(COLORS["teal"], 55), rgba(COLORS["gold"], 170), 2)
    screen.add_image("结算/胜利英雄", ASSETS["ember_victory"], (170, 164, 370, 382), "04_内容")
    stats = [("01:30", "远征用时"), ("42", "击败魔物"), ("Lv.4", "局内等级")]
    for index, (value, label) in enumerate(stats):
        left = 54 + index * 146
        screen.add_panel(f"结算/统计/{label}", (left, 392, left + 132, 458), COLORS["cream_soft"], COLORS["gold"], 16, 1)
        screen.add_text(f"结算/统计/{label}/数值", value, left, 400, 19, COLORS["ink"], width=132, align="center", bold=True)
        screen.add_text(f"结算/统计/{label}/名称", label, left, 430, 10, COLORS["ink_muted"], width=132, align="center")
    screen.add_text("结算/祝贺", "星潮安定，守望成功！", 70, 486, 14, COLORS["teal"], width=400, align="center", bold=True)
    screen.add_panel("结算/奖励卡", (54, 526, 486, 658), COLORS["glass"], COLORS["gold"], 22)
    screen.add_image("结算/奖励图标", ASSETS["xp"], (74, 552, 142, 620), "04_内容")
    screen.add_text("结算/奖励标题", "远征收获", 158, 544, 16, COLORS["gold_light"], bold=True, serif=True)
    screen.add_text("结算/奖励内容", "首通奖励 · 萤翼航标 ×1\n永久装备 · 风弦轻弓\n英雄经验 +100", 158, 574, 12, COLORS["cream"], width=292, line_spacing=8)
    screen.add_panel("结算/成长卡", (54, 676, 486, 760), COLORS["cream_soft"], COLORS["teal_bright"], 20, 2)
    screen.add_text("结算/成长标题", "英雄成长", 74, 690, 14, COLORS["ink"], bold=True)
    screen.add_text("结算/成长数值", "Lv.1  →  Lv.2   ·   技能点 +1", 206, 690, 13, COLORS["teal"], width=252, align="right", bold=True)
    screen.add_panel("结算/成长槽底", (74, 730, 462, 742), rgba(COLORS["night"], 90), None, 6, 0, shadow=False)
    screen.add_panel("结算/成长槽", (74, 730, 356, 742), COLORS["orange"], None, 6, 0, shadow=False)
    add_primary_action(screen, "结算/再战按钮", "再战一次", (62, 842, 478, 900))
    screen.add_text("结算/返回文字", "返回关卡大厅", 170, 916, 13, COLORS["gold_light"], width=200, align="center", bold=True)
    return screen


def build_audio():
    screen = inner_screen("10", "声音设置", "声音胶囊", "深青玻璃面板", "主行动按钮")
    screen.add_background(ASSETS["home_background"], darken=0.18, blur=0.5)
    screen.add_overlay("遮罩/暗化", (0, 13, 28, 90), "02_氛围")
    screen.add_panel("声音/弹窗", (54, 184, 486, 724), COLORS["glass"], COLORS["gold"], 30)
    screen.add_text("声音/眉题", "星港回响", 94, 210, 13, COLORS["cyan"], width=352, align="center", bold=True)
    screen.add_text("声音/标题", "声音设置", 94, 242, 30, COLORS["cream"], width=352, align="center", bold=True, serif=True)
    screen.add_text("声音/说明", "音乐营造氛围，音效传达战斗反馈", 94, 288, 13, COLORS["gold_light"], width=352, align="center")
    rows = [("music", "背景音乐", "72%", 342), ("star", "战斗音效", "86%", 468)]
    for icon, label, value, top in rows:
        screen.add_panel(f"声音/{label}/卡片", (80, top, 460, top + 104), COLORS["glass_soft"], COLORS["teal_bright"], 20, 2)
        screen.add_icon(f"声音/{label}/图标", icon, (122, top + 35), 24, COLORS["gold_light"])
        screen.add_text(f"声音/{label}/名称", label, 154, top + 18, 16, COLORS["cream"], bold=True)
        screen.add_text(f"声音/{label}/数值", value, 354, top + 18, 14, COLORS["cyan"], width=62, align="right", bold=True)
        screen.add_panel(f"声音/{label}/轨道", (154, top + 60, 376, top + 70), rgba(COLORS["night"], 230), None, 5, 0, shadow=False)
        amount = 0.72 if label == "背景音乐" else 0.86
        screen.add_panel(f"声音/{label}/进度", (154, top + 60, 154 + round(222 * amount), top + 70), COLORS["cyan"], None, 5, 0, shadow=False)
        knob_x = 154 + round(222 * amount)
        screen.add_circle(f"声音/{label}/滑块", (knob_x, top + 65), 8, COLORS["cream"], COLORS["gold"], 1)
        screen.add_panel(f"声音/{label}/开关", (390, top + 52, 440, top + 82), COLORS["teal"], COLORS["gold"], 15, 1, shadow=False)
        screen.add_text(f"声音/{label}/开关文字", "开", 390, top + 57, 11, COLORS["cream"], width=50, align="center", bold=True)
    add_primary_action(screen, "声音/完成按钮", "完成", (132, 620, 408, 676))
    screen.add_text("声音/底部提示", "设置会自动保存在本机", 86, 692, 11, COLORS["gold_light"], width=368, align="center")
    return screen


def build_master_preview(screens: list[Screen], revision: str):
    rows = math.ceil(len(screens) / GRID_COLUMNS)
    canvas_width = GUTTER + GRID_COLUMNS * (WIDTH + GUTTER)
    canvas_height = GUTTER + rows * (HEIGHT + GUTTER)
    canvas = Image.new("RGB", (canvas_width, canvas_height), COLORS["night"])
    draw = ImageDraw.Draw(canvas)
    placements = []
    for index, screen in enumerate(screens):
        column = index % GRID_COLUMNS
        row = index // GRID_COLUMNS
        left = GUTTER + column * (WIDTH + GUTTER)
        top = GUTTER + row * (HEIGHT + GUTTER)
        shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        shadow_draw = ImageDraw.Draw(shadow)
        shadow_draw.rounded_rectangle((left + 10, top + 14, left + WIDTH + 10, top + HEIGHT + 14), radius=18, fill=(0, 0, 0, 95))
        shadow = shadow.filter(ImageFilter.GaussianBlur(12))
        canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB")
        canvas.paste(screen.composite.convert("RGB"), (left, top))
        draw = ImageDraw.Draw(canvas)
        draw.text((left, top - 34), f"{screen.screen_id}  {screen.title}", font=font(18, bold=True), fill=COLORS["cream"])
        placements.append({"screenId": screen.screen_id, "left": left, "top": top})
    preview = OUTPUT_ROOT / f"star_tide_ui_master_{revision}_preview.png"
    canvas.save(preview, quality=95)
    thumbnail = canvas.copy()
    thumbnail.thumbnail((1600, 2400), Image.Resampling.LANCZOS)
    thumbnail.save(OUTPUT_ROOT / f"star_tide_ui_master_{revision}_overview.png", quality=92)
    return canvas, placements, preview


def write_spec(revision: str, screens: list[Screen]):
    screen_list = "\n".join(f"- `{screen.screen_id}` {screen.title}" for screen in screens)
    spec = f"""# 《星潮守望者》UI 设计稿 {revision.upper()}

## 交付结构

- 主 PSD：`star_tide_ui_master_{revision}.psd`
- 清单：`star_tide_ui_master_{revision}_manifest.json`
- 总览：`star_tide_ui_master_{revision}_overview.png`
- 原尺寸总览：`star_tide_ui_master_{revision}_preview.png`
- 独立页面：`screens/`
- PSD 中每个页面为顶层画板组，内部按背景、氛围、组件、内容、文字、导航分组。
- 文字同时带有 Photoshop 文本描述和预渲染图层；图片与卡片均为独立层。
- `00` 仅包含 `assets/art/ui/home/star_tide_home_reference.png` 的逻辑尺寸整图，不进行程序化重绘。
- `01` 是首页组件库，`02`～`10` 通过 manifest 的 `inherits` 字段声明继承组件。

## 页面

{screen_list}

## 视觉原则

1. `00 首页锁定基准` 是唯一视觉标准；任何实现差异都应调整组件和内页，不得反向重绘首页。
2. 同一屏最多保留一个橙色主按钮；青色只承担选中、进度和技能状态。
3. 全局 BottomBar 在角色、图鉴中使用 `01 首页组件库` 的同一母版：底座固定 `x=36 y=864 w=468 h=76`，分栏中心固定为 `114 / 270 / 426`。
4. BottomBar 只允许移动直径 `96px` 的选中徽记，底座、图标、文字、分栏和触控热区不得随页面改变。
5. 字体层级为品牌宋体、功能标题黑体、正文黑体；所有动态数据单独成层，辅助正文不小于 14px。
6. 540×960 为逻辑基准，左右安全边距 24px，顶部 20px；三个导航热区等宽且不小于 88×88px。
7. 主 CTA 底边不超过 840px，与 BottomBar 可见底座至少间隔 24px。
8. 游戏 HUD 保持常驻不透明区域不超过安全区约 15%，升级和暂停时才使用完整遮罩。
9. 右下技能托盘是自动技能状态展示，不提供点击交互；左下摇杆是战斗主触控区。

## 实施映射

- `UiFactory`：颜色、圆角、阴影与按钮状态。
- `BottomBar`：全局唯一浮动 Dock，三个主页面只改变选中徽记位置。
- `CharacterPage`：紧凑角色选择器、唯一一级页签、玻璃角色舞台与象牙纸张子卡。
- `CompendiumOverlay`：纸张图鉴、分类胶囊与发现状态卡。
- `GameHud`：紧凑玻璃顶栏、细经验条、右下技能托盘。
- `PauseOverlay`、`UpgradeOverlay`、`ResultOverlay`：统一纸张/玻璃层级及单主行动原则。
"""
    (OUTPUT_ROOT / f"DESIGN_SPEC_{revision}.md").write_text(spec, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--revision", default="locked_home_final")
    args = parser.parse_args()
    ensure_dirs()
    screens = [
        build_locked_home(),
        build_home_component_library(),
        build_character_status(),
        build_character_equipment(),
        build_character_skills(),
        build_compendium(),
        build_gameplay(),
        build_pause(),
        build_upgrade(),
        build_result(),
        build_audio(),
    ]
    for screen in screens:
        screen.save()
    composite, placements, preview = build_master_preview(screens, args.revision)
    composite_path = BUILD_ROOT / "master_composite.png"
    composite.convert("RGBA").save(composite_path)
    manifest = {
        "revision": args.revision,
        "width": composite.width,
        "height": composite.height,
        "compositePath": str(composite_path.relative_to(ROOT)),
        "lockedHome": {
            "screenId": "00",
            "source": str(ASSETS["home_reference"].relative_to(ROOT)),
            "policy": "flattened_reference_only_no_programmatic_redraw",
            "sourceSize": list(Image.open(ASSETS["home_reference"]).size),
            "logicalSize": [WIDTH, HEIGHT],
        },
        "componentLibraryScreenId": HOME_COMPONENT_LIBRARY_ID,
        "placements": placements,
        "screens": [screen.manifest() for screen in screens],
    }
    manifest_path = BUILD_ROOT / "manifest.json"
    manifest_text = json.dumps(manifest, ensure_ascii=False, indent=2)
    manifest_path.write_text(manifest_text, encoding="utf-8")
    named_manifest_path = OUTPUT_ROOT / f"star_tide_ui_master_{args.revision}_manifest.json"
    named_manifest_path.write_text(manifest_text, encoding="utf-8")
    write_spec(args.revision, screens)
    print(json.dumps({
        "manifest": str(manifest_path),
        "namedManifest": str(named_manifest_path),
        "preview": str(preview),
        "screens": len(screens),
        "layers": sum(len(screen.layers) for screen in screens),
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
