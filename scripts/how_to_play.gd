extends Control

## Как играть: 3 шага с иконками и текстом.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 32.0
	vb.offset_right = -32.0
	vb.offset_top = 40.0
	vb.offset_bottom = -120.0
	vb.add_theme_constant_override("separation", 14)
	add_child(vb)

	var title := Label.new()
	title.text = tr("КАК ИГРАТЬ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(title)

	var steps := [
		["1", tr("СВАЙП — ДВИЖЕНИЕ"), tr("Веди пальцем по полю — персонаж идёт за пальцем.")],
		["2", tr("ТАП — БРОСОК"), tr("Коснись цели: нож летит и возвращается бумерангом.")],
		["3", tr("УДАР ВБЛИЗИ"), tr("Подойди вплотную и нажми «УДАР», когда нож в руке.")],
	]
	for s in steps:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var num := Label.new()
		num.text = str(s[0])
		num.add_theme_font_size_override("font_size", 40)
		num.add_theme_color_override("font_color", GameState.accent())
		num.custom_minimum_size = Vector2(48, 0)
		row.add_child(num)
		var txt := VBoxContainer.new()
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := Label.new()
		h.text = str(s[1])
		h.add_theme_font_size_override("font_size", 20)
		txt.add_child(h)
		var d := Label.new()
		d.text = str(s[2])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 15)
		d.add_theme_color_override("font_color", Color(0.8, 0.86, 0.95))
		txt.add_child(d)
		row.add_child(txt)
		vb.add_child(row)

	var tips := Label.new()
	tips.text = tr("Совет: золотые сектора мишени дают бонус. Боссы — каждые 3 волны.")
	tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips.add_theme_font_size_override("font_size", 14)
	tips.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	vb.add_child(tips)

	var back := Button.new()
	back.text = tr("ПОНЯТНО")
	back.custom_minimum_size = Vector2(240, 54)
	back.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	back.position = Vector2(get_viewport_rect().size.x * 0.5 - 120, get_viewport_rect().size.y - 90)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/settings.tscn"))
	add_child(back)
