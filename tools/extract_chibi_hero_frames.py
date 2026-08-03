#!/usr/bin/env python3

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/generated/hero_chibi/source"
OUTPUT_DIR = ROOT / "assets/generated/hero_chibi"
CELL_SIZE = 512
FOOT_BASELINE = 488
POSES = ("idle", "run_contact", "run_pass", "cast", "hit", "victory")
HEROES = {
    "star_warden": SOURCE_DIR / "star_warden_atlas_alpha.png",
    "ember_ranger": SOURCE_DIR / "ember_ranger_atlas_alpha.png",
}


def extract_frames(hero_id: str, atlas_path: Path) -> None:
    atlas = Image.open(atlas_path).convert("RGBA")
    expected_size = (CELL_SIZE * 3, CELL_SIZE * 2)
    if atlas.size != expected_size:
        raise ValueError(f"{atlas_path} must be {expected_size}, got {atlas.size}")

    hero_output = OUTPUT_DIR / hero_id
    hero_output.mkdir(parents=True, exist_ok=True)
    for index, pose_id in enumerate(POSES):
        column = index % 3
        row = index // 3
        box = (
            column * CELL_SIZE,
            row * CELL_SIZE,
            (column + 1) * CELL_SIZE,
            (row + 1) * CELL_SIZE,
        )
        frame = atlas.crop(box)

        # The generator placed a few pixels from the lower row on the final
        # top-row cell boundary. They are outside the actual character pose.
        if row == 0:
            frame.paste((0, 0, 0, 0), (0, CELL_SIZE - 5, CELL_SIZE, CELL_SIZE))

        used_rect = frame.getchannel("A").getbbox()
        if used_rect is None:
            raise ValueError(f"{hero_id}/{pose_id} contains no visible pixels")
        vertical_offset = FOOT_BASELINE - used_rect[3]
        normalized = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
        normalized.alpha_composite(frame, (0, vertical_offset))
        normalized.save(hero_output / f"{pose_id}.png")


def main() -> None:
    for hero_id, atlas_path in HEROES.items():
        extract_frames(hero_id, atlas_path)


if __name__ == "__main__":
    main()
