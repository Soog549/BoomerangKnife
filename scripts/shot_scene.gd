extends Node

const OUT := "E:/Realese_BOOKNIFE/screenmob-visualbug/final-qa"
const SCENES := {
	"coll": "res://scenes/collection.tscn",
	"obj": "res://scenes/objectives.tscn",
	"shop": "res://scenes/shop.tscn",
	"prof": "res://scenes/profile.tscn",
}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var arg := "coll"
	for a in OS.get_cmdline_user_args():
		if SCENES.has(a):
			arg = a
	var ps: PackedScene = load(SCENES[arg])
	var inst: Node = ps.instantiate()
	add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + "/shot-%s.png" % arg)
	print("SHOT ", arg, " ", img.get_width(), "x", img.get_height())
	get_tree().quit()
