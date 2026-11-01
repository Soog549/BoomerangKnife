extends Control

## Сезонный пропуск + ежедневные испытания.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vp: Vector2 = get_viewport_rect().size
	var vb := VBoxContainer.new()
	vb.position = Vector2(28, 32)
	vb.size = Vector2(vp.x - 56, vp.y - 170)
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)

	var t1 := Label.new()
	t1.text = tr("ИСПЫТАНИЯ ДНЯ")
	t1.add_theme_font_size_override("font_size", 22)
	t1.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(t1)

	for item in GameState.daily_challenges():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var lab := Label.new()
		var prog: int = GameState.daily_ch_progress(item)
		var target: int = int(item["target"])
		lab.text = "%s  (%d/%d)" % [str(item["label"]), mini(prog, target), target]
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.add_theme_font_size_override("font_size", 14)
		row.add_child(lab)
		var b := Button.new()
		var claimed: bool = bool(item["claimed"])
		b.text = tr("ПОЛУЧЕНО") if claimed else tr("ЗАБРАТЬ %d") % int(item["reward"])
		b.disabled = claimed or prog < target
		b.custom_minimum_size = Vector2(170, 44)
		b.add_theme_font_size_override("font_size", 12)
		var cid := str(item["id"])
		b.pressed.connect(func() -> void:
			if GameState.claim_daily_challenge(cid):
				AudioManager.play("level")
				get_tree().reload_current_scene())
		row.add_child(b)
		vb.add_child(row)

	var t2 := Label.new()
	t2.text = tr("СЕЗОН")
	t2.add_theme_font_size_override("font_size", 22)
	t2.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	vb.add_child(t2)

	var lv: int = GameState.season_level()
	var bar := ProgressBar.new()
	bar.max_value = float(GameState.SEASON_POINTS_PER_LEVEL)
	bar.value = float(GameState.season_points % GameState.SEASON_POINTS_PER_LEVEL)
	bar.custom_minimum_size = Vector2(0, 20)
	bar.show_percentage = false
	vb.add_child(bar)

	var info := Label.new()
	info.text = tr("Уровень сезона: %d / %d · очков: %d") % [lv, GameState.SEASON_LEVELS, GameState.season_points]
	info.add_theme_font_size_override("font_size", 15)
	vb.add_child(info)

	var claim := Button.new()
	claim.text = tr("ЗАБРАТЬ НАГРАДУ УРОВНЯ %d") % lv
	claim.custom_minimum_size = Vector2(0, 48)
	claim.disabled = GameState.season_claimed.has(lv)
	claim.pressed.connect(func() -> void:
		if GameState.season_claim_level(lv):
			AudioManager.play("level")
			get_tree().reload_current_scene())
	vb.add_child(claim)

	var note := Label.new()
	note.text = tr("Очки сезона дают испытания и бои. Награды: монеты (растут с уровнем).")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.72, 0.8, 0.92))
	vb.add_child(note)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2(28, vp.y - 96)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/profile.tscn"))
	add_child(back)
