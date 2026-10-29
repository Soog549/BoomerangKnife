extends Control

## Магазин: скины и моды.
## Каждый предмет либо открывается при достижении уровня, либо покупается за монеты.
## Монеты добываются за геймплей, цели и просмотр рекламы (+50 монет за ролик).

@onready var info_label: Label = $InfoLabel
@onready var wallet_label: Label = $WalletLabel
@onready var items_box: VBoxContainer = $Scroll/Items
@onready var earn_btn: Button = $EarnButton
@onready var crystal_earn_btn: Button = $CrystalEarnButton

func _ready() -> void:
	UIKit.normalize(self)
	AudioManager.play("click")
	_fix_layout()
	if GameState.claim_vip_daily():
		pass  # бонус зашёл через add_crystals; достаточного фидбека ниже
	_rebuild()
	GameState.economy_changed.connect(_rebuild)
	GameState.coins_changed.connect(_on_coins)

func _fix_layout() -> void:
	info_label.offset_top = 58.0
	info_label.offset_bottom = 122.0
	info_label.add_theme_font_size_override("font_size", 15)
	wallet_label.offset_top = 126.0
	wallet_label.offset_bottom = 152.0
	earn_btn.offset_top = 156.0
	earn_btn.offset_bottom = 196.0
	earn_btn.offset_left = 80.0
	earn_btn.offset_right = -80.0
	crystal_earn_btn.offset_top = 200.0
	crystal_earn_btn.offset_bottom = 236.0
	crystal_earn_btn.offset_left = 80.0
	crystal_earn_btn.offset_right = -80.0
	var sc := get_node_or_null("Scroll")
	if sc:
		sc.offset_top = 248.0
		sc.offset_left = 80.0
		sc.offset_right = -80.0

func _on_coins(total: int) -> void:
	wallet_label.text = tr("Монеты: %d • %d • %d") % [total, GameState.crystals, GameState.shards]

func _rebuild() -> void:
	for child in items_box.get_children():
		child.queue_free()
	# Единый предпросмотр персонажа (полное тело, как в профиле)
	var pv := TextureRect.new()
	var cls_idx: int = clampi(GameState.avatar, 0, CLASS_WPN.size() - 1) if CLASS_WPN.size() > 0 else 0
	var cp := "res://assets/images/classes/%s.png" % str(CLASS_WPN[cls_idx][0])
	var hp := "res://assets/images/packs/%s/hero-front.png" % GameState.style_pack
	if ResourceLoader.exists(cp):
		pv.texture = load(cp)
	elif ResourceLoader.exists(hp):
		pv.texture = load(hp)
	pv.custom_minimum_size = Vector2(0, 170)
	pv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	items_box.add_child(pv)
	var pv_cap := Label.new()
	pv_cap.text = tr("ТЕКУЩИЙ ОБРАЗ · %s") % GameState.style_pack.to_upper()
	pv_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv_cap.add_theme_font_size_override("font_size", 15)
	items_box.add_child(pv_cap)
	_build_class_weapons()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.text = tr("Твой максимальный уровень: %d — проходи уровни, открывай цели или смотри рекламу за монеты:") % GameState.max_level_reached
	wallet_label.text = tr("Монеты: %d • %d • %d") % [GameState.coins, GameState.crystals, GameState.shards]
	var left := GameState.coin_ads_left()
	if left > 0:
		earn_btn.text = tr("Смотреть рекламу (+%d монет) — осталось %d") % [Economy.AD_REWARD_COINS, left]
	else:
		earn_btn.text = tr("Реклама исчерпана (завтра)")
		earn_btn.disabled = true
	var cleft := GameState.crystal_ads_left()
	if cleft > 0:
		crystal_earn_btn.text = tr("Реклама за кристаллы (+%d) — осталось %d") % [Economy.CRYSTALS_PER_AD, cleft]
	else:
		crystal_earn_btn.text = tr("Кристаллы: лимит на сегодня")
		crystal_earn_btn.disabled = true
	_build_iap()
	_build_crystal_ad_packs()
	_build_skins()
	_build_sets()
	_build_avatars()
	_build_modes()
	_build_boosters()
	_build_consumables()
	_build_equipment()
	_build_glyphs()

func _skin_price(index: int) -> int:
	return Economy.skin_price(index)

func _mode_price(mode_key: String) -> int:
	return Economy.mode_price(mode_key)

## Двухстрочная лейбл-колонка строки магазина: название + подпись.
## Центрированные, с переносом по словам — ничего не вылезает за поля.
func _row_panel(title: String, subtitle: String = "") -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 2)
	var t := Label.new()
	t.text = title
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 16)
	v.add_child(t)
	if not subtitle.is_empty():
		var s := Label.new()
		s.text = subtitle
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.add_theme_font_size_override("font_size", 13)
		s.add_theme_color_override("font_color", Color(0.72, 0.74, 0.85))
		v.add_child(s)
	return v

## Кнопка товара, вертикально по центру строки.
func _row_btn(disabled: bool, ready_text: String, action_text: String, action: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180.0, 44.0)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.text = ready_text if disabled else action_text
	btn.disabled = disabled
	if not disabled:
		btn.pressed.connect(action)
	return btn

func _build_iap() -> void:
	if Economy.DONATIONS_ONLY:
		_build_donations()
		return
	var header := Label.new()
	header.text = tr("— ПОКУПКИ (реальные деньги) —")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for p: Dictionary in Economy.IAP_PACKS:
		var row := HBoxContainer.new()
		var vip_extra := ""
		if p.has("vip_days") and GameState.vip_days_left > 0:
			vip_extra = tr("  (VIP активен)")
		row.add_child(_row_panel(tr(p.label), tr(p.desc) + vip_extra))
		var btn := Button.new()
		btn.text = str(p.get("price", ""))
		btn.pressed.connect(func() -> void:
			_do_purchase(p.id))
		row.add_child(btn)
		items_box.add_child(row)

func _do_purchase(pack_id: String) -> void:
	AudioManager.play("click")
	PurchaseService.purchase_completed.connect(func(success: bool, pid: String) -> void:
		if success and pid == pack_id:
			GameState.grant_iap_pack(pack_id)
			AudioManager.play("level")
			_rebuild()
	, CONNECT_ONE_SHOT)
	PurchaseService.purchase(pack_id)

func _build_crystal_ad_packs() -> void:
	if Economy.DONATIONS_ONLY:
		return
	var header := Label.new()
	header.text = tr("— КРИСТАЛЛЫ ЗА РЕКЛАМУ —")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for pk: Dictionary in Economy.CRYSTAL_AD_PACKS:
		var row := HBoxContainer.new()
		var pk_id: String = pk.id
		var ads_needed: int = int(pk.ads)
		var done: int = GameState.crystal_pack_progress(pk_id)
		var claimed: bool = GameState.crystal_pack_claimed(pk_id)
		var crystals: int = int(pk.crystals)

		if claimed:
			row.add_child(_row_panel(tr(pk.label), tr("%d крист. — получено ") % crystals))
		else:
			row.add_child(_row_panel(tr(pk.label), tr("%d крист. — ролики %d/%d") % [crystals, done, ads_needed]))
		row.add_child(_row_btn(claimed, tr("ГОТОВО"), tr("СМОТРЕТЬ (%d ост.)") % maxi(ads_needed - done, 0),
			func() -> void: _start_crystal_pack(pk_id)))
		items_box.add_child(row)

## Досмотреть рекламы для пака кристаллов.
func _start_crystal_pack(pk_id: String) -> void:
	if GameState.crystal_pack_claimed(pk_id):
		return
	if not GameState.crystal_pack_progressable(pk_id):
		info_label.text = tr("Сегодня лимит рекламы за кристаллы исчерпан. Возвращайся завтра!")
		return
	AudioManager.play("click")
	AdService.show_rewarded()
	var ok: bool = await AdService.rewarded_completed
	if not ok:
		return
	GameState.record_crystal_pack_ad(pk_id)
	_rebuild()

func _build_skins() -> void:
	var header := Label.new()
	header.text = tr("— СКИНЫ —")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for i in GameState.SKINS.size():
		items_box.add_child(_make_skin_row(i))

func _make_skin_row(index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var data: Dictionary = GameState.SKINS[index]
	var owned := GameState.is_skin_owned(index)
	var enabled := GameState.selected_skin == index
	var price := _skin_price(index)

	var subtitle := ""
	if owned:
		if enabled:
			subtitle = tr("выбран ")
	else:
		subtitle = tr("Открывается на уровне %d.") % data.unlock_level
	row.add_child(_thumb(KNIFE_THUMBS[clampi(index, 0, KNIFE_THUMBS.size() - 1)]))
	row.add_child(_row_panel("%s" % tr(data.label), subtitle))

	var btn := Button.new()
	if owned:
		btn.text = tr("ВЫБРАТЬ")
		btn.pressed.connect(func():
			GameState.selected_skin = index
			GameState.save_settings()
			AudioManager.play("click")
			_rebuild())
	elif GameState.coins >= price:
		btn.text = tr("КУПИТЬ (%d м.)") % price
		btn.pressed.connect(func():
			if GameState.spend_coins(price):
				GameState.purchase_skin(index)
				GameState.selected_skin = index
				GameState.save_settings()
				AudioManager.play("level")
		)
	else:
		btn.text = tr("НУЖНО %d м.") % price
		btn.disabled = true
	row.add_child(btn)
	return row

func _build_modes() -> void:
	var header := Label.new()
	header.text = tr("— МОДЫ —")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for mode_key: String in GameState.MODES:
		items_box.add_child(_make_mode_row(mode_key))

func _make_mode_row(mode_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var data: Dictionary = GameState.MODES[mode_key]
	var owned := GameState.is_mode_owned(mode_key)
	var enabled := GameState.has_mode(mode_key)
	var price := _mode_price(mode_key)

	var subtitle := ""
	if owned:
		subtitle = tr(data.desc)
		if enabled:
			subtitle += tr("  (вкл. )")
	else:
		subtitle = tr("Открывается на уровне %d.") % data.unlock_level
	row.add_child(_row_panel(tr(data.label), subtitle))

	var btn := Button.new()
	if owned:
		btn.text = tr("ВКЛ/ВЫКЛ")
		btn.pressed.connect(func():
			if enabled:
				GameState.selected_modes.erase(mode_key)
			else:
				GameState.selected_modes.append(mode_key)
			GameState.save_settings()
			AudioManager.play("click")
			_rebuild())
	elif GameState.coins >= price:
		btn.text = tr("КУПИТЬ (%d м.)") % price
		btn.pressed.connect(func():
			if GameState.spend_coins(price):
				GameState.purchase_mode(mode_key)
				GameState.selected_modes.append(mode_key)
				GameState.save_settings()
				AudioManager.play("level")
		)
	else:
		btn.text = tr("НУЖНО %d м.") % price
		btn.disabled = true
	row.add_child(btn)
	return row

func _build_boosters() -> void:
	var header := Label.new()
	header.text = tr("— БУСТЕРЫ (одноразовые) —")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		var row := HBoxContainer.new()
		var price: int = b.price
		var owned_count := GameState.booster_count(b.id)
		row.add_child(_row_panel(tr(b.label), "%s — %s" % [tr(b.desc), tr("в наличии: %d") % owned_count]))
		row.add_child(_row_btn(GameState.coins < price, tr("НУЖНО %d м.") % price, tr("КУПИТЬ (%d м.)") % price,
			func() -> void:
				if GameState.spend_coins(price):
					GameState.add_booster(b.id, 1)
					AudioManager.play("level")
					_rebuild()))
		items_box.add_child(row)

func _build_consumables() -> void:
	var header := Label.new()
	header.text = tr("— ПРЕДМЕТЫ (за кристаллы) —")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for c: Dictionary in Economy.CONSUMABLE_ITEMS:
		var row := HBoxContainer.new()
		var c_id: String = c.id
		var count := GameState.consumable_count(c_id)
		row.add_child(_row_panel(tr(c.label), tr("%s (x%d)") % [tr(c.desc), count]))
		var price: int = c.price_crystals
		row.add_child(_row_btn(GameState.crystals < price, tr("НУЖНО %d крист.") % price, tr("КУПИТЬ (%d крист.)") % price,
			func() -> void:
				if GameState.spend_crystals(price):
					GameState.add_consumable(c_id, 1)
					AudioManager.play("level")
					_rebuild()))
		items_box.add_child(row)

func _build_equipment() -> void:
	var header := Label.new()
	header.text = tr("— СНАРЯЖЕНИЕ —")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for slot: String in Economy.EQUIPMENT:
		var slot_title := Label.new()
		slot_title.text = _slot_label(slot)
		slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_box.add_child(slot_title)
		for it in Economy.EQUIPMENT[slot]:
			items_box.add_child(_make_equip_row(it))

func _slot_label(slot: String) -> String:
	match slot:
		"helmet": return tr("ШЛЕМЫ")
		"armor":  return tr("ДОСПЕХИ")
		"boots":  return tr("БОТИНКИ")
		"weapon": return tr("ОРУЖИЕ")
		"ring":   return tr("КОЛЬЦА")
		"shield": return tr("Щит")
	return slot.to_upper()

func _make_equip_row(it: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	var eq_id: String = it.id
	var owned := GameState.is_equipment_owned(eq_id)
	var equipped_id := GameState.equipped_in(it.slot)
	var price: int = it.price

	var label_panel: VBoxContainer
	if owned:
		if equipped_id == eq_id:
			label_panel = _row_panel(tr(it.label), "%s — %s  " % [tr(it.desc), tr("надето")])
		else:
			label_panel = _row_panel(tr(it.label), tr(it.desc))
	else:
		label_panel = _row_panel(tr(it.label), tr("%s (%d м.)") % [tr(it.desc), price])
	if it.slot == "shield":
		row.add_child(_thumb("res://assets/images/shields/%s.png" % eq_id, 56))
	row.add_child(label_panel)

	var btn: Button
	if owned:
		if equipped_id == eq_id:
			btn = _row_btn(false, "", tr("СНЯТЬ"), func() -> void:
				GameState.unequip_slot(it.slot)
				AudioManager.play("click")
				_rebuild())
		else:
			btn = _row_btn(false, "", tr("НАДЕТЬ"), func() -> void:
				GameState.equip_item(eq_id)
				AudioManager.play("level")
				_rebuild())
	elif GameState.coins >= price:
		btn = _row_btn(GameState.coins < price, "", tr("КУПИТЬ"), func() -> void:
			if GameState.spend_coins(price):
				GameState.purchase_equipment(eq_id)
				GameState.equip_item(eq_id)
				AudioManager.play("level")
				_rebuild())
	else:
		btn = _row_btn(GameState.coins < price, "", tr("НУЖНО %d м.") % price, Callable())
	row.add_child(btn)
	return row

func _on_crystal_earn_pressed() -> void:
	AudioManager.play("click")
	if not GameState.can_watch_crystal_ad():
		info_label.text = tr("Сегодня лимит рекламы за кристаллы исчерпан. Возвращайся завтра!")
		return
	AdService.show_rewarded()
	var ok: bool = await AdService.rewarded_completed
	if not ok:
		return
	if not GameState.can_watch_crystal_ad():
		_rebuild()
		return
	GameState.record_crystal_ad()
	GameState.record_ad_watched()
	GameState.add_crystals(Economy.CRYSTALS_PER_AD)
	_rebuild()

func _build_glyphs() -> void:
	var header := Label.new()
	header.text = tr("— ГЛИФЫ —")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for g: Dictionary in Economy.GLYPHS:
		var row := HBoxContainer.new()
		var glyph_id: String = g.id
		var type_tag := tr("временный") if g.type == "T" else tr("вечный")
		var subtitle := ""
		if GameState.has_glyph(glyph_id):
			subtitle = tr("%s [вечный куплен]") % tr(g.desc)
		elif GameState.glyph_active(glyph_id):
			subtitle = tr("%s [активен, осталось %d]") % [tr(g.desc), GameState.temp_glyph_runs(glyph_id)]
		else:
			subtitle = tr("%s (%s, %d м.)") % [tr(g.desc), type_tag, int(g.price)]
		row.add_child(_row_panel(tr(g.label), subtitle))
		var btn: Button
		if GameState.glyph_active(glyph_id):
			btn = _row_btn(true, tr("АКТИВЕН "), "", Callable())
		elif GameState.coins >= int(g.price):
			btn = _row_btn(false, "", tr("КУПИТЬ (%d м.)") % int(g.price), func() -> void:
				if GameState.purchase_glyph(glyph_id):
					AudioManager.play("level")
					_rebuild())
		else:
			btn = _row_btn(true, tr("НУЖНО %d м.") % int(g.price), "", Callable())
		row.add_child(btn)
		items_box.add_child(row)

func _on_earn_pressed() -> void:
	AudioManager.play("click")
	if not GameState.can_watch_coins_ad():
		info_label.text = tr("Сегодня ты уже забрал все бонусные монеты за рекламу. Возвращайся завтра!")
		return
	AdService.show_rewarded()
	var ok: bool = await AdService.rewarded_completed
	if not ok:
		return
	if not GameState.can_watch_coins_ad():
		_rebuild()
		return
	GameState.record_coin_ad()
	GameState.record_ad_watched()
	GameState.add_coins(GameState.ad_coin_reward())
	_rebuild()

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

const KNIFE_THUMBS := [
	"res://assets/images/knives/knife_gold.png", "res://assets/images/knives/knife_neon.png",
	"res://assets/images/knives/knife_ice.png", "res://assets/images/knives/knife_ruby.png",
	"res://assets/images/knives/knife_shadow.png", "res://assets/images/knives/knife_elektro.png",
	"res://assets/images/knives/knife_toxic.png", "res://assets/images/knives/knife_cosmos.png",
	"res://assets/images/knives/knife_zona.png", "res://assets/images/knives/knife_desert.png",
	"res://assets/images/knives/knife_retro.png", "res://assets/images/knives/knife_empire.png",
]

func _thumb(path: String, sz: int = 52) -> TextureRect:
	var t := TextureRect.new()
	if ResourceLoader.exists(path):
		t.texture = load(path)
	t.custom_minimum_size = Vector2(sz, sz)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t

func _build_avatars() -> void:
	var header := Label.new()
	header.text = "— АВАТАРЫ —"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for i in 21:
		items_box.add_child(_make_avatar_row(i))

func _make_avatar_row(index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var owned := GameState.is_avatar_owned(index)
	var enabled := GameState.avatar == index
	var pr := GameState.avatar_price(index)
	var sub := ""
	if owned:
		sub = "Выбран" if enabled else "Куплен"
	else:
		sub = "Цена: %d" % pr
	row.add_child(_thumb("res://assets/images/avatars/avatar_%d.png" % index))
	row.add_child(_row_panel("Аватар %d" % (index + 1), sub))
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 44)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if owned:
		if enabled:
			btn.text = "ВЫБРАН"
			btn.disabled = true
		else:
			btn.text = "ВЫБРАТЬ"
			btn.pressed.connect(func() -> void:
				GameState.avatar = index
				GameState.save_settings()
				_rebuild())
	else:
		btn.text = "КУПИТЬ"
		btn.disabled = GameState.coins < pr
		btn.pressed.connect(func() -> void:
			if GameState.buy_avatar(index):
				AudioManager.play("level")
				_rebuild())
	row.add_child(btn)
	return row

const SKIN_SETS := [
	{"name": "Эко", "ids": [1, 6]},
	{"name": "Кибер", "ids": [5, 6, 7]},
	{"name": "Империя", "ids": [0, 3, 11]},
	{"name": "Зона", "ids": [8, 9]},
	{"name": "Ретро", "ids": [10, 2]},
]

func _build_sets() -> void:
	var header := Label.new()
	header.text = "— НАБОРЫ СКИНОВ (скидка 20%) —"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(header)
	for s in SKIN_SETS:
		var row := HBoxContainer.new()
		var ids: Array = s["ids"]
		var all_owned := true
		var names := []
		for i in ids:
			names.append(tr(str(GameState.SKINS[int(i)].label)))
			if not GameState.is_skin_owned(int(i)):
				all_owned = false
		var sub := ", ".join(PackedStringArray(names))
		row.add_child(_row_panel("%s" % tr(str(s["name"])), sub))
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 44)
		if all_owned:
			btn.text = tr("КУПЛЕНО")
			btn.disabled = true
		else:
			btn.text = "%s %d" % [tr("КУПИТЬ"), GameState.skin_set_price(ids)]
			btn.disabled = GameState.coins < GameState.skin_set_price(ids)
			btn.pressed.connect(func() -> void:
				if GameState.buy_skin_set(ids):
					AudioManager.play("level")
					_rebuild())
		row.add_child(btn)
		items_box.add_child(row)

func _build_donations() -> void:
	var header := Label.new()
	header.text = tr("Поддержать проект")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 24)
	items_box.add_child(header)
	var note := Label.new()
	note.text = tr("Покупки за рубли временно отключены. Поддержка — по ссылкам ниже.")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	items_box.add_child(note)
	for d: Dictionary in Economy.DONATIONS:
		var row := HBoxContainer.new()
		row.add_child(_row_panel(str(d.label), str(d.desc)))
		var btn := Button.new()
		btn.text = tr("Открыть")
		btn.custom_minimum_size = Vector2(140, 48)
		btn.pressed.connect(func() -> void:
			AudioManager.play("level")
			GameState.mark_supporter()
			Telemetry.event("donate_click", {"channel": str(d.label)})
			OS.shell_open(str(d.url))
			_note("Спасибо за поддержку! Вы — Меценат Империи.")
			_rebuild())
		row.add_child(btn)
		items_box.add_child(row)


func _note(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	items_box.add_child(l)


const CLASS_WPN := [
	["warrior", "Воин"], ["rogue", "Разбойник"], ["mage", "Маг"], ["archer", "Лучник"],
	["knight", "Рыцарь"], ["berserker", "Берсерк"], ["assassin", "Ассасин"], ["paladin", "Паладин"],
	["druid", "Друид"], ["monk", "Монах"], ["pirate", "Пират"], ["samurai", "Самурай"],
	["ninja", "Ниндзя"], ["viking", "Викинг"], ["gunslinger", "Стрелок"], ["alchemist", "Алхимик"],
	["necromancer", "Некромант"], ["engineer", "Инженер"], ["bounty_hunter", "Охотник"], ["shaman", "Шаман"],
	["champion", "Чемпион"], ["princess", "Принцесса"],
]


func _build_class_weapons() -> void:
	var head := Label.new()
	head.text = tr("ОРУЖИЕ КЛАССОВ")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 20)
	items_box.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	items_box.add_child(grid)
	for pair in CLASS_WPN:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(300, 130)
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(96, 96)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var wp := "res://assets/images/weapons/%s.png" % str(pair[0])
		if ResourceLoader.exists(wp):
			tex.texture = load(wp)
		cell.add_child(tex)
		var nm := Label.new()
		nm.text = tr(str(pair[1]))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(nm)
		grid.add_child(cell)
