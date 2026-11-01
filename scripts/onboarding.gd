extends Control

var step := 0

const STEPS := [
	["ДОБРО ПОЖАЛОВАТЬ В ИМПЕРИЮ", "Ты — Оператор. Память — валюта. Нож — твой бумеранг.", "ДАЛЕЕ"],
	["КАК ИГРАТЬ", "Свайп — движение. Тап по цели — бросок. УДАР — когда враг близко.", "ПОНЯТНО"],
	["ПРОГРЕСС", "Волны дают монеты и опыт. Улучшай снаряжение, открывай классы.", "В БОЙ"],
]


func _ready() -> void:
	_show_step()


func _show_step() -> void:
	for c in get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vp: Vector2 = get_viewport_rect().size
	var vb := VBoxContainer.new()
	vb.position = Vector2(32, vp.y * 0.22)
	vb.size = Vector2(vp.x - 64, vp.y * 0.5)
	vb.add_theme_constant_override("separation", 18)
	add_child(vb)

	var t := Label.new()
	t.text = str(STEPS[step][0])
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(t)

	var d := Label.new()
	d.text = str(STEPS[step][1])
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_font_size_override("font_size", 16)
	d.add_theme_color_override("font_color", GameState.ui_fg_color())
	vb.add_child(d)

	var dots := Label.new()
	dots.text = "● ○ ○" if step == 0 else ("○ ● ○" if step == 1 else "○ ○ ●")
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.add_theme_font_size_override("font_size", 20)
	vb.add_child(dots)

	var b := Button.new()
	b.text = tr(str(STEPS[step][2]))
	b.custom_minimum_size = Vector2(280, 56)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void:
		AudioManager.play("click")
		step += 1
		if step >= STEPS.size():
			GameState.onboarding_done = true
			GameState.save_settings()
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		else:
			_show_step())
	vb.add_child(b)
