extends Control

## Обрабатывает ESC. Работает даже на паузе (process_mode=ALWAYS на этом ноде).

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var game := get_tree().current_scene
		if game != null and game.has_method("_toggle_pause"):
			game.call("_toggle_pause")
