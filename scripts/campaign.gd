extends Control
## Кампания-РПГ: 12 эпизодов S1, каждый — «встреча» одного из режимов.

func _ready() -> void:
	AudioManager.play("click")
	var vp: Vector2 = get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = tr("КАМПАНИЯ · СЕЗОН 1 «ПАМЯТЬ»")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 20)
	title.size = Vector2(vp.x, 36)
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", GameState.accent())
	add_child(title)

	var sub := Label.new()
	sub.text = tr("Пройдено: %d из %d") % [GameState.campaign_done_count(), GameState.CAMPAIGN.size()]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 60)
	sub.size = Vector2(vp.x, 24)
	sub.add_theme_font_size_override("font_size", 14)
	add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16, 96)
	scroll.size = Vector2(vp.x - 32, vp.y - 200)
	add_child(scroll)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	scroll.add_child(vb)

	var next_idx := -1
	for i in GameState.CAMPAIGN.size():
		if GameState.campaign_unlocked(i) and i not in GameState.campaign_done:
			next_idx = i
			break
	for i in GameState.CAMPAIGN.size():
		var idx: int = i
		var e: Dictionary = GameState.CAMPAIGN[i]
		var unlocked: bool = GameState.campaign_unlocked(idx)
		var done: bool = idx in GameState.campaign_done
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var info := Label.new()
		var status := "ГОТОВО" if done else ("ЗАКРЫТО" if not unlocked else ("СЛЕДУЮЩИЙ" if idx == next_idx else ""))
		var line := "%s %s · %s" % [str(e["ep"]), tr(str(e["title"])), _mode_badge(str(e["scene"]))]
		if status != "":
			line += "  —  " + status
		info.text = line
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 15)
		info.modulate = Color(1, 1, 1, 1.0 if unlocked else 0.5)
		if idx == next_idx:
			info.add_theme_color_override("font_color", GameState.accent())
		info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(info)
		if unlocked:
			var b := Button.new()
			b.text = tr("ЕЩЁ") if done else tr("ИГРАТЬ")
			b.custom_minimum_size = Vector2(120, 46)
			b.pressed.connect(func() -> void:
				AudioManager.play("level")
				GameState.campaign_launch(idx))
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


func _mode_badge(scene: String) -> String:
	match scene:
		"res://scenes/mob_arena.tscn":
			return tr("АРЕНА")
		"res://scenes/td.tscn":
			return tr("ОБОРОНА")
		"res://scenes/rts.tscn":
			return tr("СТРАТЕГИЯ")
		"res://scenes/adventure.tscn":
			return tr("ПРИКЛЮЧЕНИЕ")
		"res://scenes/survival.tscn":
			return tr("ВЫЖИВАНИЕ")
		"res://scenes/quiz.tscn":
			return tr("ВИКТОРИНА")
		"res://scenes/locations.tscn":
			return tr("ВЫБОР")
		"res://scenes/main_menu.tscn":
			return tr("ЭПИЛОГ")
	return ""
