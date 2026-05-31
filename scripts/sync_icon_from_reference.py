#!/usr/bin/env python3
"""Referans dürbün ikonunu kırp, kenar siyahlığı at, padding ekle, launcher'a yaz."""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "yetenek_avcisi" / "assets" / "icon"
BRANDING = ROOT / "yetenek_avcisi" / "assets" / "branding" / "scoutiq_icon.png"
SIZE = 1024
BG = (11, 15, 25)
BG_CENTER = (18, 24, 38)
# Grafik alanı — kenarlarda nefes payı (~%16 padding)
GRAPHIC_FILL = 0.72


def _is_letterbox_black(r: int, g: int, b: int, a: int) -> bool:
    if a < 10:
        return True
    return r < 28 and g < 28 and b < 32


def _is_navy_bg(r: int, g: int, b: int, a: int) -> bool:
    if a < 20:
        return True
    return r < 70 and g < 70 and b < 95 and (r + g + b) < 160


def _is_foreground_green(r: int, g: int, b: int, a: int) -> bool:
    if a < 40:
        return False
    return g > 90 and g > r * 1.2 and (r + g + b) > 100


def crop_letterbox(img: Image.Image) -> Image.Image:
    w, h = img.size
    px = img.convert("RGBA").load()

    def col_black(x: int) -> bool:
        dark = 0
        for y in range(h):
            r, g, b, a = px[x, y]
            if _is_letterbox_black(r, g, b, a):
                dark += 1
        return dark >= h * 0.9

    left = 0
    while left < w and col_black(left):
        left += 1
    right = w - 1
    while right > left and col_black(right):
        right -= 1
    if right - left < 32:
        return img
    return img.crop((left, 0, right + 1, h))


def content_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    px = img.convert("RGBA").load()
    w, h = img.size
    min_x, min_y, max_x, max_y = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if _is_foreground_green(r, g, b, a):
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x <= min_x:
        return 0, 0, w, h
    pad = int(max(w, h) * 0.04)
    return (
        max(0, min_x - pad),
        max(0, min_y - pad),
        min(w, max_x + pad),
        min(h, max_y + pad),
    )


def radial_background() -> Image.Image:
    img = Image.new("RGB", (SIZE, SIZE), BG)
    draw = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    steps = 48
    for i in range(steps, 0, -1):
        t = i / steps
        r = int((SIZE * 0.72) * t)
        color = (
            int(BG[0] + (BG_CENTER[0] - BG[0]) * (1 - t) * 0.35),
            int(BG[1] + (BG_CENTER[1] - BG[1]) * (1 - t) * 0.35),
            int(BG[2] + (BG_CENTER[2] - BG[2]) * (1 - t) * 0.35),
        )
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)
    return img


def extract_green_layer(img: Image.Image) -> Image.Image:
    """Sadece neon yeşil pikseller — referanstaki lacivert kutu kalmasın."""
    src = img.convert("RGBA")
    w, h = src.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    spx = src.load()
    opx = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = spx[x, y]
            if _is_foreground_green(r, g, b, a):
                opx[x, y] = (r, g, b, 255)
            elif g > 70 and g >= r and g >= b and a > 100:
                opx[x, y] = (0, 255, 135, 255)
    return out


def build_icon_from_reference(path: Path) -> tuple[Image.Image, Image.Image]:
    raw = Image.open(path).convert("RGBA")
    cropped = crop_letterbox(raw)
    x0, y0, x1, y1 = content_bbox(cropped)
    graphic = extract_green_layer(cropped.crop((x0, y0, x1, y1)))

    target = int(SIZE * GRAPHIC_FILL)
    scale = min(target / graphic.width, target / graphic.height)
    nw = max(1, int(graphic.width * scale))
    nh = max(1, int(graphic.height * scale))
    graphic = graphic.resize((nw, nh), Image.Resampling.LANCZOS)

    full = radial_background().convert("RGBA")
    ox = (SIZE - nw) // 2
    oy = (SIZE - nh) // 2
    full.paste(graphic, (ox, oy), graphic)

    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    fg.paste(graphic, (ox, oy), graphic)

    return full.convert("RGB"), fg


def main() -> None:
    ref = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if ref is None or not ref.exists():
        default = (
            ROOT.parent
            / ".cursor"
            / "projects"
            / "Users-musaok-Projects-yetenek-avcisi"
            / "assets"
            / "image-cc45a7c0-e54b-41f3-90c7-075f0478e105.png"
        )
        ref = default if default.exists() else None
    if ref is None or not ref.exists():
        raise SystemExit("Referans PNG bulunamadı.")

    full, fg = build_icon_from_reference(ref)
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    full.save(ICON_DIR / "app_icon.png", optimize=True)
    fg.save(ICON_DIR / "app_icon_foreground.png", optimize=True)
    BRANDING.parent.mkdir(parents=True, exist_ok=True)
    full.save(BRANDING, optimize=True)
    ref_copy = ICON_DIR / "scoutiq_reference.png"
    Image.open(ref).save(ref_copy)
    print(f"source: {ref}")
    print(f"graphic fill: {GRAPHIC_FILL:.0%} of {SIZE}px")
    print(f"wrote {ICON_DIR / 'app_icon.png'}")
    print(f"wrote {ICON_DIR / 'app_icon_foreground.png'}")
    print(f"wrote {BRANDING}")


if __name__ == "__main__":
    main()
