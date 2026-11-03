extends Control

## Карта кампании: 8 локаций, открытие по прохождению предыдущей.


func _ready() -> void:
	var bg := TextureRect.new()
	var p := "res://assets/images/packs/%s/bg.jpg" % GameState.style_pack
	if ResourceLoader.exists(p):
		bg.texture = load(p)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var vp: Vector2 = get_viewport_rect().size
	var sc := ScrollContainer.new()
	sc.position = Vector2(24, 24)
	sc.size = Vector2(vp.x - 48, vp.y - 130)
	add_child(sc)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(vp.x - 48, 0)
	vb.add_theme_constant_override("separation", 10)
	sc.add_child(vb)

	var title := Label.new()
	title.text = tr("КАМПАНИЯ · ЛОКАЦИИ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(title)

	for i in GameState.LOCATIONS.size():
		var loc: Dictionary = GameState.LOCATIONS[i]
		var unlocked: bool = GameState.location_unlocked(i)
		var done: int = GameState.location_levels_done(i)
		var total: int = GameState.location_total(i)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 84)
		if unlocked:
			var ep: String = str(loc.get("ep", ""))
			b.text = "%d. %s   (%d/%d)%s" % [i + 1, str(loc["name"]), mini(done, total), total, ("  ·  " + ep if ep != "" else "")]
			b.add_theme_font_size_override("font_size", 17)
			var idx: int = i
			b.pressed.connect(func() -> void:
				AudioManager.play("click")
				GameState.set_location(idx)
				get_tree().change_scene_to_file("res://scenes/game.tscn"))
		else:
			var prev_name: String = str(GameState.LOCATIONS[i - 1]["name"]) if i > 0 else "—"
			b.text = "%d. %s — закрыто\n   нужно пройти: %s (5+ уровней)" % [i + 1, str(loc["name"]), prev_name]
			b.add_theme_font_size_override("font_size", 13)
			b.disabled = true
		# _loc_row — превью стиля + кнопка с цветной рамкой
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(64, 64)
		thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.clip_contents = true
		var pbg := "res://assets/images/packs/%s/bg.jpg" % str(loc["style"])
		if ResourceLoader.exists(pbg):
			thumb.texture = load(pbg)
		row.add_child(thumb)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.12, 0.20, 0.92)
		sb.set_corner_radius_all(12)
		sb.border_color = GameState.ACCENTS[i % GameState.ACCENTS.size()]
		sb.set_border_width_all(2)
		sb.set_content_margin_all(6)
		b.add_theme_stylebox_override("normal", sb)
		row.add_child(b)
		vb.add_child(row)

		var d := Label.new()
		var end_kind: String = GameState.ending_for(i)
		var end_txt := ""
		if end_kind == "mercy":
			end_txt = "   ·   Милосердие"
		elif end_kind == "power":
			end_txt = "   ·   Сила"
		d.text = "    " + str(loc["desc"]) + end_txt
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 12)
		d.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95, 0.9))
		vb.add_child(d)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2(24, vp.y - 92)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/empire.tscn"))
	add_child(back)
