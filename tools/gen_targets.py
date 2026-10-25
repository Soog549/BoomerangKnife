#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_targets.py — генерация тематических мишеней BoomerangKnife (процедурно, PIL).
8 миров -> assets/images/target/target_<id>.png (512x512, круг-буллзай с палитрой мира).
  python tools/gen_targets.py
0 ₽, локально. ДиФоФлеш (03), 2026-10-17.
"""
from __future__ import annotations
import os, math
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "images", "target")
S = 512
C = S // 2

# мир: (внешнее кольцо, чередование A, чередование B, центр, акцент-метки, фон)
THEMES = {
    "forest":  ((74, 122, 58),   (46, 84, 38),   (150, 190, 110), (222, 190, 96),  (74, 122, 58),   (18, 24, 16)),
    "neon":    ((236, 60, 168),  (24, 24, 40),   (60, 220, 230),  (255, 220, 90),  (236, 60, 168),  (10, 10, 20)),
    "ice":     ((150, 200, 235), (222, 240, 255), (90, 150, 210), (255, 255, 255), (120, 180, 225), (12, 20, 32)),
    "ruby":    ((196, 40, 52),   (110, 20, 30),  (240, 120, 110), (255, 210, 120), (196, 40, 52),   (24, 10, 14)),
    "shadow":  ((96, 70, 132),   (34, 26, 48),   (150, 120, 200), (200, 180, 255), (96, 70, 132),   (10, 8, 16)),
    "elektro": ((248, 214, 70),  (40, 60, 130),  (90, 160, 240),  (255, 255, 255), (248, 214, 70),  (12, 14, 26)),
    "toxic":   ((120, 200, 60),  (30, 60, 30),   (180, 240, 90),  (230, 255, 120), (120, 200, 60),  (12, 20, 10)),
    "cosmos":  ((120, 100, 230), (24, 20, 52),   (200, 160, 255), (255, 240, 200), (120, 100, 230), (8, 8, 20)),
}


def draw_target(ring, a, b, center, accent, bg) -> Image.Image:
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # фон-круг
    d.ellipse([4, 4, S - 4, S - 4], fill=bg + (255,))
    # внешнее кольцо
    d.ellipse([6, 6, S - 6, S - 6], outline=ring + (255,), width=14)
    # концентрические кольца
    rings = 5
    for i in range(rings):
        r = int((S / 2 - 26) * (1 - i / rings))
        col = a if i % 2 == 0 else b
        d.ellipse([C - r, C - r, C + r, C + r], fill=col + (255,))
        d.ellipse([C - r, C - r, C + r, C + r], outline=bg + (120,), width=3)
    # центр
    d.ellipse([C - 26, C - 26, C + 26, C + 26], fill=center + (255,))
    # акцентные метки (радиальные штрихи)
    for k in range(12):
        ang = k * math.pi / 6
        x1, y1 = C + math.cos(ang) * (S / 2 - 34), C + math.sin(ang) * (S / 2 - 34)
        x2, y2 = C + math.cos(ang) * (S / 2 - 20), C + math.sin(ang) * (S / 2 - 20)
        d.line([x1, y1, x2, y2], fill=accent + (220,), width=5)
    return im


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for wid, pal in THEMES.items():
        im = draw_target(*pal)
        im.save(os.path.join(OUT, f"target_{wid}.png"))
        n += 1
        print("saved target_%s.png" % wid)
    print("total", n)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
