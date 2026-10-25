#!/usr/bin/env python3
"""
Генерация простых PNG-плейсхолдеров БЕЗ зависимостей (чистый Python).
Нужны чтобы проверить, что система подхвата ассетов в Godot работает.
Реальные арты потом сгенерируй через ComfyUI (tools/comfyui_batch.py).
"""
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "assets" / "images"


def write_png(path: Path, size: int, pixels):
    """pixels: list[list[tuple[int,int,int,int]]] (RGBA)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = b""
    for row in pixels:
        raw += b"\x00"  # filter: none
        for r, g, b, a in row:
            raw += struct.pack("4B", r, g, b, a)
    def chunk(typ, data):
        c = struct.pack(">I", len(data)) + typ + data
        c += struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)
        return c
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", ihdr)
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(png)
    print(f"  ✓ {path.relative_to(ROOT)}")


def solid(size, rgb, alpha=255):
    return [[(*rgb, alpha)] * size for _ in range(size)]


def circle(size, rgb, radius_frac=0.42):
    """Круг на прозрачном фоне."""
    center = (size - 1) / 2
    radius = size * radius_frac
    img = []
    for y in range(size):
        row = []
        for x in range(size):
            dist = ((x - center) ** 2 + (y - center) ** 2) ** 0.5
            row.append((*rgb, 255 if dist <= radius else 0))
        img.append(row)
    return img


def vertical_knife(size, rgb, rgb2):
    """Примитивный нож (прямоугольник + рукоятка) на прозрачном фоне."""
    img = []
    cx = size // 2
    for y in range(size):
        row = []
        for x in range(size):
            a = 0
            col = (0, 0, 0)
            if y < size * 0.55:
                if abs(x - cx) <= size * 0.06:
                    a, col = 255, rgb
            elif y < size * 0.75:
                if abs(x - cx) <= size * 0.075:
                    a, col = 255, rgb2
            row.append((*col, a))
        img.append(row)
    return img


def main():
    print("Генерация плейсхолдеров ассетов...")
    knife_specs = [
        ("knife_gold", (242, 204, 77), (115, 76, 31)),
        ("knife_neon", (51, 255, 153), (26, 115, 77)),
        ("knife_ice", (128, 217, 255), (51, 102, 153)),
        ("knife_ruby", (255, 77, 77), (128, 26, 26)),
    ]
    for name, c1, c2 in knife_specs:
        write_png(IMAGES / "knives" / f"{name}.png", 64, vertical_knife(64, c1, c2))

    write_png(IMAGES / "target" / "target_round.png", 128,
              circle(128, (140, 102, 38), 0.46))

    # фон: вертикальный градиент
    size = 32
    grad = []
    for y in range(size):
        t = y / (size - 1)
        r = int(23 + (9 - 23) * t)
        g = int(28 + (11 - 28) * t)
        b = int(46 + (18 - 46) * t)
        grad.append([(r, g, b, 255)] * size)
    write_png(IMAGES / "background" / "bg_main.png", size, grad)

    for name in ("btn_play", "btn_settings"):
        write_png(IMAGES / "ui" / f"{name}.png", 64,
                  circle(64, (51, 102, 153), 0.45))
    print("Готово. Запусти игру — ножи, цель и фон теперь берутся из PNG.")


if __name__ == "__main__":
    main()
