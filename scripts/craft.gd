extends Control
## Крафт/обмен ресурсов: осколки ↔ монеты ↔ кристаллы. MVP.

const RECIPES := [
	{"id": "sh_to_coins", "title": "3 осколка -> 100 монет", "need_shards": 3, "give_coins": 100},
	{"id": "sh_to_cryst", "title": "5 осколков -> 1 кристалл", "need_shards": 5, "give_crystals": 1},
	{"id": "coins_to_sh", "title": "150 монет -> 1 осколок", "need_coins": 150, "give_shards": 1},
	{"id": "coins_to_cryst", "title": "300 монет -> 1 кристалл", "need_coins": 300, "give_crystals": 1},
]


func _ready() -> void:
	AudioManager.play("click")
	var vp: Vector2 = get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = tr("КРАФТ")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 24)
	title.size = Vector2(vp.x, 40)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GameState.accent())
	add_child(title)

	var wallet := Label.new()
	wallet.text = tr("Монеты: %d · Кристаллы: %d · Осколки: %d") % [GameState.coins, GameState.crystals, GameState.shards]
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet.position = Vector2(0, 72)
	wallet.size = Vector2(vp.x, 28)
	wallet.add_theme_font_size_override("font_size", 15)
	add_child(wallet)

	var vb := VBoxContainer.new()
	vb.position = Vector2(24, 130)
	vb.size = Vector2(vp.x - 48, 900)
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)

	for r in RECIPES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info := Label.new()
		info.text = tr(str(r["title"]))
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 15)
		row.add_child(info)
		var can := _can(r)
		var b := Button.new()
		b.text = tr("Создать")
		b.custom_minimum_size = Vector2(160, 54)
		b.disabled = not can
		var rr: Dictionary = r
		b.pressed.connect(func() -> void:
			AudioManager.play("level")
			if _do(rr):
				Toast.show(tr("Готово"))
			get_tree().reload_current_scene())
		row.add_child(b)
		vb.add_child(row)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2((vp.x - 200) * 0.5, vp.y - 96)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/empire.tscn"))
	add_child(back)


func _can(r: Dictionary) -> bool:
	if r.has("need_shards") and GameState.shards < int(r["need_shards"]):
		return false
	if r.has("need_coins") and GameState.coins < int(r["need_coins"]):
		return false
	return true


func _do(r: Dictionary) -> bool:
	if not _can(r):
		return false
	if r.has("need_shards") and not GameState.spend_shards(int(r["need_shards"])):
		return false
	if r.has("need_coins") and not GameState.spend_coins(int(r["need_coins"])):
		return false
	if r.has("give_coins"):
		GameState.add_coins(int(r["give_coins"]))
	if r.has("give_crystals"):
		GameState.add_crystals(int(r["give_crystals"]))
	if r.has("give_shards"):
		GameState.add_shards(int(r["give_shards"]))
	return true
