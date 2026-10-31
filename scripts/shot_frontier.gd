extends Node
## Снимок наземного режима (полноростовый риг) с автостартом раунда.

const OUT := "E:/Realese_BOOKNIFE/screenmob-visualbug/final-qa"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	GameState.frontier_mode = true
	GameState.difficulty = "hard"
	var ps: PackedScene = load("res://scenes/mob_arena.tscn")
	var inst: Node = ps.instantiate()
	add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	if inst.has_method("_start_round"):
		inst.call("_start_round")
	await get_tree().create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + "/20-frontier.png")
	print("SHOT frontier ", img.get_width(), "x", img.get_height())
	get_tree().quit()
