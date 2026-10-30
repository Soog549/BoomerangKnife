extends Control
## Экран инвентаря на едином UI-каркасе (компактные строки, отступы, переносы).

@onready var wallet_label: Label = $WalletLabel
@onready var rows: VBoxContainer = $Scroll/Rows
@onready var armed_label: Label = $ArmedLabel


func _ready() -> void:
	AudioManager.play("click")
	_fix_layout()
	_rebuild()
	GameState.economy_changed.connect(_rebuild)
	GameState.coins_changed.connect(func(t: int) -> void:
		wallet_label.text = tr("Монеты: %d • Кристаллы: %d") % [t, GameState.crystals])


func _fix_layout() -> void:
	var sc := get_node_or_null("Scroll")
	if sc != null:
		sc.position = Vector2(UIKit.M, 112)
		sc.size = Vector2(UIKit.W - UIKit.M * 2.0, 1030)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var hint := get_node_or_null("HintLabel")
	if hint != null:
		hint.position = Vector2(UIKit.M, 30)
	var spots := {
		"ShopButton": Vector2(UIKit.M, 1152),
		"ClearButton": Vector2(UIKit.M + 216, 1152),
		"GlyphsBtn": Vector2(UIKit.M + 432, 1152),
		"BackButton": Vector2(UIKit.M, 1204),
	}
	var sizes := {
		"ShopButton": Vector2(200, 40),
		"ClearButton": Vector2(200, 40),
		"GlyphsBtn": Vector2(200, 40),
		"BackButton": Vector2(UIKit.W - UIKit.M * 2.0, 44),
	}
	for n in spots:
		var b := get_node_or_null(n)
		if b != null:
			b.anchor_left = 0.0
			b.anchor_top = 0.0
			b.anchor_right = 0.0
			b.anchor_bottom = 0.0
			b.position = spots[n]
			b.size = sizes[n]


func _rebuild() -> void:
	wallet_label.text = tr("Монеты: %d • Кристаллы: %d") % [GameState.coins, GameState.crystals]
	armed_label.text = tr("В лоадауте: %s") % _armed_name()
	for child in rows.get_children():
		child.queue_free()
	_build_boosters()
	_build_consumables()
	_build_equipment()
	_build_glyphs()


func _build_boosters() -> void:
	var any := false
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		if GameState.booster_count(b.id) > 0:
			any = true
	if not any:
		return
	UIKit.section(rows, tr("БУСТЕРЫ"))
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		var cnt := GameState.booster_count(b.id)
		if cnt <= 0:
			continue
		var txt := "%s — %s  (x%d)" % [tr(b.label), tr(b.desc), cnt]
		UIKit.item(rows, txt, tr("В ЛОАДАУТ"), func() -> void:
			GameState.armed_booster = b.id
			GameState.save_settings()
			AudioManager.play("click")
			_rebuild())


func _build_consumables() -> void:
	var any := false
	for c: Dictionary in Economy.CONSUMABLE_ITEMS:
		if GameState.consumable_count(c.id) > 0:
			any = true
	if not any:
		return
	UIKit.section(rows, tr("ПРЕДМЕТЫ"))
	for c: Dictionary in Economy.CONSUMABLE_ITEMS:
		var cnt := GameState.consumable_count(c.id)
		if cnt <= 0:
			continue
		var txt := "%s — %s  (x%d)" % [tr(c.label), tr(c.desc), cnt]
		UIKit.item(rows, txt, tr("ИСПОЛЬЗОВАТЬ"), func() -> void:
			AudioManager.play("click"))


func _build_equipment() -> void:
	var owned_items: Array = []
	for it in Economy.all_equipment():
		if GameState.is_equipment_owned(it.id):
			owned_items.append(it)
	if owned_items.is_empty():
		UIKit.section(rows, tr("СНАРЯЖЕНИЕ"))
		UIKit.item(rows, tr("Пока пусто — загляни в магазин"), tr("МАГАЗИН"), func() -> void:
			AudioManager.play("click")
			get_tree().change_scene_to_file("res://scenes/shop.tscn"), true)
		return
	UIKit.section(rows, tr("СНАРЯЖЕНИЕ"))
	var counts := {}
	for it in owned_items:
		counts[it.slot] = int(counts.get(it.slot, 0)) + 1
	var summary := ""
	for slot in counts:
		summary += "%s: %d  " % [tr(str(slot)), counts[slot]]
	UIKit.item(rows, tr("Всего: ") + summary, "—", func() -> void: pass, true)
	for it in owned_items:
		var eq_id: String = it.id
		var equipped := GameState.equipped_in(it.slot) == eq_id
		var txt := "%s — %s" % [tr(it.label), tr(it.desc)]
		if equipped:
			UIKit.item(rows, txt, tr("СНЯТЬ"), func() -> void:
				GameState.unequip_slot(it.slot)
				AudioManager.play("click")
				_rebuild())
		else:
			UIKit.item(rows, txt, tr("НАДЕТЬ"), func() -> void:
				GameState.equip_item(eq_id)
				AudioManager.play("level")
				_rebuild())


func _build_glyphs() -> void:
	UIKit.section(rows, tr("ГЛИФЫ"))
	for g: Dictionary in Economy.GLYPHS:
		var active := GameState.glyph_active(g.id)
		var txt := "%s — %s" % [tr(g.label), tr(g.desc)]
		if active:
			txt += tr("  (активен)")
		UIKit.item(rows, txt, tr("АКТИВЕН") if active else tr("В МАГАЗИН"),
			func() -> void:
				AudioManager.play("click")
				get_tree().change_scene_to_file("res://scenes/shop.tscn"),
			active)


func _armed_name() -> String:
	if GameState.armed_booster == "":
		return tr("— (не выбран)")
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		if b.id == GameState.armed_booster:
			return str(b.label)
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
