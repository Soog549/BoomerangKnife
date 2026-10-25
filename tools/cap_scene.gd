extends SceneTree
## cap_scene.gd — снимок кадра изнутри Godot (probe): грузит сцену, ждёт N кадров, сохраняет PNG.
## Запуск: godot --path BK -s res://tools/cap_scene.gd
## env: BK_CAP_SCENE (сцена), BK_CAP_OUT (путь), BK_CAP_WAIT (кадров, по умолч. 40)

var _frames := 0
var _wait := 40
var _out := ""

func _initialize -> void:
	var scene := OS.get_environment("BK_CAP_SCENE")
	if scene == "":
		scene = "res://scenes/worlds.tscn"
	_out = OS.get_environment("BK_CAP_OUT")
	if _out == "":
		_out = "user://cap.png"
	var w := OS.get_environment("BK_CAP_WAIT")
	if w != "":
		_wait = int(w)
	var err := change_scene_to_file(scene)
	print("CAP: scene=", scene, " err=", err, " wait=", _wait)
	process_frame.connect(_on_frame)

func _on_frame -> void:
	_frames += 1
	if _frames < _wait:
		return
	var gpath := _out
	if gpath.begins_with("user://") or gpath.begins_with("res://"):
		gpath = ProjectSettings.globalize_path(gpath)
	var img := root.get_texture.get_image
	img.save_png(gpath)
	print("CAP: saved ", gpath, " size=", img.get_width, "x", img.get_height)
	quit
