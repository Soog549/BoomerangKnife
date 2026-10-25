class_name LorePopup
extends CanvasLayer

## Всплывающая вставка-лор мира (см. LORE-WORLDS.md). Строится в коде,
## не блокирует игру: кнопка «В путь» закрывает и эмитит closed.

signal closed


func show_world(i: int) -> void:
	if i < 0 or i >= Worlds.LIST.size():
		queue_free()
		return
	var w: Dictionary = Worlds.LIST[i]

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.06, 0.15, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(560, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var art_path := "res://assets/images/worlds/%s.png" % str(w["art"])
	if ResourceLoader.exists(art_path):
		var tr := TextureRect.new()
		tr.texture = load(art_path) as Texture2D
		tr.custom_minimum_size = Vector2(560, 360)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(tr)
	else:
		var pad := Control.new()
		pad.custom_minimum_size = Vector2(0, 24)
		box.add_child(pad)

	var title := Label.new()
	title.text = str(w["name"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)

	var body := Label.new()
	body.text = str(w["lore"])
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(body)

	var btn := Button.new()
	btn.text = "В путь"
	btn.custom_minimum_size = Vector2(0, 56)
	btn.pressed.connect(_on_go)
	box.add_child(btn)


func _on_go()-> void:
	AudioManager.play("click")
	closed.emit()
	queue_free()
