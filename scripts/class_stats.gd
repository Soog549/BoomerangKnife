extends Control

## Статистика по классам: бои и победы.


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
	vb.add_theme_constant_override("separation", 8)
	sc.add_child(vb)

	var title := Label.new()
	title.text = tr("СТАТИСТИКА КЛАССОВ")
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(title)

	var types: Array = load("res://scripts/profile.gd").AVATAR_TYPES
	for i in types.size():
		var battles: int = int(GameState.class_battles.get(str(i), 0))
		var wins: int = int(GameState.class_wins.get(str(i), 0))
		var l := Label.new()
		l.text = "%s — %s %d · %s %d" % [str(types[i]), tr("боёв"), battles, tr("побед"), wins]
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color",
			GameState.ui_fg_color() if battles > 0 else Color(0.6, 0.65, 0.75))
		vb.add_child(l)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2(28, vp.y - 96)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/profile.tscn"))
	add_child(back)
