# 🎨 Промпты для артов (ComfyUI, SDXL / Pixel Art модели)

Используй эти промпты в ComfyUI на своём ноутбуке (RTX 3070).
Формат: `<prompt>` — описание, negative prompt общий для всех.
Размер: 1024x1024 (или 512x512 для пиксель-арта, потом апскейл).

## Общий negative prompt
```
text, watermark, signature, logo, low quality, worst quality, blurry,
jpeg artifacts, deformed, bad anatomy, extra limbs, cluttered background
```

---

## 1. Ножи (4 скина) → assets/images/knives/
Прозрачный фон (green screen / flat magenta, потом убрать через remove_chroma_key.py)
Одинокий предмет в центре, крупным планом, вид сбоку, вертикально.

- knife_gold.png:
  `single golden boomerang-shaped throwing knife, ornate medieval gold blade with
  amber handle, side view, centered, full object, game sprite, high detail,
  flat solid magenta background, no shadows on background`
- knife_neon.png:
  `single glowing neon green cyberpunk boomerang knife, futuristic energy blade,
  side view, centered, full object, game sprite, high detail,
  flat solid magenta background`
- knife_ice.png:
  `single ice-blue crystal boomerang knife, frozen blade with frost details,
  light blue handle, side view, centered, full object, game sprite,
  flat solid magenta background`
- knife_ruby.png:
  `single ruby-red boomerang knife, crimson blade, dark wood handle,
  side view, centered, full object, game sprite, flat solid magenta background`

## 2. Цель → assets/images/target/
- target_round.png:
  `wooden circular target board with 8 radial segments, bullseye center,
  fantasy style, flat front view, centered, game prop sprite,
  flat solid magenta background`

## 3. Фон → assets/images/background/
- bg_main.png:
  `night forest silhouette background for mobile game, moody blue-purple sky,
  distant pine trees, subtle stars, flat 2D game art, no UI elements,
  portrait orientation`

## 4. UI элементы → assets/images/ui/
- btn_play.png:
  `round wooden button with play icon, flat 2D game UI, centered,
  flat solid magenta background`
- btn_settings.png:
  `round wooden gear button, flat 2D game UI, centered,
  flat solid magenta background`
- title_logo.png:
  `golden medieval font text "НОЖ БУМЕРАНГ", centered, game title logo,
  flat 2D, dark transparent background`
