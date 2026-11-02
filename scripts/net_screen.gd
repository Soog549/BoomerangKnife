extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vp: Vector2 = get_viewport_rect().size
	var vb := VBoxContainer.new()
	vb.position = Vector2(32, 40)
	vb.size = Vector2(vp.x - 64, vp.y - 160)
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)

	var t := Label.new()
	t.text = "СЕТЕВАЯ ИГРА (LAN)"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(t)

	var host_b := Button.new()
	host_b.text = "СОЗДАТЬ ИГРУ (хост)"
	host_b.custom_minimum_size = Vector2(0, 54)
	host_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		NetManager.host())
	vb.add_child(host_b)

	var ip_edit := LineEdit.new()
	ip_edit.placeholder_text = "IP хоста, напр. 192.168.0.5"
	ip_edit.custom_minimum_size = Vector2(0, 50)
	vb.add_child(ip_edit)

	var join_b := Button.new()
	join_b.text = "ПОДКЛЮЧИТЬСЯ"
	join_b.custom_minimum_size = Vector2(0, 54)
	join_b.pressed.connect(func() -> void:
		AudioManager.play("click")
		NetManager.join(ip_edit.text.strip_edges()))
	vb.add_child(join_b)

	var state := Label.new()
	state.text = "Отключено"
	state.add_theme_font_size_override("font_size", 14)
	vb.add_child(state)

	var list := Label.new()
	list.add_theme_font_size_override("font_size", 14)
	vb.add_child(list)

	NetManager.connection_state.connect(func(txt: String) -> void: state.text = txt)
	NetManager.players_changed.connect(func(arr: Array) -> void:
		var names: Array = []
		for p in arr:
			names.append(str(p["name"]))
		list.text = "Игроки (%d): %s" % [arr.size(), ", ".join(PackedStringArray(names))])

	var leave_b := Button.new()
	leave_b.text = "ОТКЛЮЧИТЬСЯ"
	leave_b.custom_minimum_size = Vector2(0, 48)
	leave_b.pressed.connect(func() -> void: NetManager.leave())
	vb.add_child(leave_b)

	var back := Button.new()
	back.text = "НАЗАД"
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2(32, vp.y - 92)
	back.pressed.connect(func() -> void:
		NetManager.leave()
		get_tree().change_scene_to_file("res://scenes/settings.tscn"))
	add_child(back)
