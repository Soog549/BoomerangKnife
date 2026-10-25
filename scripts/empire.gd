extends Control
## ХАБ ИМПЕРИИ — мета-экран: база растёт от прогресса игрока.
## Показывает: уровень Империи, прогресс реликвий, миры (закрытые/открытые), статистику.

var _worlds: Array = []

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.10, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var tex := TextureRect.new()
	var pbg := "res://assets/images/packs/%s/bg.png" % GameState.style_pack
	if ResourceLoader.exists(pbg):
		tex.texture = load(pbg)
		tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.modulate = Color(1, 1, 1, 0.35)
		add_child(tex)

	var rank: int = _empire_rank()
	var title := Label.new()
	title.text = "ИМПЕРИЯ ZWS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.position = Vector2(0, 40)
	title.size = Vector2(720, 42)
	add_child(title)
	var lvl := Label.new()
	lvl.text = "Уровень Империи: %d" % rank
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.add_theme_font_size_override("font_size", 20)
	lvl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	lvl.position = Vector2(0, 86)
	lvl.size = Vector2(720, 28)
	add_child(lvl)

	var stats := Label.new()
	stats.text = "Монеты %d   ·   Реликвии %d   ·   Ачивки %d/12   ·   Скины %d" % [
		GameState.coins, GameState.relics_total, GameState.arena_ach.size(), GameState.owned_skins.size()]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 16)
	stats.position = Vector2(0, 122)
	stats.size = Vector2(720, 24)
	add_child(stats)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.1, 0.12, 0.18)
	bar_bg.position = Vector2(60, 158)
	bar_bg.size = Vector2(600, 18)
	add_child(bar_bg)
	var prog := float(GameState.max_level_reached) / 25.0
	var bar_fill := ColorRect.new()
	bar_fill.color = Color(1.0, 0.8, 0.25)
	bar_fill.position = Vector2(60, 158)
	bar_fill.size = Vector2(600.0 * clampf(prog, 0.0, 1.0), 18)
	add_child(bar_fill)
	var cap := Label.new()
	cap.text = "Прогресс: %d / 25 (открывает миры)" % GameState.max_level_reached
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 14)
	cap.position = Vector2(0, 182)
	cap.size = Vector2(720, 20)
	add_child(cap)

	# Миры
	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(40, 214)
	grid.size = Vector2(640, 480)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	var unlocked := GameState.max_level_reached
	var cur := Worlds.current_index()
	for i in range(Worlds.LIST.size()):
		var w: Dictionary = Worlds.LIST[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(308, 64)
		var lock: bool = unlocked < int(w["unlock"])
		if lock:
			b.text = "🔒 %s  (ур. %d)" % [str(w["name"]), int(w["unlock"])]
			b.disabled = true
		else:
			var tag := "  ★" if i == cur else ""
			b.text = "%s%s" % [str(w["name"]), tag]
			b.pressed.connect(_open_world.bind(i))
		grid.add_child(b)

	# Кнопки
	var vb := VBoxContainer.new()
	vb.position = Vector2(60, 712)
	vb.size = Vector2(600, 0)
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)
	var daily := Button.new()
	daily.text = "ЕЖЕДНЕВНАЯ НАГРАДА"
	daily.custom_minimum_size = Vector2(600, 52)
	daily.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/daily_rewards.tscn"))
	vb.add_child(daily)
	var col := Button.new()
	col.text = "КОЛЛЕКЦИЯ И ДОСТИЖЕНИЯ"
	col.custom_minimum_size = Vector2(600, 52)
	col.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/collection.tscn"))
	vb.add_child(col)
	var back := Button.new()
	back.text = "НАЗАД"
	back.custom_minimum_size = Vector2(600, 52)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	vb.add_child(back)

	AudioManager.play_music("menu")


func _empire_rank() -> int:
	return 1 + int(Worlds.current_index()) + int(GameState.owned_skins.size() >= 6)


func _open_world(i: int) -> void:
	get_tree().change_scene_to_file("res://scenes/worlds.tscn")
