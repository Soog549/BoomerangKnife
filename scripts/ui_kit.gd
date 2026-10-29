extends Node
## UI-КАРКАС ИМПЕРИИ: единый шаблон экранов (safe-area, переносы, компактные кнопки).

const W := 720.0
const H := 1280.0
const M := 36.0
const BTN_H := 44.0


func section(parent: Node, title: String) -> void:
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	parent.add_child(l)


func item(parent: Node, text: String, btn_text: String, cb: Callable, disabled: bool = false) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b := Button.new()
	b.text = btn_text
	b.custom_minimum_size = Vector2(130, 40)
	b.disabled = disabled
	if not disabled:
		b.pressed.connect(cb)
	h.add_child(b)
	parent.add_child(h)
	return h


func back(root: Control, scene: String) -> void:
	var b := Button.new()
	b.text = "← НАЗАД"
	b.custom_minimum_size = Vector2(200, BTN_H)
	b.position = Vector2(M, H - M - BTN_H)
	b.pressed.connect(func() -> void: get_tree().change_scene_to_file(scene))
	root.add_child(b)
