extends Control

## Экран персонажа: аватар (текущий скин из магазина) и характеристики.
## Статы считаются из GameState на лету — меняются вместе с экипировкой.

@onready var avatar_rect: ColorRect = $Scroll/VBox/AvatarPanel/HBox/AvatarRect
@onready var type_avatar: TextureRect = $Scroll/VBox/AvatarPanel/HBox/TypeAvatar
@onready var avatar_label: Label = $Scroll/VBox/AvatarPanel/HBox/Info/AvatarLabel
@onready var stats_box: VBoxContainer = $Scroll/VBox/StatsBox
var preview_box: VBoxContainer = null

const AVATAR_TYPES := ["Мужчина", "Женщина", "Робот", "Домовой", "Осминог"]
const AVATAR_PATHS := [
	"res://assets/images/avatars/avatar_0.png",
	"res://assets/images/avatars/avatar_1.png",
	"res://assets/images/avatars/avatar_2.png",
	"res://assets/images/avatars/avatar_3.png",
	"res://assets/images/avatars/avatar_4.png",
]

func _ready() -> void:
	_fix_avatar()
	AudioManager.play("click")
	_rebuild()

func _rebuild() -> void:
	var skin: Dictionary = GameState.current_skin()
	avatar_rect.color = skin.blade
	avatar_label.text = tr("Скин: %s") % skin.label
	var av_idx := clampi(GameState.avatar, 0, AVATAR_PATHS.size() - 1)
	type_avatar.texture = load(AVATAR_PATHS[av_idx])
	_add_stat(tr("Персонаж"), tr(AVATAR_TYPES[av_idx]))

	for child in stats_box.get_children():
		child.queue_free()

	_rebuild_preview()

	var mode_names: Array[String] = []
	for m: String in GameState.selected_modes:
		mode_names.append(GameState.MODES[m].label)
	var mode_str := "—"
	if not mode_names.is_empty():
		mode_str = ", ".join(PackedStringArray(mode_names))

	_add_stat("Уровень игрока", "%d (опыт: %d/%d)" % [
		GameState.player_level, GameState.player_xp, Economy.player_xp_needed(GameState.player_level)])
	_add_stat(tr("Множитель (за ур.)"), "x%.2f" % Economy.player_score_bonus(GameState.player_level))
	_add_stat(tr("Монеты"), "%d • %d • %d" % [GameState.coins, GameState.crystals, GameState.shards])
	_add_stat(tr("Сложность"), GameState.difficulty_data().label)
	_add_stat("Жизни на старте", str(GameState.start_lives()))
	_add_stat(tr("Скорость ножа"), "x%.2f" % GameState.knife_speed_mult())
	_add_stat(tr("Множитель очков"), "x%.2f" % GameState.score_mult())
	_add_stat("Рекорд (классика)", str(GameState.high_score))
	_add_stat("Рекорд волн (эндлесс)", str(GameState.endless_best_wave))
	_add_stat(tr("Экипированные моды"), mode_str)
	_add_stat(tr("Экипированный бустер"), _armed_name())
	_add_stat(tr("Снаряжение"), _gear_summary())
	_add_stat(tr("Активные глифы"), _glyph_summary())
	_add_stat(tr("Слоты глифов"), tr("%d из %d") % [GameState.equipped_glyphs.size(), GameState.glyph_slots()])


	var boost_parts: Array[String] = []
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		boost_parts.append("%s x%d" % [b.label, GameState.booster_count(b.id)])
	_add_stat(tr("Бустеры"), ", ".join(PackedStringArray(boost_parts)) if not boost_parts.is_empty() else "—")

	var con_parts: Array[String] = []
	for c: Dictionary in Economy.CONSUMABLE_ITEMS:
		con_parts.append("%s x%d" % [c.label, GameState.consumable_count(c.id)])
	_add_stat(tr("Предметы"), ", ".join(PackedStringArray(con_parts)) if not con_parts.is_empty() else "—")

func _rebuild_preview() -> void:
	if preview_box != null and is_instance_valid(preview_box):
		preview_box.queue_free()
	preview_box = VBoxContainer.new()
	stats_box.add_child(preview_box)
	var header := Label.new()
	header.text = tr("СНАРЯЖЕНИЕ НА ТЕЛЕ")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(header)
	var av := CharacterPreview.new()
	av.avatar_texture = load(AVATAR_PATHS[clampi(GameState.avatar, 0, AVATAR_PATHS.size() - 1)])
	av.size_flags_horizontal = SIZE_SHRINK_CENTER
	preview_box.add_child(av)

func _glyph_summary() -> String:
	var parts: Array[String] = []
	for g: Dictionary in Economy.GLYPHS:
		if GameState.glyph_active(g.id):
			var lvl: int = GameState.glyph_level(g.id)
			var lvl_str := (tr(" ур.%d") % lvl) if lvl > 1 else ""
			if g.type == "T":
				parts.append("%s%s (%d)" % [g.label, lvl_str, GameState.temp_glyph_runs(g.id)])
			else:
				parts.append("%s%s" % [g.label, lvl_str])
	if parts.is_empty():
		return "—"
	return ", ".join(PackedStringArray(parts))

func _gear_summary() -> String:
	var slots: Array[String] = []
	for id in GameState.equipped_ids():
		var it := Economy.find_equipment(id)
		if not it.is_empty():
			slots.append(it.label)
	if slots.is_empty():
		return "—"
	return ", ".join(PackedStringArray(slots))

func _armed_name() -> String:
	if GameState.armed_booster == "":
		return "—"
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		if b.id == GameState.armed_booster:
			return b.label
	return GameState.armed_booster

func _add_stat(label_text: String, value: String) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(430, 0)
	lbl.text = label_text
	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(lbl)
	row.add_child(val)
	stats_box.add_child(row)

func _on_equipment_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/loadout.tscn")

func _on_inventory_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/inventory.tscn")

func _on_glyphs_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/glyphs.tscn")

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _fix_avatar() -> void:
	avatar_rect.visible = false
	type_avatar.custom_minimum_size = Vector2(110, 110)
	type_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	type_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_update_avatar_tex()
	var hb := avatar_rect.get_parent()
	if hb != null and hb.get_node_or_null("PrevBtn") == null:
		var prev := Button.new()
		prev.name = "PrevBtn"
		prev.text = "<"
		prev.custom_minimum_size = Vector2(44, 110)
		prev.pressed.connect(func() -> void: _cycle_avatar(-1))
		hb.add_child(prev)
		hb.move_child(prev, 0)
		var nxt := Button.new()
		nxt.name = "NextBtn"
		nxt.text = ">"
		nxt.custom_minimum_size = Vector2(44, 110)
		nxt.pressed.connect(func() -> void: _cycle_avatar(1))
		hb.add_child(nxt)

func _update_avatar_tex() -> void:
	var p := "res://assets/images/avatars/avatar_%d.png" % GameState.avatar
	if ResourceLoader.exists(p):
		type_avatar.texture = load(p)
	if avatar_label != null:
		avatar_label.text = tr("Аватар: #%d") % (GameState.avatar + 1)

func _cycle_avatar(d: int) -> void:
	var owned: Array = GameState.owned_avatars
	if owned.is_empty():
		owned = [0]
	var idx: int = owned.find(GameState.avatar)
	GameState.avatar = int(owned[(idx + d + owned.size()) % owned.size()])
	GameState.save_settings()
	_update_avatar_tex()
	AudioManager.play("click")
