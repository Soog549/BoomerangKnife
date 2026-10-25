extends Control

## Экран «Миры»: карта 8 миров, прогресс по GameState.max_level_reached.
## См. LORE-WORLDS.md. Строит UI в коде поверх фоновой текстуры.

func _ready()-> void:
	AudioManager.play_music("menu")
	GameState.apply_orientation()
	_build()


func _build()-> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 40.0
	vbox.offset_right = -40.0
	vbox.offset_top = 40.0
	vbox.offset_bottom = -40.0
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	var title := Label.new()
	title.text = " МИРЫ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	var cur := Worlds.current_index()
	for i in range(Worlds.LIST.size()):
		var w: Dictionary = Worlds.LIST[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 54)
		if Worlds.is_unlocked(i):
			var mark := "" if i == cur else ("" if i < cur else "")
			b.text = "%s %s" % [mark, str(w["name"])]
			b.pressed.connect(_on_world.bind(i))
		else:
			b.text = " %s — ур. %d" % [str(w["name"]), int(w["unlock"])]
			b.disabled = true
		vbox.add_child(b)

	var ni := Worlds.next_index()
	if ni >= 0:
		var hint := Label.new()
		hint.text = "Следующий мир: %s — ещё %d ур." % [str(Worlds.LIST[ni]["name"]), Worlds.levels_to(ni)]
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 18)
		vbox.add_child(hint)

	var back := Button.new()
	back.text = " НАЗАД"
	back.custom_minimum_size = Vector2(0, 54)
	back.pressed.connect(_on_back)
	vbox.add_child(back)


func _on_world(i: int) -> void:
	AudioManager.play("click")
	var pop := LorePopup.new()
	add_child(pop)
	pop.show_world(i)


func _on_back()-> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
