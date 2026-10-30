extends Node
## ЕДИНЫЙ PAUSE UI: одинаковые пауза-меню во всех режимах.

const W := 720.0
const H := 1280.0


func normalize(menu: Control) -> void:
	if menu == null:
		return
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	for c in menu.get_children():
		if c is ColorRect:
			(c as ColorRect).color = Color(0.0, 0.0, 0.0, 0.72)
			(c as ColorRect).set_anchors_preset(Control.PRESET_FULL_RECT)
		elif c is VBoxContainer:
			var vb := c as VBoxContainer
			vb.process_mode = Node.PROCESS_MODE_ALWAYS
			vb.position = Vector2(W * 0.5 - 150.0, H * 0.36)
			vb.size = Vector2(300.0, 280.0)
			vb.add_theme_constant_override("separation", 12)
			for bc in vb.get_children():
				if bc is Button:
					var b := bc as Button
					b.custom_minimum_size = Vector2(300.0, 56.0)
					b.process_mode = Node.PROCESS_MODE_ALWAYS
