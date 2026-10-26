extends Control

## Экран глифов: показывает все глифы, их статус (куплен/экипирован),
## и кнопки «экипировать/снять». Слоты растут с уровнем персонажа.

@onready var wallet_label: Label = $WalletLabel
@onready var slots_label: Label = $SlotsLabel
@onready var shards_label: Label = $ShardsLabel
@onready var rows: VBoxContainer = $Scroll/Rows

func _ready() -> void:
	AudioManager.play("click")
	_rebuild()
	GameState.economy_changed.connect(_rebuild)
	GameState.coins_changed.connect(func(t): wallet_label.text = tr("Монеты: %d • %d • %d") % [t, GameState.crystals, GameState.shards])

func _rebuild() -> void:
	wallet_label.text = tr("Монеты: %d • %d • %d") % [GameState.coins, GameState.crystals, GameState.shards]
	slots_label.text = "Слоты: занято %d из %d (уровень игрока %d)" % [
		GameState.equipped_glyphs.size(), GameState.glyph_slots(), GameState.player_level]
	shards_label.text = "Осколки: %d (победа в дуэли +%d, турнир +%d)" % [
		GameState.shards, Economy.SHARDS_PER_DUEL_WIN, Economy.SHARDS_PER_TOURNAMENT]
	for child in rows.get_children():
		child.queue_free()
	for g: Dictionary in Economy.GLYPHS:
		rows.add_child(_make_row(g))

func _make_row(g: Dictionary) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var glyph_id: String = g.id
	var owned := GameState.has_glyph(glyph_id)
	var active := GameState.glyph_active(glyph_id)
	var equipped := GameState.glyph_equipped(glyph_id)

	var glvl := GameState.glyph_level(glyph_id)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if active:
		if g.type == "T":
			label.text = tr("%s — %s  (активен, осталось %d)") % [tr(g.label), tr(g.desc), GameState.temp_glyph_runs(glyph_id)]
		else:
			label.text = tr("%s — %s  (вечный, ур. %d)") % [tr(g.label), tr(g.desc), glvl]
	else:
		label.text = tr("%s — %s  (ур. %d, %d м.)") % [tr(g.label), tr(g.desc), glvl, int(g.price)]
	box.add_child(label)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	var info := Label.new()
	info.custom_minimum_size = Vector2(90, 0)
	info.text = tr("слот") if equipped else ""
	btns.add_child(info)

	var btn := Button.new()
	if equipped:
		btn.text = tr("СНЯТЬ")
		btn.pressed.connect(func() -> void:
			GameState.unequip_glyph(glyph_id)
			AudioManager.play("click")
			_rebuild())
	elif owned:
		btn.text = tr("ЭКИПИРОВАТЬ")
		btn.pressed.connect(func() -> void:
			if GameState.equip_glyph(glyph_id):
				AudioManager.play("level")
				_rebuild()
			else:
				slots_label.text = "Нет свободных слотов! Повысь уровень игрока."
		)
	else:
		btn.text = tr("КУПИТЬ (%d м.)") % int(g.price)
		btn.pressed.connect(func() -> void:
			if GameState.purchase_glyph(glyph_id):
				AudioManager.play("level")
				_rebuild())
	btns.add_child(btn)
	if owned:
		_add_upgrade_button(btns, glyph_id, glvl)
	box.add_child(btns)
	return box

func _add_upgrade_button(row: HBoxContainer, glyph_id: String, glvl: int) -> void:
	var upg := Button.new()
	if GameState.can_upgrade_glyph(glyph_id):
		upg.text = tr("ШЛИФОВАТЬ (%d оск.)") % Economy.glyph_upgrade_cost(glvl)
		upg.pressed.connect(func() -> void:
			if GameState.upgrade_glyph(glyph_id):
				AudioManager.play("level")
				_rebuild())
	elif glvl >= Economy.GLYPH_MAX_LEVEL:
		upg.text = tr("МАКС ур.")
		upg.disabled = true
	else:
		upg.text = tr("НУЖНО %d оск.") % Economy.glyph_upgrade_cost(glvl)
		upg.disabled = true
	row.add_child(upg)

func _on_shop_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/profile.tscn")
