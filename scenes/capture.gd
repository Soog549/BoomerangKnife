extends Node
## CAPTURE: загружает сцену, ждёт кадры, сохраняет скриншот, выходит.
## Запуск: godot --path . --rendering-driver opengl3 --resolution 720x1280 scenes/capture.tscn -- --scene=res://scenes/mob_arena.tscn --out=E:/path/shot.png

func _ready() -> void:
	var scene_path := ""
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene_path = a.substr(8)
		elif a.begins_with("--out="):
			out = a.substr(6)
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		print("CAPTURE FAIL: no scene ", scene_path)
		get_tree().quit(1)
		return
	var ps := load(scene_path) as PackedScene
	if ps == null:
		print("CAPTURE FAIL: not a scene")
		get_tree().quit(1)
		return
	var inst := ps.instantiate()
	add_child(inst)
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		print("CAPTURE FAIL: no image")
		get_tree().quit(1)
		return
	var err := img.save_png(out)
	print("CAPTURE ", "OK" if err == OK else "FAIL", " -> ", out)
	get_tree().quit(0 if err == OK else 1)
