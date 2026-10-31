extends CanvasLayer
## Fader — мягкое появление сцены (fade-in 0.2 с) при каждом переходе.
## Универсальный переход без правки вызовов change_scene_to_file.


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var r := ColorRect.new()
	r.color = Color(0.02, 0.02, 0.05, 1.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
