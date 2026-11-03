extends Control
## Казарма: найм и прокачка юнитов (MVP).

func _ready() -> void:
	AudioManager.play("click")
	var vp: Vector2 = get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = tr("КАЗАРМА")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 24)
	title.size = Vector2(vp.x, 40)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GameState.accent())
	add_child(title)

	var wallet := Label.new()
	wallet.text = tr("Монеты: %d") % GameState.coins
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet.position = Vector2(0, 72)
	wallet.size = Vector2(vp.x, 28)
	wallet.add_theme_font_size_override("font_size", 16)
	add_child(wallet)

	var vb := VBoxContainer.new()
	vb.position = Vector2(24, 122)
	vb.size = Vector2(vp.x - 48, 900)
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)

	for u in GameState.UNIT_TYPES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var uid: String = str(u["id"])
		var uname: String = tr(str(u["name"]))
		var lvl := GameState.unit_level(uid)
		var info := Label.new()
		info.text = "%s  ·  ур.%d\n%s" % [uname, lvl, tr(str(u["desc"]))]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size = Vector2(0, 64)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 15)
		row.add_child(info)
		var b := Button.new()
		var cost := GameState.unit_hire_cost(uid)
		b.text = (tr("Нанять") if lvl == 0 else tr("Улучшить")) + " %d" % cost
		b.custom_minimum_size = Vector2(180, 56)
		b.disabled = GameState.coins < cost
		b.pressed.connect(func() -> void:
			AudioManager.play("level")
			if GameState.hire_unit(uid):
				Toast.show(tr("Нанят: ") + uname)
			get_tree().reload_current_scene())
		row.add_child(b)
		vb.add_child(row)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2((vp.x - 200) * 0.5, vp.y - 96)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/empire.tscn"))
	add_child(back)
