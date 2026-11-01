extends Node

const OUT := "E:/Realese_BOOKNIFE/screenmob-visualbug/final-qa"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var ps: PackedScene = load("res://scenes/td.tscn")
	var inst: Node = ps.instantiate()
	add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.8).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + "/05-td.png")
	print("SHOT td ", img.get_width(), "x", img.get_height())
	get_tree().quit()
