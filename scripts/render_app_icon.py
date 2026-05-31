#!/usr/bin/env python3
"""Scoutiq dürbün + OVR yayı + yıldız — launcher ikon PNG."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "yetenek_avcisi" / "assets" / "icon"
SIZE = 1024
BG = (11, 15, 25)
GREEN = (0, 255, 135)
GREEN_DARK = (0, 204, 106)


def _star_points(cx: float, cy: float, scale: float) -> list[tuple[float, float]]:
    raw = (
        (0, -34),
        (9, -10),
        (34, -10),
        (14, 4),
        (22, 30),
        (0, 16),
        (-22, 30),
        (-14, 4),
        (-34, -10),
        (-9, -10),
    )
    return [(cx + x * scale, cy + y * scale) for x, y in raw]


def draw_binocular_icon(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float) -> None:
    def s(v: float) -> float:
        return v * scale

    sw_outer = max(2, int(s(28)))
    sw_bridge = max(2, int(s(24)))
    sw_inner = max(2, int(s(12)))
    sw_arc = max(2, int(s(14)))

    lx, ly = cx + s(-118), cy + s(-8)
    rx, ry = cx + s(118), cy + s(-8)
    lr = s(118)
    ir = s(52)

    for x, y in ((lx, ly), (rx, ry)):
        draw.ellipse((x - lr, y - lr, x + lr, y + lr), outline=GREEN, width=sw_outer)

    draw.line(
        (cx + s(-36), cy + s(-8), cx + s(36), cy + s(-8)),
        fill=GREEN,
        width=sw_bridge,
    )

    for x, y in ((lx, ly), (rx, ry)):
        draw.ellipse((x - ir, y - ir, x + ir, y + ir), outline=GREEN_DARK, width=sw_inner)

    draw.polygon(_star_points(cx, cy + s(-8), scale), fill=GREEN)

    # OVR yayı — merkez (0, -50), yarıçap 200
    arc_box = (cx + s(-200), cy + s(-250), cx + s(200), cy + s(150))
    draw.arc(arc_box, 200, 340, fill=GREEN, width=sw_arc)

    dot_r = max(3, int(s(10)))
    for dx, dy in (s(-176), s(150)), (0.0, s(62)), (s(176), s(150)):
        draw.ellipse(
            (cx + dx - dot_r, cy + dy - dot_r, cx + dx + dot_r, cy + dy + dot_r),
            fill=GREEN,
        )


def render(full_path: Path, transparent: bool = False) -> None:
    if transparent:
        img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    else:
        img = Image.new("RGB", (SIZE, SIZE), BG)
    draw = ImageDraw.Draw(img)
    if not transparent:
        draw.rectangle((0, 0, SIZE, SIZE), fill=BG)
    draw_binocular_icon(draw, SIZE / 2, SIZE / 2, 1.0)
    img.save(full_path, optimize=True)
    print(f"wrote {full_path} ({full_path.stat().st_size} bytes)")


def main() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    render(ICON_DIR / "app_icon.png", transparent=False)
    render(ICON_DIR / "app_icon_foreground.png", transparent=True)
    branding = ROOT / "yetenek_avcisi" / "assets" / "branding" / "scoutiq_icon.png"
    branding.parent.mkdir(parents=True, exist_ok=True)
    render(branding, transparent=False)


if __name__ == "__main__":
    main()
