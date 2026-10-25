extends Control

## Экран инвентаря: бустеры, расходники и снаряжение.
## Бустеры/расходники показываются с количеством, снаряжение — с кнопками надеть/снять.

@onready var wallet_label: Label = $WalletLabel
@onready var rows: VBoxContainer = $Scroll/Rows
@onready var armed_label: Label = $ArmedLabel

func _ready() -> void:
	AudioManager.play("click")
	_fix_layout()
	_rebuild()
	GameState.economy_changed.connect(_rebuild)
	GameState.coins_changed.connect(func(t): wallet_label.text = tr("Монеты: %d • Кристаллы: %d") % [t, GameState.crystals])

func _fix_layout() -> void:
	var sc := get_node_or_null("Scroll")
	if sc != null:
		sc.offset_bottom = -310.0
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var hint := get_node_or_null("HintLabel")
	if hint != null:
		hint.position = Vector2(16, 926)
	var spots := {
		"ShopButton": Vector2(20, 978),
		"ClearButton": Vector2(250, 978),
		"GlyphsBtn": Vector2(480, 978),
		"BackButton": Vector2(20, 1044),
	}
	var sizes := {
		"ShopButton": Vector2(220, 56),
		"ClearButton": Vector2(220, 56),
		"GlyphsBtn": Vector2(220, 56),
		"BackButton": Vector2(680, 56),
	}
	for n in spots:
		var b := get_node_or_null(n)
		if b != null:
			b.anchor_top = 0.0
			b.anchor_bottom = 0.0
			b.anchor_left = 0.0
			b.anchor_right = 0.0
			b.position = spots[n]
			b.size = sizes[n]

func _rebuild() -> void:
	wallet_label.text = tr("Монеты: %d • Кристаллы: %d") % [GameState.coins, GameState.crystals]
	armed_label.text = tr("В лоадауте: %s") % _armed_name()
	for child in rows.get_children():
		child.queue_free()
	_build_section(tr("БУСТЕРЫ"), _booster_rows())
	_build_section(tr("ПРЕДМЕТЫ"), _consumable_rows())
	_build_section(tr("СНАРЯЖЕНИЕ"), _equipment_rows())
	_build_section(tr("ГЛИФЫ"), _glyph_rows())

func _build_section(title: String, rows_data: Array) -> void:
	if rows_data.is_empty():
		return
	var h := Label.new()
	h.text = "— %s —" % title
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(h)
	for row in rows_data:
		rows.add_child(row)

func _glyph_rows() -> Array:
	var out: Array = []
	for g: Dictionary in Economy.GLYPHS:
		var active := GameState.glyph_active(g.id)
		var row := VBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(0, 0)
		if active:
			if g.type == "T":
				label.text = tr("%s — %s  (активен, осталось %d забегов)") % [g.label, g.desc, GameState.temp_glyph_runs(g.id)]
			else:
				label.text = tr("%s — %s  (вечный)") % [g.label, g.desc]
		else:
			label.text = "%s — %s" % [tr(g.label), tr(g.desc)]
			label.modulate = Color(0.7, 0.7, 0.7, 1)
		row.add_child(label)
		var btn := Button.new()
		if active:
			btn.text = tr("АКТИВЕН ")
			btn.disabled = true
		else:
			btn.text = tr("КУПИТЬ В МАГАЗИН")
			btn.pressed.connect(func() -> void:
				AudioManager.play("click")
				get_tree().change_scene_to_file("res://scenes/shop.tscn"))
		row.add_child(btn)
		out.append(row)
	return out

func _booster_rows() -> Array:
	var out: Array = []
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		var count := GameState.booster_count(b.id)
		if count <= 0 and GameState.armed_booster != b.id:
			continue
		var row := VBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(0, 0)
		label.text = "%s — %s  (x%d)" % [tr(b.label), tr(b.desc), count]
		row.add_child(label)
		var btn := Button.new()
		if GameState.armed_booster == b.id:
			btn.text = tr("ГОТОВ ")
			btn.disabled = true
		elif count > 0:
			btn.text = tr("В ЛОАДАУТ")
			btn.pressed.connect(func() -> void:
				GameState.armed_booster = b.id
				GameState.save_settings()
				AudioManager.play("click")
				_rebuild())
		else:
			btn.text = tr("В МАГАЗИН")
			btn.pressed.connect(func() -> void:
				AudioManager.play("click")
				get_tree().change_scene_to_file("res://scenes/shop.tscn"))
		row.add_child(btn)
		out.append(row)
	return out

func _consumable_rows() -> Array:
	var out: Array = []
	for c: Dictionary in Economy.CONSUMABLE_ITEMS:
		var count := GameState.consumable_count(c.id)
		var row := VBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(0, 0)
		label.text = "%s — %s  (x%d)" % [tr(c.label), tr(c.desc), count]
		row.add_child(label)
		var btn := Button.new()
		if count > 0:
			btn.text = tr("ИСПОЛЬЗОВАТЬ")
			btn.pressed.connect(func() -> void:
				GameState.armed_booster = ""  # золотой нож не зависит от лоадаута бустеров
				GameState.save_settings()
				AudioManager.play("click"))
		else:
			btn.text = tr("КУПИТЬ ЗА КРИСТАЛЛЫ")
			btn.pressed.connect(func() -> void:
				AudioManager.play("click")
				get_tree().change_scene_to_file("res://scenes/shop.tscn"))
		row.add_child(btn)
		out.append(row)
	return out

func _equipment_rows() -> Array:
	var out: Array = []
	for it in Economy.all_equipment():
		var eq_id: String = it.id
		var owned := GameState.is_equipment_owned(eq_id)
		if not owned:
			continue
		var row := VBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(0, 0)
		if GameState.equipped_in(it.slot) == eq_id:
			label.text = "%s — %s  " % [tr(it.label), tr(it.desc)]
		else:
			label.text = "%s — %s" % [tr(it.label), tr(it.desc)]
		row.add_child(label)
		var btn := Button.new()
		if GameState.equipped_in(it.slot) == eq_id:
			btn.text = tr("СНЯТЬ")
			btn.pressed.connect(func() -> void:
				GameState.unequip_slot(it.slot)
				AudioManager.play("click")
				_rebuild())
		else:
			btn.text = tr("НАДЕТЬ")
			btn.pressed.connect(func() -> void:
				GameState.equip_item(eq_id)
				AudioManager.play("level")
				_rebuild())
		row.add_child(btn)
		out.append(row)
	return out

func _armed_name() -> String:
	if GameState.armed_booster == "":
		return tr("— (нет, экипируй в инвентаре или лоадауте)")
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		if b.id == GameState.armed_booster:
			return b.label
	return GameState.armed_booster

func _on_clear_pressed() -> void:
	GameState.armed_booster = ""
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild()

func _on_shop_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func _on_glyphs_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/glyphs.tscn")

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/profile.tscn")
