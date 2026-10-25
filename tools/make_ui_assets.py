#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
make_ui_assets.py — собирает UI-ассеты BoomerangKnife из деревянной кнопки-заготовки
и эмблемы (генерируются bk_art_gen.py) в готовые кнопки и лого-титул.

Зачем: SDXL плохо рисует иконки/текст, поэтому:
  - btn_blank.png / logo_mark.png — из ComfyUI (bk_art_gen.py ui);
  - иконки Play/шестерёнка и надпись «НОЖ БУМЕРАНГ» — рисуем в PIL (чётко и воспроизводимо).

Запуск:
  python tools/bk_art_gen.py ui              # сначала сгенерировать btn_blank + logo_mark
  python tools/make_ui_assets.py             # затем собрать кнопки и лого

Выход: assets/images/ui/{btn_play,btn_settings,title_logo}.png
"""
import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
UI = ROOT / "assets" / "images" / "ui"
FONT = ROOT / "assets" / "fonts" / "neucha_regular.ttf"

CREAM = (232, 213, 181, 255)
DARK = (11, 16, 38, 255)
GOLD = (255, 213, 74, 255)


def play_icon(size=512):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    s = size * 0.34
    pts = [(cx - s * 0.55, cy - s), (cx - s * 0.55, cy + s), (cx + s * 0.95, cy)]
    e = size * 0.045
    out = [(cx - s * 0.55 - e, cy - s - e), (cx - s * 0.55 - e, cy + s + e), (cx + s * 0.95 + e, cy)]
    d.polygon(out, fill=DARK)
    d.polygon(pts, fill=CREAM)
    return img


def gear_icon(size=512, teeth=8):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    r_out, r_in, r_hole = size * 0.36, size * 0.28, size * 0.13
    step = math.pi * 2 / teeth
    for grow, col in ((size * 0.02, DARK), (0.0, CREAM)):
        pts = []
        for i in range(teeth):
            a0 = i * step
            for frac, r in ((0.0, r_in), (0.12, r_out), (0.38, r_out), (0.5, r_in)):
                a = a0 + frac * step
                pts.append((cx + math.cos(a) * (r + grow), cy + math.sin(a) * (r + grow)))
        d.polygon(pts, fill=col)
    d.ellipse([cx - r_hole, cy - r_hole, cx + r_hole, cy + r_hole], fill=DARK)
    return img


def compose_button(icon_name, out_name):
    blank = Image.open(UI / "btn_blank.png").convert("RGBA").resize((512, 512))
    blank.alpha_composite(play_icon() if icon_name == "play" else gear_icon())
    blank.save(UI / out_name)
    print("saved", out_name)


def make_title_logo():
    w, h = 720, 340
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mark = Image.open(UI / "logo_mark.png").convert("RGBA").resize((260, 260))
    img.alpha_composite(mark, ((w - 260) // 2, 0))
    d = ImageDraw.Draw(img)
    text = "НОЖ БУМЕРАНГ"
    fs = 76
    while fs > 30:
        font = ImageFont.truetype(str(FONT), fs)
        if d.textlength(text, font=font) <= w - 30:
            break
        fs -= 2
    font = ImageFont.truetype(str(FONT), fs)
    d.text((w // 2, 262), text, font=font, fill=GOLD, anchor="ma",
           stroke_width=max(4, fs // 12), stroke_fill=DARK)
    img.save(UI / "title_logo.png")
    print("saved title_logo.png", img.size, "fs=", fs)


def main():
    for need in ("btn_blank.png", "logo_mark.png"):
        if not (UI / need).exists():
            raise SystemExit(f"нет {need} — сначала: python tools/bk_art_gen.py ui")
    compose_button("play", "btn_play.png")
    compose_button("gear", "btn_settings.png")
    make_title_logo()


if __name__ == "__main__":
    main()
