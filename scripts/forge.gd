extends Control
## Кузница: улучшение экипировки (+уровень за монеты). MVP.

func _ready() -> void:
	AudioManager.play("click")
	var vp: Vector2 = get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = tr("КУЗНИЦА")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 24)
	title.size = Vector2(vp.x, 40)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GameState.accent())
	add_child(title)

	var wallet := Label.new()
	wallet.text = tr("Монеты: %d") % GameState.coins
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet.position = Vector2(0, 70)
	wallet.size = Vector2(vp.x, 28)
	wallet.add_theme_font_size_override("font_size", 16)
	add_child(wallet)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16, 116)
	scroll.size = Vector2(vp.x - 32, vp.y - 236)
	add_child(scroll)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	scroll.add_child(vb)

	var any := false
	for slot in GameState.EQUIPMENT_SLOTS:
		for it in ItemsDB.build_slot(str(slot)):
			var iid := str(it["id"])
			if not (iid in GameState.owned_equipment):
				continue
			any = true
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var lvl := GameState.item_level(iid)
			var info := Label.new()
			info.text = "%s  ·  ур.%d" % [tr(str(it.get("name", iid))), lvl]
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_theme_font_size_override("font_size", 15)
			row.add_child(info)
			var b := Button.new()
			var cost := GameState.upgrade_cost(iid)
			b.text = tr("Улучшить ") + str(cost)
			b.custom_minimum_size = Vector2(180, 52)
			b.disabled = GameState.coins < cost
			var lid: String = iid
			b.pressed.connect(func() -> void:
				AudioManager.play("level")
				if GameState.upgrade_item(lid):
					Toast.show(tr("Улучшено до ур.") + str(GameState.item_level(lid)))
				get_tree().reload_current_scene())
			row.add_child(b)
			vb.add_child(row)

	if not any:
		var empty := Label.new()
		empty.text = tr("Нет предметов. Купи снаряжение в МАГАЗИНЕ.")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, 80)
		empty.add_theme_font_size_override("font_size", 15)
		vb.add_child(empty)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2((vp.x - 200) * 0.5, vp.y - 96)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/empire.tscn"))
	add_child(back)
