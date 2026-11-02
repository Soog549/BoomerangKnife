extends Control

## Эволюция: 5 этапов от Искры до Империи. Валюта — Память.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vp: Vector2 = get_viewport_rect().size
	var sc := ScrollContainer.new()
	sc.position = Vector2(20, 20)
	sc.size = Vector2(vp.x - 40, vp.y - 120)
	add_child(sc)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(vp.x - 40, 0)
	vb.add_theme_constant_override("separation", 10)
	sc.add_child(vb)

	var title := Label.new()
	title.text = tr("ЭВОЛЮЦИЯ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(title)

	var pts := Label.new()
	pts.text = tr("Память: %d") % GameState.evo_points
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pts.add_theme_font_size_override("font_size", 16)
	pts.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	vb.add_child(pts)

	for i in GameState.EVO.size():
		var e: Dictionary = GameState.EVO[i]
		var opened: bool = GameState.evo_unlocked(i)
		var can: bool = GameState.evo_can_open(i)
		var row := VBoxContainer.new()
		var head := Label.new()
		head.text = "%d. %s%s" % [i + 1, str(e["name"]), ("  ✓" if opened else "")]
		head.add_theme_font_size_override("font_size", 18)
		head.add_theme_color_override("font_color",
			Color(0.6, 0.95, 0.7) if opened else Color(0.85, 0.9, 1.0))
		row.add_child(head)
		var d := Label.new()
		d.text = str(e["desc"])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 13)
		d.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
		row.add_child(d)
		if not opened:
			var bar := ProgressBar.new()
			bar.max_value = 1.0
			bar.value = GameState.evo_progress(i)
			bar.custom_minimum_size = Vector2(0, 14)
			bar.show_percentage = false
			row.add_child(bar)
			if can:
				var b := Button.new()
				b.text = tr("ОТКРЫТЬ ЭТАП")
				b.custom_minimum_size = Vector2(0, 46)
				var idx: int = i
				b.pressed.connect(func() -> void:
					if GameState.evo_open(idx):
						AudioManager.play("level")
						Toast.show(tr("Этап открыт: %s") % str(GameState.EVO[idx]["name"]))
						get_tree().reload_current_scene())
				row.add_child(b)
		vb.add_child(row)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2(20, vp.y - 88)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/empire.tscn"))
	add_child(back)
