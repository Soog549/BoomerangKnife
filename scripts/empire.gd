extends Control
## ДРЕВО ИМПЕРИИ — персональное меню-навигация по роадмапу (под Императора).
## Ветви: РЕЛИЗ · ИГРЫ · КОНТЕНТ · НАСТРОЙКИ · АУДИТ. Дип-Про, 2026-10-24.

var info: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.11, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "ДРЕВО ИМПЕРИИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.position = Vector2(0, 14)
	title.size = Vector2(720, 38)
	add_child(title)
	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 16)
	info.position = Vector2(0, 52)
	info.size = Vector2(720, 24)
	info.text = "Монеты: %d  |  Реликвии: %d  |  Ачивки: %d/12  |  Ножи: %d" % [GameState.coins, GameState.relics_total, GameState.arena_ach.size(), 1 + GameState.extra_knives]
	add_child(info)

	var sc := ScrollContainer.new()
	sc.position = Vector2(30, 86)
	sc.size = Vector2(660, 1000)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(660, 0)
	v.add_theme_constant_override("separation", 8)
	sc.add_child(v)

	v.add_child(_node("РЕЛИЗ BK — 11/11 ", "Кит: E:\\Realese_BOOKNIFE\\04_DOCS", ""))
	v.add_child(_node("  |- ПРОВЕРКА ГОТОВНОСТИ", "gate 11/11 · CI 3/3 · PCK 33 МБ · ID 590498", ""))
	v.add_child(_node("  |- ПРОФИЛЬ ИГРОКА", "статистика и достижения", "res://scenes/stats.tscn"))
	v.add_child(_node("ИГРЫ", "", ""))
	v.add_child(_node("  |- Арена мобов", "ножи/магазин/лут/боссы", "res://scenes/mob_arena.tscn"))
	v.add_child(_node("  |- TD-прото", "3 карты/башни/боссы", "res://scenes/td.tscn"))
	v.add_child(_node("  \\- Классика / Бесконечный", "Knife Hit-ядро", "res://scenes/main_menu.tscn"))
	v.add_child(_node("КОНТЕНТ", "", ""))
	v.add_child(_node("  |- Коллекция", "лор + достижения", "res://scenes/collection.tscn"))
	v.add_child(_node("  \\- Магазин", "скины/аватары/щиты", "res://scenes/shop.tscn"))
	v.add_child(_node("НАСТРОЙКИ", "", ""))
	v.add_child(_node("  |- МОЯ ИГРА", "сложность/дроп/управление", "res://scenes/my_game.tscn"))
	v.add_child(_node("  \\- Настройки", "звук/язык/персонаж", "res://scenes/settings.tscn"))
	v.add_child(_node("АУДИТ / МЕТРИКИ", "gate 11/11 · CI 3/3 · golden v4", ""))
	v.add_child(_node("ПЛАН", "наполнение  игра  Руслан  мир", ""))

	var back := Button.new()
	back.text = " НАЗАД"
	back.position = Vector2(60, 1120)
	back.size = Vector2(600, 56)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(back)

func _node(text: String, sub: String, scene: String) -> Control:
	if scene == "" and sub == "":
		var l := Label.new()
		l.text = text
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", Color(0.6, 0.95, 0.8))
		return l
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(660, 52)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if scene != "":
		b.pressed.connect(func() -> void: get_tree().change_scene_to_file(scene))
	else:
		b.pressed.connect(func() -> void: info.text = sub)
	b.tooltip_text = sub
	return b
