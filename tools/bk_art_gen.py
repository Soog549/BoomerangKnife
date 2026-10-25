#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
bk_art_gen.py — рабочая генерация спрайтов BoomerangKnife через ComfyUI API.

Зачем: заводской tools/comfyui_batch.py неполный (чекпоинт-заглушка, не качает
результат, не вырезает фон). Здесь — полный цикл: generate -> download -> rembg
-> trim -> square-pad -> assets/images/<category>/<name>.png

Запуск:
  python bk_art_gen.py knives            # все ножи (8)
  python bk_art_gen.py knife_gold        # один ассет
  python bk_art_gen.py --dry knives      # план без генерации
  python bk_art_gen.py --model sd_xl_base_1.0.safetensors knives
  BK_ART_KEEP_BG=1 ...  # пропустить фоновый backup

Стиль — по assets/prompts/STYLEGUIDE.md («Cozy Night Forest», полу-флэт).
"""
import base64
import io
import json
import os
import shutil
import sys
import time
import urllib.request
import urllib.parse
from pathlib import Path

COMFY = os.environ.get("COMFY_URL", "http://127.0.0.1:8188")
ROOT = Path(__file__).resolve().parent.parent
IMG = ROOT / "assets" / "images"

DEFAULT_MODEL = os.environ.get("BK_MODEL", "sd_xl_base_1.0.safetensors")

NEG = ("text, watermark, signature, logo, multiple knives, two knives, duplicate, "
       "extra objects, clutter, blurry, low quality, worst quality, jpeg artifacts, "
       "deformed, photorealistic, 3d render, busy background, hard shadow, hands, people")

KNIFE_SUFFIX = ("single boomerang-shaped throwing knife, smooth curved wing silhouette, "
                "side view, centered, isolated on plain solid light gray background, "
                "semi-flat vector game sprite, clean bold silhouette, cel shading, "
                "soft rim glow, cozy fantasy night style, high detail, no drop shadow")

BG_NEG = ("text, words, letters, letters, watermark, signature, logo, ui, hud, hud elements, "
          "buttons, menu, frame, border, caption, subtitle, characters, people, hands, "
          "blurry, low quality, worst quality, jpeg artifacts, clutter, photorealistic, 3d render")

WORLD_SUFFIX = ("flat 2D mobile game background, semi-flat vector art, cozy fantasy night style, "
                "portrait orientation, layered depth, soft glow, clean bold shapes, "
                "no text, no words, no characters, no UI, no logo, high detail")

UI_SUFFIX = ("clean mobile game UI icon, semi-flat vector art, cozy fantasy night style, "
             "bold simple silhouette, centered, isolated on plain solid light gray background, "
             "warm oak wood and amber, soft glow, no text, no letters, no words, no numbers, high detail")

# name, category, prompt, size, cut_bg
ASSETS = {
    "knife_gold":    ("knives", "golden medieval throwing knife, warm gold blade, amber wooden handle, " + KNIFE_SUFFIX, 1024, True),
    "knife_neon":    ("knives", "glowing neon green cyberpunk energy throwing knife, dark metal handle, " + KNIFE_SUFFIX, 1024, True),
    "knife_ice":     ("knives", "ice-blue crystal throwing knife, frozen translucent blade with frost, pale blue handle, " + KNIFE_SUFFIX, 1024, True),
    "knife_ruby":    ("knives", "ruby-red crimson throwing knife, glossy red blade, dark wood handle, " + KNIFE_SUFFIX, 1024, True),
    "knife_shadow":  ("knives", "dark obsidian throwing knife, smoky purple-black blade, matte dark handle, " + KNIFE_SUFFIX, 1024, True),
    "knife_elektro": ("knives", "electric throwing knife, cyan and yellow lightning energy blade, amber handle, " + KNIFE_SUFFIX, 1024, True),
    "knife_toxic":   ("knives", "acid green toxic throwing knife, glowing slime blade, dark green handle, " + KNIFE_SUFFIX, 1024, True),
    "knife_cosmos":  ("knives", "deep violet galaxy throwing knife, starry cosmic blade with nebula, obsidian handle, " + KNIFE_SUFFIX, 1024, True),
    "target_round":  ("target", "round wooden target board with 8 radial segments and a bullseye center, warm oak wood planks, thin dark seams, small metal rivets, fantasy style, straight front view, centered, isolated on plain solid light gray background, semi-flat vector game prop sprite, clean bold silhouette, high detail", 1024, True),
    "bg_main":       ("background", "flat 2D mobile game background, cozy night forest, deep midnight blue and indigo sky, layered silhouettes of pine trees, subtle stars, soft moon glow behind trees, depth in three layers, semi-flat vector art, no text, no characters, no UI, portrait orientation", (768, 1344), False),

    # --- Миры (слой лор + миры, см. LORE-WORLDS.md) — фоны для попапа-вставки ---
    "world_forest":  ("worlds", "cozy night forest clearing, deep midnight blue and indigo sky, layered pine tree silhouettes, warm fireflies, soft moon glow, distant warm window light, " + WORLD_SUFFIX, (768, 1344), False),
    "world_neon":    ("worlds", "neon cyberpunk road at night, glowing green and pink city lights, wet reflective asphalt, energy light streaks, distant towers, " + WORLD_SUFFIX, (768, 1344), False),
    "world_ice":     ("worlds", "frozen ice canyon, pale blue glaciers and icicles, aurora ribbons, falling snow, cold blue haze, " + WORLD_SUFFIX, (768, 1344), False),
    "world_ruby":    ("worlds", "volcanic ruby forge interior, glowing red embers, dark anvil silhouettes, orange sparks, molten ruby glow, " + WORLD_SUFFIX, (768, 1344), False),
    "world_shadow":  ("worlds", "dark misty thicket, purple-black twisted trees, low fog, faint purple lantern glow, ominous night, " + WORLD_SUFFIX, (768, 1344), False),
    "world_elektro": ("worlds", "stormy mountain peak, heavy thunderclouds, bright lightning bolts, cyan and yellow electricity arcs, night sky, " + WORLD_SUFFIX, (768, 1344), False),
    "world_toxic":   ("worlds", "toxic swamp, acid green mist, bubbling bogs, twisted bare trees, glowing spores, murky green glow, " + WORLD_SUFFIX, (768, 1344), False),
    "world_cosmos":  ("worlds", "cosmic space horizon, deep violet nebula, dense starfield, distant planets, faint dawn glow on the edge, " + WORLD_SUFFIX, (768, 1344), False),

    # --- UI (лого-эмблема + круглые деревянные кнопки, STYLEGUIDE §6) ---
    "logo_mark":    ("ui", "ornate round wooden badge emblem, a single boomerang throwing knife crossed in the center, warm oak wood ring, amber bevel, glowing amber core, fantasy game logo mark, " + UI_SUFFIX, 1024, True),
    "btn_blank":    ("ui", "plain round wooden button blank, empty carved wood disc with a subtle amber bevel ring and soft inner shading, no icon, no symbol, no letter, centered, isolated on plain solid light gray background, semi-flat vector game UI, cozy fantasy night style, high detail", 1024, True),
    "btn_play":     ("ui", "round wooden button with a bold carved play triangle icon in the center, dark oak, amber bevel ring, " + UI_SUFFIX, 1024, True),
    "btn_settings": ("ui", "round wooden button with a carved gear cog icon in the center, dark oak, amber bevel ring, " + UI_SUFFIX, 1024, True),
}

OUTPUT_NODE = "7"


def api(path, data=None):
    url = COMFY + path
    if data is None:
        with urllib.request.urlopen(url, timeout=60) as r:
            return json.loads(r.read())
    req = urllib.request.Request(url, data=json.dumps(data).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())


def build_wf(pos, neg, size, model):
    w, h = (size, size) if isinstance(size, int) else size
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": model}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": neg, "clip": ["1", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "5": {"class_type": "KSampler", "inputs": {
            "seed": int(time.time() * 1000) % 2**31, "steps": 30, "cfg": 7.0,
            "sampler_name": "dpmpp_2m_sde", "scheduler": "karras", "denoise": 1.0,
            "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        OUTPUT_NODE: {"class_type": "SaveImage", "inputs": {"filename_prefix": "bkart", "images": ["6", 0]}},
    }


def wait(pid, timeout=420):
    t0 = time.time()
    while time.time() - t0 < timeout:
        try:
            h = api(f"/history/{pid}")
            if pid in h:
                return h[pid]
        except Exception:
            pass
        time.sleep(2)
    return None


def download(entry):
    q = urllib.parse.urlencode({"filename": entry["filename"],
                                "subfolder": entry.get("subfolder", ""),
                                "type": entry.get("type", "output")})
    with urllib.request.urlopen(COMFY + "/view?" + q, timeout=120) as r:
        return r.read()


def gen(name, dry=False, model=DEFAULT_MODEL, force=False):
    category, prompt, size, cut = ASSETS[name]
    out_dir = IMG / category
    dest = out_dir / f"{name}.png"
    if dry:
        print(f"[dry] {category}/{name}  size={size}  cut={cut}  model={model}")
        return True
    if dest.exists() and not force:
        print(f"[skip] уже есть: {dest.name} (используй --force)")
        return True
    out_dir.mkdir(parents=True, exist_ok=True)
    try:
        neg = NEG if cut else BG_NEG
        wf = build_wf(prompt, neg, size, model)
        pid = api("/prompt", {"prompt": wf, "client_id": "bkart"})["prompt_id"]
        print(f"[*] {name}: queued {pid}, жду…")
        res = wait(pid)
        if not res:
            print(f"[!] {name}: таймаут ComfyUI")
            return False
        imgs = res.get("outputs", {}).get(OUTPUT_NODE, {}).get("images", [])
        if not imgs:
            print(f"[!] {name}: нет изображения в ответе: {json.dumps(res.get('status', {}))[:300]}")
            return False
        raw = download(imgs[-1])
        _process(raw, dest, cut, size)
        print(f"[ok] {dest}")
        return True
    except urllib.error.HTTPError as e:
        print(f"[!] {name}: HTTP {e.code}: {e.read()[:300]}")
        return False
    except Exception as e:
        print(f"[!] {name}: {e}")
        return False


def _process(raw, dest, cut, size):
    from PIL import Image
    img = Image.open(io.BytesIO(raw)).convert("RGBA")
    if not cut:
        # фон/полнокадровый ассет: вписать точно в заданный размер (без квадрата и обрезки)
        w, h = size if isinstance(size, tuple) else (size, size)
        img = img.resize((w, h), Image.LANCZOS).convert("RGB")
        img.save(dest)
        return
    from rembg import remove
    img = remove(img)
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    target = 512
    pad = int(target * 0.06)
    inner = target - 2 * pad
    scale = min(inner / img.width, inner / img.height)
    img = img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))), Image.LANCZOS)
    canvas = Image.new("RGBA", (target, target), (0, 0, 0, 0))
    canvas.paste(img, ((target - img.width) // 2, (target - img.height) // 2), img)
    canvas.save(dest)


def main():
    args = [a for a in sys.argv[1:]]
    dry = "--dry" in args
    force = "--force" in args
    model = DEFAULT_MODEL
    if "--model" in args:
        i = args.index("--model")
        model = args[i + 1]
        args = args[:i] + args[i + 2:]
    names = [a for a in args if not a.startswith("--")]
    if not names:
        names = list(ASSETS)
    elif names[0] in ("knives", "worlds", "target", "background", "ui"):
        group = names[0]
        names = [n for n, v in ASSETS.items() if v[0] == group]
    

    ok = 0
    for n in names:
        if n not in ASSETS:
            print(f"[?] неизвестный ассет: {n}")
            continue
        if gen(n, dry=dry, model=model, force=force):
            ok += 1
    print(f"\nИтого: {ok}/{len(names)}")


if __name__ == "__main__":
    main()
