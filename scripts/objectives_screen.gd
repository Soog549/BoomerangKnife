extends Control

## Экран целей: показывает прогресс, выдаёт монеты за выполнение.

@onready var wallet_label: Label = $Wallet
@onready var items_box: VBoxContainer = $Scroll/Items

func _ready() -> void:
	AudioManager.play("click")
	_rebuild()
	GameState.stats_changed.connect(_rebuild)
	GameState.economy_changed.connect(_rebuild)
	GameState.coins_changed.connect(_on_coins)

func _on_coins(total: int) -> void:
	wallet_label.text = tr("Монеты: %d") % total

func _rebuild() -> void:
	for child in items_box.get_children():
		child.queue_free()
	wallet_label.text = tr("Монеты: %d") % GameState.coins
	for obj: Dictionary in Objectives.LIST:
		items_box.add_child(_make_row(obj))

func _make_row(obj: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	var prog := Objectives.progress(obj)
	var done := Objectives.is_done(obj)
	var claimed := Objectives.is_claimed(obj)

	var label := Label.new()
	label.custom_minimum_size = Vector2(420, 0)
	if claimed:
		label.text = tr("%s   (забрано)") % obj.label
	elif done:
		label.text = tr("%s — готово!") % obj.label
	else:
		label.text = "%s  (%d/%d)" % [tr(obj.label), prog, obj.target]
	row.add_child(label)

	var btn := Button.new()
	if claimed:
		btn.text = tr("ГОТОВО")
		btn.disabled = true
	elif done:
		btn.text = tr("ЗАБРАТЬ +%d монет") % obj.reward
		btn.pressed.connect(func(): _claim(obj))
	else:
		btn.text = tr("В ПРОЦЕССЕ")
		btn.disabled = true
	row.add_child(btn)
	return row

func _claim(obj: Dictionary) -> void:
	GameState.claim_objective(obj.id)
	GameState.add_coins(obj.reward)
	AudioManager.play("level")
	_rebuild()

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
