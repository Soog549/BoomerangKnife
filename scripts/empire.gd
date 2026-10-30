extends Control
## КАРТА ИМПЕРИИ — интерактивное меню: иконки-переходы по «территории».

const NODES := [
	{"t": "КАМПАНИЯ", "s": "res://scenes/game.tscn", "x": 0.18, "y": 0.16},
	{"t": "АРЕНА", "s": "res://scenes/mob_arena.tscn", "x": 0.52, "y": 0.12},
	{"t": "ОБОРОНА", "s": "res://scenes/td.tscn", "x": 0.82, "y": 0.20},
	{"t": "ДУЭЛЬ", "s": "res://scenes/duel.tscn", "x": 0.30, "y": 0.34},
	{"t": "МИРЫ", "s": "res://scenes/worlds.tscn", "x": 0.70, "y": 0.38},
	{"t": "МАГАЗИН", "s": "res://scenes/shop.tscn", "x": 0.18, "y": 0.56},
	{"t": "КОЛЛЕКЦИЯ", "s": "res://scenes/collection.tscn", "x": 0.52, "y": 0.60},
	{"t": "ПЕРСОНАЖ", "s": "res://scenes/profile.tscn", "x": 0.80, "y": 0.54},
	{"t": "НАСТРОЙКИ", "s": "res://scenes/settings.tscn", "x": 0.36, "y": 0.74},
]


func _ready() -> void:
	AudioManager.play("click")
	AudioManager.play_music("menu")
	var bg := TextureRect.new()
	var pbg := "res://assets/images/packs/%s/bg.jpg" % GameState.style_pack
	if ResourceLoader.exists(pbg):
		bg.texture = load(pbg)
	else:
		bg.texture = load("res://assets/images/ui/splash-hd-1440x2560.png") if ResourceLoader.exists("res://assets/images/ui/splash-hd-1440x2560.png") else null
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(1, 1, 1, 0.55)
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.07, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var title := Label.new()
	title.text = "КАРТА ИМПЕРИИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.position = Vector2(0, UIKit.M)
	title.size = Vector2(UIKit.W, 36)
	add_child(title)

	var lvl := Label.new()
	lvl.text = "Глава %d: %s · Реликвии: %d" % [GameState.chapter_index() + 1, GameState.chapter_name(), GameState.relics_total]
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.add_theme_font_size_override("font_size", 15)
	lvl.position = Vector2(0, UIKit.M + 40)
	lvl.size = Vector2(UIKit.W, 22)
	add_child(lvl)

	for n in NODES:
		_add_node(n)

	_add_special()
	UIKit.back(self, "res://scenes/main_menu.tscn")

	var rec := Label.new()
	rec.text = "РАШ: %d  ·  ВЫЖ: %d" % [GameState.best_rush_waves, GameState.best_survival_waves]
	rec.add_theme_font_size_override("font_size", 16)
	rec.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	rec.position = Vector2(24, 1280.0 - 60.0)
	add_child(rec)



func _add_node(n: Dictionary) -> void:
	var b := Button.new()
	b.text = str(n["t"])
	b.custom_minimum_size = Vector2(190, 84)
	b.size = Vector2(190, 84)
	b.position = Vector2(float(n["x"]) * 720.0 - 95.0, float(n["y"]) * 1280.0)
	b.add_theme_font_size_override("font_size", 15)
	b.modulate = Color(1, 1, 1, 0.92)
	var path: String = str(n["s"])
	b.pressed.connect(func() -> void:
		AudioManager.play("click")
		GameState.last_mode_scene = path if path.contains("arena") or path.contains("td") or path.contains("duel") or path.contains("game") else GameState.last_mode_scene
		get_tree().change_scene_to_file(path))
	add_child(b)
	# «дорога» под иконкой
	var dot := ColorRect.new()
	dot.color = Color(0.55, 0.85, 1.0, 0.35)
	dot.size = Vector2(6, 6)
	dot.position = b.position + Vector2(92, 90)
	add_child(dot)


func _add_special() -> void:
	var g := Button.new()
	g.text = "ГИЛЬДИЯ"
	g.size = Vector2(190, 84)
	g.position = Vector2(0.10 * 720.0, 0.70 * 1280.0)
	g.add_theme_font_size_override("font_size", 15)
	g.pressed.connect(_guild_pressed)
	add_child(g)

	var zones := [
		{"t": "ОКРАИНА\n(easy)", "d": "easy", "x": 0.34},
		{"t": "ПУСТОШЬ\n(normal)", "d": "normal", "x": 0.50},
		{"t": "РУБЕЖ\n(hard)", "d": "hard", "x": 0.66},
		{"t": "БОСС-РАШ", "d": "normal", "x": 0.82, "m": "rush"},
		{"t": "ВЫЖИВАНИЕ", "d": "hard", "x": 0.34, "y": 0.78, "m": "surv"},
	]
	for z in zones:
		var b := Button.new()
		b.text = str(z["t"])
		b.size = Vector2(120, 76)
		b.position = Vector2(float(z["x"]) * 720.0 - 60.0, float(z.get("y", 0.70)) * 1280.0)
		b.add_theme_font_size_override("font_size", 13)
		var dd: String = str(z["d"])
		var mm: String = str(z.get("m", ""))
		b.pressed.connect(func() -> void:
			GameState.difficulty = dd
			GameState.rush_mode = mm == "rush"
			GameState.survival_arena = mm == "surv"
			GameState.save_settings()
			AudioManager.play("click")
			GameState.last_mode_scene = "res://scenes/mob_arena.tscn"
			get_tree().change_scene_to_file("res://scenes/mob_arena.tscn"))
		add_child(b)


func _guild_pressed() -> void:
	AudioManager.play("click")
	if GameState.chapter_quest == "guild":
		GameState.chapter_quest = "mobs"
		GameState.save_settings()
		Toast.show(tr("ЗАДАНИЕ: зачисти 3 зоны карты (Окраина → Пустошь → Рубеж)"))
	else:
		Toast.show(tr("Сейчас заданий нет. Пройди тренировку 5 мишеней в Кампании."))
