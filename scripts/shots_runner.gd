extends Node
## РЎРЅРёРјР°РµС‚ СЃРµСЂРёСЋ СЃРєСЂРёРЅС€РѕС‚РѕРІ РІСЃРµС… СЌРєСЂР°РЅРѕРІ Рё РІС‹С…РѕРґРёС‚.

const OUT := "E:/Realese_BOOKNIFE/screenmob-visualbug/final-qa"

const SCENES := [
	"res://scenes/main_menu.tscn",
	"res://scenes/empire.tscn",
	"res://scenes/game.tscn",
	"res://scenes/mob_arena.tscn",
	"res://scenes/td.tscn",
	"res://scenes/duel.tscn",
	"res://scenes/shop.tscn",
	"res://scenes/profile.tscn",
	"res://scenes/settings.tscn",
	"res://scenes/collection.tscn",
	"res://scenes/objectives.tscn",
	"res://scenes/worlds.tscn",
]

var _holder: Node = null


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_holder = Node.new()
	_holder.name = "Holder"
	add_child(_holder)
	_run()


func _run() -> void:
	for i in SCENES.size():
		var path: String = SCENES[i]
		var ps: PackedScene = load(path)
		if ps == null:
			print("SKIP ", path)
			continue
		for ch in _holder.get_children():
			ch.queue_free()
		await get_tree().process_frame
		var inst: Node = ps.instantiate()
		_holder.add_child(inst)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().create_timer(2.2).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var name := path.get_file().get_basename()
		var out := "%s/%02d-%s.png" % [OUT, i + 1, name]
		img.save_png(out)
		print("SHOT ", out, " ", img.get_width(), "x", img.get_height())
		await get_tree().process_frame
	print("DONE")
	get_tree().quit()
