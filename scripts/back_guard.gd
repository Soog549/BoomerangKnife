extends Node
## BackGuard — перехват системной кнопки «Назад» на Android.
## В игре → пауза. В подменю → главное меню. В главном меню → ничего (не выкидывает).


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back()


func handle_back() -> void:
	var tree := get_tree()
	var sc := tree.current_scene
	if sc == null:
		return
	if sc.has_method("_toggle_pause"):
		sc.call("_toggle_pause")
		return
	var f := sc.scene_file_path.get_file()
	if f == "main_menu.tscn" or f == "splash.tscn":
		return
	tree.change_scene_to_file("res://scenes/main_menu.tscn")
