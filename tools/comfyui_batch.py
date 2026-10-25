#!/usr/bin/env python3
"""
Массовая генерация ассетов для «Нож Бумеранг» через ComfyUI API.

Требования:
  - ComfyUI запущен с флагом --listen (по умолчанию http://127.0.0.1:8188)
  - Подключена модель (сюда можно подставить свою; по умолчанию пустая)

Запуск:
  python comfyui_batch.py               # все ассеты
  python comfyui_batch.py knives        # только ножи
  python comfyui_batch.py --dry         # показать план без генерации

Скрипт пишет PNG в ../assets/images/<категория>/<имя>.png
"""

import json
import sys
import time
import urllib.request
import urllib.parse
import os
from pathlib import Path

COMFY_URL = os.environ.get("COMFY_URL", "http://127.0.0.1:8188")
ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "assets" / "images"

# negative prompt, общий
NEG = ("text, watermark, signature, logo, low quality, worst quality, blurry, "
       "jpeg artifacts, deformed, bad anatomy, extra limbs, cluttered background")

ASSETS = [
    ("knives", "knife_gold",
     "single golden boomerang-shaped throwing knife, ornate medieval gold blade "
     "with amber handle, side view, centered, full object, game sprite, high detail, "
     "flat solid magenta background"),
    ("knives", "knife_neon",
     "single glowing neon green cyberpunk boomerang knife, futuristic energy blade, "
     "side view, centered, full object, game sprite, high detail, "
     "flat solid magenta background"),
    ("knives", "knife_ice",
     "single ice-blue crystal boomerang knife, frozen blade with frost details, "
     "light blue handle, side view, centered, full object, game sprite, "
     "flat solid magenta background"),
    ("knives", "knife_ruby",
     "single ruby-red boomerang knife, crimson blade, dark wood handle, "
     "side view, centered, full object, game sprite, flat solid magenta background"),
    ("target", "target_round",
     "wooden circular target board with 8 radial segments, bullseye center, "
     "fantasy style, flat front view, centered, game prop sprite, "
     "flat solid magenta background"),
    ("background", "bg_main",
     "night forest silhouette background for mobile game, moody blue-purple sky, "
     "distant pine trees, subtle stars, flat 2D game art, portrait orientation, "
     "no UI elements"),
    ("ui", "btn_play",
     "round wooden button with play icon, flat 2D game UI, centered, "
     "flat solid magenta background"),
    ("ui", "btn_settings",
     "round wooden gear button, flat 2D game UI, centered, "
     "flat solid magenta background"),
    ("ui", "title_logo",
     "golden medieval font text NOJ BUMERANG title logo, centered, "
     "flat 2D game UI, dark background"),
]


def build_workflow(prompt: str):
    """Собирает простой workflow: Checkpoint (заглушка) -> CLIPText -> KSampler -> SaveImage."""
    # Здесь подставь свой чекпоинт. Пример: "v1-5-pruned-emaonly.safetensors"
    checkpoint = "put_your_checkpoint_here.safetensors"
    return {
        "4": {"class_type": "CheckpointLoaderSimple",
              "inputs": {"ckpt_name": checkpoint}},
        "6": {"class_type": "CLIPTextEncode",
              "inputs": {"text": prompt, "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode",
              "inputs": {"text": NEG, "clip": ["4", 1]}},
        "5": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "3": {"class_type": "KSampler",
              "inputs": {"seed": int(time.time() * 1000) % 2**31,
                         "steps": 30, "cfg": 7.0, "sampler_name": "euler",
                         "scheduler": "normal", "denoise": 1.0,
                         "model": ["4", 0], "positive": ["6", 0],
                         "negative": ["7", 0], "latent_image": ["5", 0]}},
        "8": {"class_type": "VAEDecode",
              "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage",
              "inputs": {"filename_prefix": "boomerang", "images": ["8", 0]}},
    }


def queue_prompt(workflow):
    data = json.dumps({"prompt": workflow}).encode()
    req = urllib.request.Request(f"{COMFY_URL}/prompt", data=data,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())["prompt_id"]


def wait_complete(prompt_id, timeout=300):
    start = time.time()
    while time.time() - start < timeout:
        try:
            req = urllib.request.Request(f"{COMFY_URL}/history/{prompt_id}")
            with urllib.request.urlopen(req) as resp:
                hist = json.loads(resp.read())
            if prompt_id in hist:
                return hist[prompt_id]
        except Exception:
            pass
        time.sleep(2)
    return None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry" in sys.argv
    only = args[0] if args else None

    for category, name, prompt in ASSETS:
        if only and category != only and only != name:
            continue
        out_dir = IMAGES / category
        out_dir.mkdir(parents=True, exist_ok=True)
        dest = out_dir / f"{name}.png"
        print(f"[*] {category}/{name}")
        if dry:
            print(f"    -> {dest}")
            continue
        if dest.exists():
            print(f"    skip (уже есть: {dest})")
            continue
        try:
            wf = build_workflow(prompt)
            pid = queue_prompt(wf)
            print(f"    queued {pid}, жду...")
            res = wait_complete(pid)
            if res:
                print(f"    готово: {dest}  (НЕ забудь убрать magenta-фон через remove_chroma_key.py)")
            else:
                print("    ТАЙМАУТ / ошибка — проверь ComfyUI")
        except Exception as e:
            print(f"    ОШИБКА: {e}")


if __name__ == "__main__":
    main()
