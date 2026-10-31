extends Control

## Экран вызова на дуэль: генерирует случайную экипировку и смысл вызова,
## соперник может принять или отклонить.

@onready var challenge_label: Label = $Center/Panel/VBox/ChallengeLabel
@onready var rules_label: Label = $Center/Panel/VBox/RulesLabel

func _ready() -> void:
	_apply_bg()
	var _hb := get_node_or_null("UI/HomeButton")
	if _hb != null:
		_hb.visible = false
	AudioManager.play("click")
	var train_btn := Button.new()
	train_btn.text = tr("ТРЕНИРОВКА (СОЛО)")
	train_btn.pressed.connect(_on_train)
	var mob_btn := Button.new()
	mob_btn.text = tr("ПРОТИВ МОБА")
	mob_btn.pressed.connect(_on_mob)
	var row := get_node_or_null("Center/Panel/VBox/BtnRow")
	if row != null:
		row.add_child(train_btn)
		row.add_child(mob_btn)
	# Случайный соперник и его сообщение
	var rivals := [tr("Богатырь"), tr("Медведь"), tr("Космонавт"), tr("Шаман"), tr("Разбойник"), tr("Атаман")]
	var rival: String = rivals[randi() % rivals.size()]
	challenge_label.text = tr("%s бросает тебе вызов!") % rival

func _on_train() -> void:
	AudioManager.play("click")
	GameState.duel_config = {"variant": "solo", "rounds": 3, "segments": 5, "speed": 1.0}
	GameState.save_settings()
	get_tree().change_scene_to_file("res://scenes/duel_arena.tscn")

func _on_mob() -> void:
	AudioManager.play("click")
	var lvl := clampi(GameState.player_level, 1, 3)
	GameState.duel_config = {"variant": "mob", "mob_level": lvl, "rounds": 3, "segments": 5, "speed": 1.0}
	GameState.save_settings()
	get_tree().change_scene_to_file("res://scenes/duel_arena.tscn")




func _accept(variant: String) -> void:
	AudioManager.play("click")
	# Генерируем случайный характер дуэли (одинаковый для обоих)
	var skin_i := randi() % GameState.SKINS.size()
	var segs := randi_range(4, 7)
	var speed := 0.9 + randf() * 0.6
	GameState.forced_skin = skin_i
	GameState.duel_config = {
		"segments": segs,
		"speed": speed,
		"golden": true,
		"moving": randf() > 0.5,
		"rounds": 3,
		"variant": variant,
	}
	GameState.save_settings()
	get_tree().change_scene_to_file("res://scenes/duel_arena.tscn")

func _on_decline() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_back() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _apply_bg() -> void:
	var bg := get_node_or_null("Background")
	var p := "res://assets/images/packs/%s/bg.jpg" % GameState.style_pack
	if bg == null or not ResourceLoader.exists(p):
		return
	var tex := TextureRect.new()
	tex.texture = load(p)
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.modulate = Color(1, 1, 1, 0.55)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(tex)
