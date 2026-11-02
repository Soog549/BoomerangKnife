extends Control

## Экран персонажа: аватар (текущий скин из магазина) и характеристики.
## Статы считаются из GameState на лету — меняются вместе с экипировкой.

@onready var avatar_rect: ColorRect = $Scroll/VBox/AvatarPanel/HBox/AvatarRect
@onready var type_avatar: TextureRect = $Scroll/VBox/AvatarPanel/HBox/TypeAvatar
@onready var avatar_label: Label = $Scroll/VBox/AvatarPanel/HBox/Info/AvatarLabel
@onready var stats_box: VBoxContainer = $Scroll/VBox/StatsBox
var preview_box: VBoxContainer = null
var _tier := 2  # 0 голова, 1 бюст, 2 тело

const CLASS_FILES := ["warrior", "rogue", "mage", "archer", "knight", "berserker", "assassin", "paladin", "druid", "monk", "pirate", "samurai", "ninja", "viking", "gunslinger", "alchemist", "necromancer", "engineer", "bounty_hunter", "shaman", "champion", "princess", "fist", "kinetic", "pyro", "cryo", "psion", "telekinetic", "kimaster", "aurate", "graviton", "symbiote", "empath"]

const AVATAR_TYPES := ["Воин", "Разбойник", "Маг", "Лучник", "Рыцарь", "Берсерк", "Ассасин", "Паладин", "Друид", "Монах", "Пират", "Самурай", "Ниндзя", "Викинг", "Стрелок", "Алхимик", "Некромант", "Инженер", "Охотник", "Шаман", "Чемпион", "Принцесса", "Кулачный",
	"Кинетик",
	"Пиромант",
	"Криомант",
	"Псайкер",
	"Телекинетик",
	"Мастер КИ",
	"Аурат",
	"Гравитоник",
	"Симбиот",
	"Эмпат"]
const AVATAR_PATHS := [
	"res://assets/images/avatars/avatar_0.png",
	"res://assets/images/avatars/avatar_1.png",
	"res://assets/images/avatars/avatar_2.png",
	"res://assets/images/avatars/avatar_3.png",
	"res://assets/images/avatars/avatar_4.png",
	"res://assets/images/avatars/avatar_5.png",
	"res://assets/images/avatars/avatar_6.png",
	"res://assets/images/avatars/avatar_7.png",
	"res://assets/images/avatars/avatar_8.png",
	"res://assets/images/avatars/avatar_9.png",
	"res://assets/images/avatars/avatar_10.png",
	"res://assets/images/avatars/avatar_11.png",
	"res://assets/images/avatars/avatar_12.png",
	"res://assets/images/avatars/avatar_13.png",
	"res://assets/images/avatars/avatar_14.png",
	"res://assets/images/avatars/avatar_15.png",
	"res://assets/images/avatars/avatar_16.png",
	"res://assets/images/avatars/avatar_17.png",
	"res://assets/images/avatars/avatar_18.png",
	"res://assets/images/avatars/avatar_19.png",
	"res://assets/images/avatars/avatar_20.png",
	"res://assets/images/avatars/avatar_21.png",
]

func _ready() -> void:
	UIKit.normalize(self)
	_fix_avatar()
	AudioManager.play("click")
	_rebuild()

func _rebuild() -> void:
	var skin: Dictionary = GameState.current_skin()
	avatar_rect.color = skin.blade
	avatar_label.text = ""
	var av_idx := clampi(GameState.avatar, 0, AVATAR_PATHS.size() - 1)
	type_avatar.texture = load(AVATAR_PATHS[av_idx])
	_add_stat(tr("Персонаж"), tr(AVATAR_TYPES[av_idx]))
	_add_stat(tr("Скин"), str(skin.label))

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
	_add_equipment_strip()
	_add_runs()
	_add_companions()
	_add_upgrade_hint()
	_add_identity()
	_add_nav_tabs()
	_add_title_and_frame()
	_add_clans_button()


func _rebuild_preview() -> void:
	if preview_box != null and is_instance_valid(preview_box):
		preview_box.queue_free()
	preview_box = VBoxContainer.new()
	stats_box.add_child(preview_box)
	var header := Label.new()
	header.text = tr("СНАРЯЖЕНИЕ НА ТЕЛЕ")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(header)
	var tier_row := HBoxContainer.new()
	tier_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tier_row.add_theme_constant_override("separation", 8)
	var names := ["ГОЛОВА", "БЮСТ", "ТЕЛО"]
	for i in 3:
		var b := Button.new()
		b.text = tr(names[i])
		b.custom_minimum_size = Vector2(150, 44)
		b.disabled = i == _tier
		b.pressed.connect(func() -> void:
			_tier = i
			AudioManager.play("click")
			_rebuild_preview())
		tier_row.add_child(b)
	preview_box.add_child(tier_row)

	# ART_BODY — для «ТЕЛО» показываем полноростовой арт класса + иконки надетого
	if _tier == 2:
		var ci2: int = clampi(GameState.avatar, 0, CLASS_FILES.size() - 1)
		var ap := "res://assets/images/classes_full/%s.png" % CLASS_FILES[ci2]
		if not ResourceLoader.exists(ap):
			ap = "res://assets/images/classes/%s.png" % CLASS_FILES[ci2]
		if ResourceLoader.exists(ap):
			var art := TextureRect.new()
			art.texture = load(ap)
			art.custom_minimum_size = Vector2(240, 360)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			preview_box.add_child(art)
			var erow := HBoxContainer.new()
			erow.alignment = BoxContainer.ALIGNMENT_CENTER
			erow.add_theme_constant_override("separation", 6)
			for slot in GameState.EQUIPMENT_SLOTS:
				var eid: String = GameState.equipped_in(str(slot))
				if eid == "":
					continue
				var it: Dictionary = ItemsDB.find_item(str(slot), eid)
				if it.is_empty():
					continue
				var q: int = int(it.get("quality", 0)) + 1
				var ip := "res://assets/images/equipment/%s_q%d.png" % [str(slot), q]
				if ResourceLoader.exists(ip):
					var t2 := TextureRect.new()
					t2.texture = load(ip)
					t2.custom_minimum_size = Vector2(48, 48)
					t2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					t2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					erow.add_child(t2)
			preview_box.add_child(erow)
			return


	var av := CharacterPreview.new()
	var tier_names := ["warrior-head.png", "warrior-bust.png", "warrior-body.png"]
	var tp := "res://assets/images/tiers/%s" % tier_names[_tier]
	var ci: int = clampi(GameState.avatar, 0, CLASS_FILES.size() - 1)
	var cp := "res://assets/images/classes_full/%s.png" % CLASS_FILES[ci]
	if not ResourceLoader.exists(cp):
		cp = "res://assets/images/classes/%s.png" % CLASS_FILES[ci]
	if _tier == 2 and ResourceLoader.exists(cp):
		tp = cp
	var full := "res://assets/images/packs/%s/hero-front.png" % GameState.style_pack
	if ResourceLoader.exists(tp):
		av.avatar_texture = load(tp)
	elif ResourceLoader.exists(full):
		av.avatar_texture = load(full)
	else:
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
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(250, 0)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.text = label_text
	var val := Label.new()
	val.text = value
	val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


func _add_equipment_strip() -> void:
	var head := Label.new()
	head.text = tr("ЭКИПИРОВКА")
	head.add_theme_font_size_override("font_size", 15)
	head.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	stats_box.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for slot in ItemsDB.SLOTS:
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(104, 0)
		var eid: String = GameState.equipped_in(str(slot))
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(56, 56)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var title := "—"
		if eid != "":
			var it: Dictionary = ItemsDB.find_item(str(slot), eid)
			if not it.is_empty():
				var q: int = int(it.get("quality", 0)) + 1
				var ip := "res://assets/images/equipment/%s_q%d.png" % [str(slot), q]
				if ResourceLoader.exists(ip):
					tex.texture = load(ip)
				title = str(it.get("name", "—"))
		col.add_child(tex)
		var l := Label.new()
		l.text = title
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 11)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		row.add_child(col)
	stats_box.add_child(row)


var _log_filter := ""


func _add_runs() -> void:
	var runs: Array = []
	for r in GameState.recent_runs:
		if _log_filter == "" or str(r.get("mode", "")) == _log_filter:
			runs.append(r)
	if runs.is_empty() and GameState.recent_runs.is_empty():
		return
	var fbtn := Button.new()
	fbtn.text = tr("ФИЛЬТР: %s") % (tr("ВСЕ") if _log_filter == "" else GameState.mode_label(_log_filter))
	fbtn.custom_minimum_size = Vector2(0, 40)
	fbtn.add_theme_font_size_override("font_size", 13)
	fbtn.pressed.connect(func() -> void:
		var modes := ["", "arena", "frontier", "rush", "survival", "campaign", "td"]
		var i := modes.find(_log_filter)
		_log_filter = str(modes[(i + 1) % modes.size()])
		_rebuild())
	stats_box.add_child(fbtn)
	var head := Label.new()
	head.text = tr("ПОСЛЕДНИЕ ЗАБЕГИ")
	head.add_theme_font_size_override("font_size", 15)
	head.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	stats_box.add_child(head)
	var top := runs.duplicate()
	top.sort_custom(func(a, b) -> bool: return int(a.get("score", 0)) > int(b.get("score", 0)))
	var top_head := Label.new()
	top_head.text = tr("ТОП-5 ЗАБЕГОВ")
	top_head.add_theme_font_size_override("font_size", 14)
	top_head.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	stats_box.add_child(top_head)
	for i in mini(5, top.size()):
		var tr2 := Label.new()
		var rr: Dictionary = top[i]
		tr2.text = "%d. %s · %s %d · %s %d" % [
			i + 1, GameState.mode_label(str(rr.get("mode", ""))),
			tr("волна"), int(rr.get("wave", 0)), tr("счёт"), int(rr.get("score", 0))]
		tr2.add_theme_font_size_override("font_size", 13)
		tr2.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55) if i == 0 else Color(0.82, 0.88, 0.96))
		stats_box.add_child(tr2)
	for r in runs:
		if not (r is Dictionary):
			continue
		var line := Label.new()
		var ts: int = int(r.get("ts", 0))
		var dt := Time.get_datetime_dict_from_unix_time(ts) if ts > 0 else {}
		var when := ""
		if not dt.is_empty():
			when = "%02d.%02d %02d:%02d" % [int(dt["day"]), int(dt["month"]), int(dt["hour"]), int(dt["minute"])]
		line.text = "%s · %s %d · %s %d%s" % [
			GameState.mode_label(str(r.get("mode", ""))),
			tr("волна"), int(r.get("wave", 0)),
			tr("счёт"), int(r.get("score", 0)),
			("  ·  " + when) if when != "" else ""]
		line.add_theme_font_size_override("font_size", 13)
		line.add_theme_color_override("font_color", Color(0.8, 0.86, 0.95))
		stats_box.add_child(line)


func _add_clans_button() -> void:
	var b := Button.new()
	b.text = tr("КЛАНЫ И ДРУЗЬЯ · ВЕДУТСЯ РАБОТЫ")
	b.custom_minimum_size = Vector2(0, 46)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	b.pressed.connect(func() -> void:
		AudioManager.play("click")
		var dlg := AcceptDialog.new()
		dlg.title = tr("КЛАНЫ И ДРУЗЬЯ")
		dlg.dialog_text = tr("Раздел в разработке: кланы, друзья и совместные рейды появятся в одном из обновлений.")
		dlg.ok_button_text = tr("ПОНЯТНО")
		add_child(dlg)
		dlg.popup_centered())
	stats_box.add_child(b)
	var pr := Button.new()
	pr.text = tr("СЕЗОН И ИСПЫТАНИЯ")
	pr.custom_minimum_size = Vector2(0, 48)
	pr.add_theme_font_size_override("font_size", 15)
	pr.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/progress.tscn"))
	stats_box.add_child(pr)


func _title_for_level() -> String:
	var lv: int = GameState.player_level
	if lv >= 30:
		return "ИМПЕРАТОР"
	if lv >= 22:
		return "ЛЕГАТ"
	if lv >= 16:
		return "ЦЕНТУРИОН"
	if lv >= 10:
		return "ВЕТЕРАН"
	if lv >= 5:
		return "ЛЕГИОНЕР"
	if lv >= 2:
		return "СТРАЖНИК"
	return "НОВИЧОК"


func _frame_color() -> Color:
	var lv: int = GameState.player_level
	if lv >= 30:
		return Color(1.0, 0.84, 0.35)
	if lv >= 22:
		return Color(0.85, 0.55, 1.0)
	if lv >= 16:
		return Color(0.45, 0.7, 1.0)
	if lv >= 10:
		return Color(0.5, 0.95, 0.75)
	return Color(0.75, 0.75, 0.8)


func _add_title_and_frame() -> void:
	var head := Label.new()
	head.text = tr("ТИТУЛ: %s") % tr(_title_for_level())
	head.add_theme_font_size_override("font_size", 16)
	head.add_theme_color_override("font_color", _frame_color())
	stats_box.add_child(head)

	var av := get_node_or_null("AvatarPreview")
	if av == null:
		av = find_child("CharacterPreview", true, false)
	if av is Control:
		var c := av as Control
		var frame := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = _frame_color()
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(12)
		frame.add_theme_stylebox_override("panel", sb)
		frame.position = c.position - Vector2(6, 6)
		frame.size = c.size + Vector2(12, 12)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.get_parent().add_child(frame)
		c.get_parent().move_child(frame, c.get_index())


func _add_identity() -> void:
	var pid: String = GameState.ensure_player_id()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var idl := Label.new()
	idl.text = "ID: %s" % pid
	idl.add_theme_font_size_override("font_size", 15)
	idl.add_theme_color_override("font_color", Color(0.75, 0.86, 1.0))
	idl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(idl)
	var copy_b := Button.new()
	copy_b.text = tr("КОПИРОВАТЬ")
	copy_b.custom_minimum_size = Vector2(150, 40)
	copy_b.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(pid)
		AudioManager.play("click")
		Toast.show(tr("ID скопирован")))
	row.add_child(copy_b)
	stats_box.add_child(row)

	var st := Label.new()
	st.text = tr("СТАТИСТИКА: волн %d · уровней %d · боссов %d · покупок %d") % [
		GameState.track_value("arena_waves"), GameState.track_value("campaign_levels"),
		GameState.track_value("boss_kills"), GameState.track_value("shop_buys")]
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.add_theme_font_size_override("font_size", 13)
	st.add_theme_color_override("font_color", Color(0.82, 0.88, 0.96))
	stats_box.add_child(st)

	var rec := Label.new()
	rec.text = tr("РЕКОРДЫ: счёт %d · раш %d · выживание %d") % [
		GameState.high_score, GameState.best_rush_waves, GameState.best_survival_waves]
	rec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rec.add_theme_font_size_override("font_size", 13)
	rec.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	stats_box.add_child(rec)

	var share := Button.new()
	share.text = tr("ПОДЕЛИТЬСЯ РЕЗУЛЬТАТОМ")
	share.custom_minimum_size = Vector2(0, 46)
	share.pressed.connect(func() -> void:
		var txt := "BoomerangKnife · ID %s · ур.%d · счёт %d · раш %d · выживание %d" % [
			pid, GameState.player_level, GameState.high_score,
			GameState.best_rush_waves, GameState.best_survival_waves]
		DisplayServer.clipboard_set(txt)
		AudioManager.play("level")
		Toast.show(tr("Результат скопирован — вставь в соцсети")))
	stats_box.add_child(share)
	var cb := Label.new()
	cb.text = tr("Боёв за класс: %d") % int(GameState.class_battles.get(str(GameState.avatar), 0))
	cb.add_theme_font_size_override("font_size", 13)
	cb.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	stats_box.add_child(cb)
	var cw := Label.new()
	cw.text = tr("Побед за класс: %d") % int(GameState.class_wins.get(str(GameState.avatar), 0))
	cw.add_theme_font_size_override("font_size", 13)
	cw.add_theme_color_override("font_color", Color(0.7, 0.95, 0.8))
	stats_box.add_child(cw)


func _add_upgrade_hint() -> void:
	var best_slot := ""
	var best_gain := 0.0
	for slot in GameState.EQUIPMENT_SLOTS:
		var eq_id: String = GameState.equipped_in(str(slot))
		var cur := 0.0
		if eq_id != "":
			var ci: Dictionary = ItemsDB.find_item(str(slot), eq_id)
			if not ci.is_empty():
				cur = GameState.item_score(ci) * (1.0 + 0.08 * float(GameState.item_level(eq_id)))
		for it in ItemsDB.build_slot(str(slot)):
			if not GameState.is_equipment_owned(str(it["id"])):
				continue
			var sc: float = GameState.item_score(it) * (1.0 + 0.08 * float(GameState.item_level(str(it["id"]))))
			if sc - cur > best_gain:
				best_gain = sc - cur
				best_slot = str(slot)
	if best_slot == "":
		return
	var l := Label.new()
	l.text = tr("Совет: надень лучший предмет в слоте «%s»") % tr(best_slot)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	stats_box.add_child(l)


func _add_nav_tabs() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var bar := HBoxContainer.new()
	bar.name = "HeroTabs"
	bar.add_theme_constant_override("separation", 4)
	bar.position = Vector2(16, 92)
	bar.size = Vector2(vp.x - 32, 52)
	add_child(bar)
	var tabs := [
		["ЭКИПИРОВКА", "res://scenes/inventory.tscn"],
		["ГЛИФЫ", "res://scenes/glyphs.tscn"],
		["ДОСТИЖЕНИЯ", "res://scenes/achievements_screen.tscn"],
		["СТАТЫ", "res://scenes/class_stats.tscn"],
	]
	for it in tabs:
		var b := Button.new()
		b.text = tr(str(it[0]))
		b.custom_minimum_size = Vector2(0, 48)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 11)
		var path: String = str(it[1])
		if ResourceLoader.exists(path):
			b.pressed.connect(func() -> void:
				AudioManager.play("click")
				GameState.last_hero_scene = path
				get_tree().change_scene_to_file(path))
		else:
			b.disabled = true
		bar.add_child(b)


func _add_companions() -> void:
	var head := Label.new()
	head.text = tr("КОМПАНЬОНЫ")
	head.add_theme_font_size_override("font_size", 15)
	head.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	stats_box.add_child(head)
	var defs := [
		[1, "Скит", "15 урона каждые 1.6 с · за прохождение 1-й локации"],
		[2, "Аврора", "бьёт врагов и открывает ветку заданий · за квест кузнеца"],
		[3, "Тень", "замедляет врагов на 45% в радиусе 220 · 25 кристаллов"],
	]
	for d in defs:
		var id: int = int(d[0])
		var have: bool = GameState.companion_id >= id
		var l := Label.new()
		l.text = "%s %s — %s" % ["✔" if have else "–", str(d[1]), str(d[2])]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color",
			Color(0.6, 0.95, 0.7) if have else Color(0.72, 0.78, 0.88))
		stats_box.add_child(l)
