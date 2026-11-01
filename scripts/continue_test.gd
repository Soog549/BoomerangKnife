extends Node


func _ready() -> void:
	GameState.continue_mode = "campaign"
	GameState.mode_save("campaign", {"level": 1, "score": 5, "lives": 3})
	GameState.save_settings()
	await get_tree().process_frame
	var ps: PackedScene = load("res://scenes/game.tscn")
	var inst: Node = ps.instantiate()
	add_child(inst)
	await get_tree().create_timer(2.0).timeout
	print("CONTINUE_TEST ok level=", GameState.mode_load("campaign").get("level", -1))
	get_tree().quit()
