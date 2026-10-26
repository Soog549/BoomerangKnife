extends Control

## Экран целей (509 вех) с пагинацией: 30 на страницу.

@onready var wallet_label: Label = $Wallet
@onready var items_box: VBoxContainer = $Scroll/Items

const PER := 30
var _page := 0
var _nav: HBoxContainer = null
var _page_label: Label = null


func _ready() -> void:
	AudioManager.play("click")
	_build_nav()
	_rebuild()
	GameState.stats_changed.connect(_rebuild)
	GameState.economy_changed.connect(_rebuild)
	GameState.coins_changed.connect(_on_coins)


func _build_nav() -> void:
	_nav = HBoxContainer.new()
	_nav.position = Vector2(20, 1030)
	_nav.size = Vector2(680, 56)
	_nav.add_theme_constant_override("separation", 10)
	add_child(_nav)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(90, 52)
	prev.pressed.connect(func() -> void: _change_page(-1))
	_nav.add_child(prev)
	_page_label = Label.new()
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nav.add_child(_page_label)
	var nxt := Button.new()
	nxt.text = "▶"
	nxt.custom_minimum_size = Vector2(90, 52)
	nxt.pressed.connect(func() -> void: _change_page(1))
	_nav.add_child(nxt)


func _change_page(d: int) -> void:
	var total := Objectives.all().size()
	var pages := int(ceil(float(total) / PER))
	_page = clampi(_page + d, 0, max(0, pages - 1))
	AudioManager.play("click")
	_rebuild()


func _on_coins(total: int) -> void:
	wallet_label.text = tr("Монеты: %d") % total


func _rebuild() -> void:
	for child in items_box.get_children():
		child.queue_free()
	wallet_label.text = tr("Монеты: %d") % GameState.coins
	var all := Objectives.all()
	var pages := int(ceil(float(all.size()) / PER))
	_page = clampi(_page, 0, max(0, pages - 1))
	if _page_label != null:
		_page_label.text = tr("Стр. %d / %d  ·  всего %d") % [_page + 1, pages, all.size()]
	var start := _page * PER
	var finish := mini(start + PER, all.size())
	for i in range(start, finish):
		items_box.add_child(_make_row(all[i]))


func _make_row(obj: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	var prog := Objectives.progress(obj)
	var done := Objectives.is_done(obj)
	var claimed := Objectives.is_claimed(obj)

	var label := Label.new()
	label.custom_minimum_size = Vector2(400, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		btn.text = tr("ЗАБРАТЬ +%d") % obj.reward
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
	Telemetry.event("objective_claim", {"id": obj.id})
	_rebuild()


func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
