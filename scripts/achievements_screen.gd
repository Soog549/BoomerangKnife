extends Control

## Экран достижений: список с прогрессом и статусом.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vp: Vector2 = get_viewport_rect().size
	var sc := ScrollContainer.new()
	sc.position = Vector2(28, 26)
	sc.size = Vector2(vp.x - 56, vp.y - 140)
	add_child(sc)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(vp.x - 56, 0)
	vb.add_theme_constant_override("separation", 10)
	sc.add_child(vb)

	var title := Label.new()
	title.text = tr("ДОСТИЖЕНИЯ")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(title)

	var ach: Array = load("res://scripts/collection.gd").ACH
	var opened := 0
	if opened >= ach.size():
		var btn := Button.new()
		btn.text = tr("ЗАБРАТЬ НАГРАДУ ЗА 100% (10 💎)")
		btn.custom_minimum_size = Vector2(0, 52)
		btn.disabled = GameState.ach_reward_claimed
		if GameState.ach_reward_claimed:
			btn.text = tr("НАГРАДА ПОЛУЧЕНА")
		btn.pressed.connect(func() -> void:
			GameState.crystals += 10
			GameState.ach_reward_claimed = true
			GameState.save_settings()
			AudioManager.play("level")
			Toast.show(tr("+10 кристаллов за все достижения"))
			get_tree().reload_current_scene())
		vb.add_child(btn)

	for a in ach:
		if GameState.arena_ach.has(str(a[2])):
			opened += 1
	var info := Label.new()
	info.text = tr("Открыто %d / %d") % [opened, ach.size()]
	info.add_theme_font_size_override("font_size", 15)
	info.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	vb.add_child(info)

	var bar := ProgressBar.new()
	bar.max_value = float(ach.size())
	bar.value = float(opened)
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = false
	vb.add_child(bar)

	for a in ach:
		var got: bool = GameState.arena_ach.has(str(a[2]))
		var row := Label.new()
		row.text = "%s  %s  (%s)" % ["✔" if got else "–", str(a[0]), str(a[1])]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_color",
			Color(0.6, 0.95, 0.7) if got else Color(0.75, 0.8, 0.88))
		vb.add_child(row)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2(28, vp.y - 96)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/profile.tscn"))
	add_child(back)
