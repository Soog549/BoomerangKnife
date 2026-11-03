extends Control
## КАРТА ИМПЕРИИ — интерактивное меню: иконки-переходы по «территории».

const NODES := [
	{"t": "◆ КАМПАНИЯ", "s": "res://scenes/locations.tscn", "x": 0.18, "y": 0.13},
	{"t": "◆ АРЕНА", "s": "res://scenes/mob_arena.tscn", "x": 0.52, "y": 0.11},
	{"t": "◆ ОБОРОНА", "s": "res://scenes/td.tscn", "x": 0.82, "y": 0.17},
	{"t": "◆ ДУЭЛЬ", "s": "res://scenes/duel.tscn", "x": 0.20, "y": 0.28},
	{"t": "◆ МИРЫ", "s": "res://scenes/worlds.tscn", "x": 0.76, "y": 0.30},
	{"t": "◆ МАГАЗИН", "s": "res://scenes/shop.tscn", "x": 0.18, "y": 0.42},
	{"t": "◆ КОЛЛЕКЦИЯ", "s": "res://scenes/collection.tscn", "x": 0.52, "y": 0.44},
	{"t": "◆ ПЕРСОНАЖ", "s": "res://scenes/profile.tscn", "x": 0.82, "y": 0.40},
	{"t": "◆ НАСТРОЙКИ", "s": "res://scenes/settings.tscn", "x": 0.50, "y": 0.86},
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
	rec.position = Vector2(24, 92.0)
	var dcl := Label.new()
	dcl.text = "Испытания: " + str(GameState.daily_ready_count()) + " · сброс через " + GameState.ad_reset_in_text()
	dcl.add_theme_font_size_override("font_size", 13)
	dcl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.75))
	dcl.position = Vector2(24, 112.0)
	add_child(dcl)
	var sl := Label.new()
	sl.text = "Сезон: осталось " + str(GameState.season_days_left()) + " дн."
	sl.add_theme_font_size_override("font_size", 13)
	sl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5))
	sl.position = Vector2(24, 132.0)
	add_child(sl)
	var adv_b := Button.new()
	adv_b.text = tr("ПРИКЛЮЧЕНИЕ")
	adv_b.position = Vector2(250, 985.0)
	adv_b.size = Vector2(160, 56)
	adv_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/adventure.tscn"))
	add_child(adv_b)
	var surv_b := Button.new()
	surv_b.text = tr("ВЫЖИВАНИЕ-МИР")
	surv_b.position = Vector2(110, 1040.0)
	surv_b.size = Vector2(160, 52)
	surv_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/survival.tscn"))
	add_child(surv_b)
	var quiz_b := Button.new()
	quiz_b.text = tr("ВИКТОРИНА")
	quiz_b.position = Vector2(430, 1040.0)
	quiz_b.size = Vector2(140, 52)
	quiz_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/quiz.tscn"))
	add_child(quiz_b)
	var rts_b := Button.new()
	rts_b.text = tr("СТРАТЕГИЯ")
	rts_b.position = Vector2(560, 985.0)
	rts_b.size = Vector2(140, 56)
	rts_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/rts.tscn"))
	add_child(rts_b)
	var evo_b := Button.new()
	evo_b.text = tr("ЭВОЛЮЦИЯ")
	evo_b.position = Vector2(430, 985.0)
	evo_b.size = Vector2(140, 56)
	evo_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/evo.tscn"))
	add_child(evo_b)
	var camp_b := Button.new()
	camp_b.text = tr("КАМПАНИЯ")
	camp_b.position = Vector2(110, 925.0)
	camp_b.size = Vector2(160, 52)
	camp_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		_open_mode_sheet("КАМПАНИЯ", [
			["ЛОКАЦИИ", "res://scenes/locations.tscn"],
			["ПРИКЛЮЧЕНИЕ", "res://scenes/adventure.tscn"],
		]))
	add_child(camp_b)
	var front_b := Button.new()
	front_b.text = tr("РУБЕЖ")
	front_b.position = Vector2(290, 925.0)
	front_b.size = Vector2(150, 52)
	front_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		_open_mode_sheet("РУБЕЖ", [
			["АРЕНА · ОБОРОНА · РАШ", "arena"],
			["ВЫЖИВАНИЕ · СТРАТЕГИЯ", "survival"],
			["ВИКТОРИНА", "res://scenes/quiz.tscn"],
		]))
	add_child(front_b)
	var world_b := Button.new()
	world_b.text = tr("МИР")
	world_b.position = Vector2(460, 925.0)
	world_b.size = Vector2(110, 52)
	world_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		_open_mode_sheet("МИР", [
			["ВЫЖИВАНИЕ-МИР", "res://scenes/survival.tscn"],
			["СЕТЬ · КООП", "res://scenes/network.tscn"],
			["ЭВОЛЮЦИЯ", "res://scenes/evo.tscn"],
		]))
	add_child(world_b)
	var train := Button.new()
	train.text = tr("ТРЕНИРОВКА")
	train.position = Vector2(110, 985.0)
	train.size = Vector2(140, 56)
	train.pressed.connect(func() -> void:
		GameState.training_mode = true
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/mob_arena.tscn"))
	add_child(train)
	if GameState.chest_available():
		var chest := Button.new()
		chest.text = tr("🎁 СУНДУК")
		chest.position = Vector2(290, 985.0)
		chest.size = Vector2(150, 56)
		chest.pressed.connect(func() -> void:
			AudioManager.play("level")
			var rew: Dictionary = GameState.claim_chest()
			Toast.show(tr("Сундук: %s") % str(rew.get("amount", 0)))
			get_tree().reload_current_scene())
		add_child(chest)
	if GameState.can_claim_daily():
		var gift := Button.new()
		gift.text = tr("ПОДАРОК")
		gift.position = Vector2(560, 120.0)
		gift.size = Vector2(136, 56)
		gift.pressed.connect(func() -> void:
			AudioManager.play("click")
			get_tree().change_scene_to_file("res://scenes/daily_rewards.tscn"))
		add_child(gift)
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
	g.size = Vector2(200, 76)
	g.position = Vector2(0.12 * 720.0, 0.56 * 1280.0)
	g.add_theme_font_size_override("font_size", 15)
	g.pressed.connect(_guild_pressed)
	add_child(g)

	var zones := [
		{"t": "◆ ОКРАИНА", "d": "easy", "x": 0.50, "y": 0.56},
		{"t": "◆ ПУСТОШЬ", "d": "normal", "x": 0.84, "y": 0.56},
		{"t": "◆ РУБЕЖ", "d": "hard", "x": 0.20, "y": 0.68},
		{"t": "◆ БОСС-РАШ", "d": "normal", "x": 0.52, "y": 0.68, "m": "rush"},
		{"t": "◆ ВЫЖИВАНИЕ", "d": "hard", "x": 0.82, "y": 0.68, "m": "surv"},
	]
	for z in zones:
		var b := Button.new()
		b.text = str(z["t"])
		b.size = Vector2(150, 72)
		b.position = Vector2(float(z["x"]) * 720.0 - 75.0, float(z.get("y", 0.56)) * 1280.0)
		b.add_theme_font_size_override("font_size", 13)
		var dd: String = str(z["d"])
		var mm: String = str(z.get("m", ""))
		b.pressed.connect(func() -> void:
			AudioManager.play("click")
			var best_txt := ""
			if mm == "rush":
				best_txt = tr("Рекорд: %d") % GameState.best_rush_waves
			elif mm == "surv":
				best_txt = tr("Рекорд: %d") % GameState.best_survival_waves
			var dlg := ConfirmationDialog.new()
			dlg.title = str(z["t"])
			dlg.dialog_text = "%s\n%s\n%s" % [
				tr("Сложность: %s") % dd, best_txt, tr("Начать?")]
			dlg.ok_button_text = tr("НАЧАТЬ")
			dlg.cancel_button_text = tr("Отмена")
			add_child(dlg)
			dlg.confirmed.connect(func() -> void:
				GameState.difficulty = dd
				GameState.rush_mode = mm == "rush"
				GameState.survival_arena = mm == "surv"
				GameState.save_settings()
				GameState.last_mode_scene = "res://scenes/mob_arena.tscn"
				get_tree().change_scene_to_file("res://scenes/mob_arena.tscn"))
			dlg.popup_centered())
		add_child(b)


func _guild_pressed() -> void:
	AudioManager.play("click")
	if GameState.chapter_quest == "guild":
		GameState.chapter_quest = "mobs"
		GameState.save_settings()
		Toast.show(tr("ЗАДАНИЕ: зачисти 3 зоны карты (Окраина → Пустошь → Рубеж)"))
	else:
		Toast.show(tr("Сейчас заданий нет. Пройди тренировку 5 мишеней в Кампании."))


func _open_mode_sheet(title: String, items: Array) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title
	dlg.ok_button_text = tr("ЗАКРЫТЬ")
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	for it in items:
		var b := Button.new()
		b.text = str(it[0])
		b.custom_minimum_size = Vector2(360, 54)
		var target: String = str(it[1])
		b.pressed.connect(func() -> void:
			dlg.hide()
			_mode_open(target))
		vb.add_child(b)
	dlg.add_child(vb)
	add_child(dlg)
	dlg.popup_centered()


func _mode_open(target: String) -> void:
	AudioManager.play("click")
	match target:
		"arena":
			GameState.last_mode_scene = "res://scenes/mob_arena.tscn"
			get_tree().change_scene_to_file("res://scenes/mob_arena.tscn")
		"survival":
			GameState.survival_arena = true
			GameState.last_mode_scene = "res://scenes/mob_arena.tscn"
			get_tree().change_scene_to_file("res://scenes/mob_arena.tscn")
		_:
			get_tree().change_scene_to_file(target)
