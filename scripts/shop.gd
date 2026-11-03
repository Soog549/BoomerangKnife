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
		sc.offset_bottom = -120.0
	# НАЗАД — к реальному низу экрана (а не к 1280 на высоких устройствах)
	var vp: Vector2 = get_viewport_rect().size
	var back := get_node_or_null("Scroll/BackButton")
	if back == null:
		back = _find_back(self)
	if back is Control:
		var b := back as Control
		b.set_anchors_preset(Control.PRESET_TOP_LEFT)
		b.position = Vector2(36.0, vp.y - 96.0)
		b.custom_minimum_size = Vector2(200.0, 52.0)
		b.size = Vector2(200.0, 52.0)


func _find_back(n: Node) -> Node:
	if n is Button and str((n as Button).text).find("НАЗАД") != -1:
		return n
	for c in n.get_children():
		var r := _find_back(c)
		if r != null:
			return r
	return null

func _on_coins(total: int) -> void:
	wallet_label.text = tr("Монеты %d  ·  Кристаллы %d  ·  Осколки %d") % [total, GameState.crystals, GameState.shards]

var _slot_filter := ""


var _shop_page := 0
var _eq_sort := 0

const SHOP_PAGES := [
	["ПЕРСОНАЖ", ["_build_class_weapons", "_build_class_gallery"]],
	["ОБРАЗЫ", ["_build_skins", "_build_sets", "_build_avatars", "_build_companions"]],
	["РЕЖИМЫ", ["_build_modes", "_build_boosters", "_build_consumables"]],
	["СНАРЯЖЕНИЕ", ["_build_equipment"]],
	["ПРОЧЕЕ", ["_build_glyphs", "_build_iap", "_build_crystal_ad_packs", "_build_donations"]],
	["СЕТЫ", ["_build_sets_page"]],
]


func _rebuild() -> void:
	for child in items_box.get_children():
		child.queue_free()
	var trust := Label.new()
	trust.text = tr("БЕЗ РЕКЛАМЫ · ОФЛАЙН · ПРОГРЕСС СОХРАНЯЕТСЯ")
	trust.add_theme_font_size_override("font_size", 13)
	trust.add_theme_color_override("font_color", Color(0.55, 0.9, 0.75, 0.9))
	trust.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_box.add_child(trust)

	# Единый предпросмотр персонажа (полное тело, как в профиле)
	var pv := TextureRect.new()
	var cls_idx: int = clampi(GameState.avatar, 0, CLASS_WPN.size() - 1) if CLASS_WPN.size() > 0 else 0
	var cp := "res://assets/images/classes_full/%s.png" % str(CLASS_WPN[cls_idx][0])
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
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.text = tr("Твой максимальный уровень: %d — проходи уровни, открывай цели или смотри рекламу за монеты:") % GameState.max_level_reached
	wallet_label.text = tr("Монеты %d  ·  Кристаллы %d  ·  Осколки %d") % [GameState.coins, GameState.crystals, GameState.shards]
	var left := GameState.coin_ads_left()
	if left > 0:
		earn_btn.text = tr("Смотреть рекламу (+%d монет) — осталось %d") % [Economy.AD_REWARD_COINS, left]
	else:
		earn_btn.text = tr("Реклама исчерпана · сброс через %s") % GameState.ad_reset_in_text()
		earn_btn.disabled = true
	var cleft := GameState.crystal_ads_left()
	if cleft > 0:
		crystal_earn_btn.text = tr("Реклама за кристаллы (+%d) — осталось %d") % [Economy.CRYSTALS_PER_AD, cleft]
	else:
		crystal_earn_btn.text = tr("Кристаллы: лимит · сброс через %s") % GameState.ad_reset_in_text()
		crystal_earn_btn.disabled = true
	_build_page_tabs()
	_build_pager()
	var page: Array = SHOP_PAGES[clampi(_shop_page, 0, SHOP_PAGES.size() - 1)]
	for m in page[1]:
		call(str(m))

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
	var sc_counts: Dictionary = GameState.equipment_set_counts()
	if not sc_counts.is_empty():
		var line := "Сеты: "
		for k in sc_counts:
			line += "%s %d/6   " % [str(k), int(sc_counts[k])]
		var sl := Label.new()
		sl.text = tr(line)
		sl.add_theme_font_size_override("font_size", 13)
		sl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		items_box.add_child(sl)
	var sort_row := HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 6)
	var sorts := [["ЦЕНА", 0], ["КАЧЕСТВО", 1], ["УРОВЕНЬ", 2]]
	for sd in sorts:
		var sb2 := Button.new()
		sb2.text = tr(str(sd[0]))
		sb2.custom_minimum_size = Vector2(0, 38)
		sb2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb2.add_theme_font_size_override("font_size", 12)
		sb2.disabled = int(sd[1]) == _eq_sort
		var key: int = int(sd[1])
		sb2.pressed.connect(func() -> void:
			_eq_sort = key
			AudioManager.play("click")
			_rebuild())
		sort_row.add_child(sb2)
	items_box.add_child(sort_row)
	var auto_b := Button.new()
	auto_b.text = tr("АВТО-ЭКИП (лучшее)")
	auto_b.custom_minimum_size = Vector2(0, 44)
	var buyall := Button.new()
	buyall.text = tr("КУПИТЬ ДОСТУПНОЕ (до 6)")
	buyall.custom_minimum_size = Vector2(0, 44)
	buyall.pressed.connect(func() -> void:
		var dlg := ConfirmationDialog.new()
		dlg.title = tr("Массовая покупка")
		dlg.dialog_text = tr("Купить до 6 доступных предметов по уровню и монетам?")
		dlg.ok_button_text = tr("КУПИТЬ")
		dlg.cancel_button_text = tr("Отмена")
		add_child(dlg)
		dlg.confirmed.connect(func() -> void:
			var b := GameState.buy_all_affordable(6)
			AudioManager.play("level")
			Toast.show(tr("Куплено: %d") % b)
			_rebuild())
		dlg.popup_centered())
	items_box.add_child(buyall)
	auto_b.pressed.connect(func() -> void:
		var ch := GameState.auto_equip_best()
		AudioManager.play("level")
		Toast.show(tr("Экипировано: %d") % ch)
		_rebuild())
	items_box.add_child(auto_b)
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 6)
	var fdefs := [["", "ВСЕ"], ["helmet", "ШЛЕМ"], ["armor", "БРОНЯ"], ["boots", "БОТЫ"],
		["weapon", "ОРУЖИЕ"], ["ring", "КОЛЬЦА"], ["shield", "ЩИТ"]]
	for fd in fdefs:
		var fb := Button.new()
		fb.text = tr(str(fd[1]))
		fb.custom_minimum_size = Vector2(0, 40)
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fb.disabled = _slot_filter == str(fd[0])
		var fk: String = str(fd[0])
		fb.pressed.connect(func() -> void:
			_slot_filter = fk
			AudioManager.play("click")
			_rebuild())
		frow.add_child(fb)
	items_box.add_child(frow)
	for slot: String in ItemsDB.SLOTS:
		if _slot_filter != "" and str(slot) != _slot_filter:
			continue
		var slot_title := Label.new()
		var own_cnt := 0
		for _it in ItemsDB.build_slot(str(slot)):
			if GameState.is_equipment_owned(_it.id):
				own_cnt += 1
		slot_title.text = "%s  (%d/%d)" % [_slot_label(slot), own_cnt, Economy.items(str(slot)).size()]
		slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_box.add_child(slot_title)
		var slot_items: Array = ItemsDB.build_slot(str(slot))
		if _eq_sort == 0:
			slot_items.sort_custom(func(a, b) -> bool: return int(a["price"]) < int(b["price"]))
		elif _eq_sort == 1:
			slot_items.sort_custom(func(a, b) -> bool: return int(a["quality"]) > int(b["quality"]))
		else:
			slot_items.sort_custom(func(a, b) -> bool: return int(a["req_level"]) < int(b["req_level"]))
		for it in slot_items:
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

	var qname: String = str(it.get("quality_name", ""))
	var req: int = int(it.get("req_level", 1))
	var stext: String = str(it.get("stats_text", ""))
	var locked: bool = GameState.player_level < req
	var sub: String = "%s · ур.%d · %s" % [qname, req, stext]
	if owned:
		sub = sub + "  —  " + (tr("надето") if equipped_id == eq_id else tr("в сумке"))
		var lv: int = GameState.item_level(eq_id)
		if lv > 0:
			sub = sub + "  ·  +%d ур." % lv
	elif locked:
		sub = sub + "  ·  " + tr("нужен уровень %d") % req
	else:
		sub = sub + "  ·  %d" % price + " " + tr("монет")
	if not owned and equipped_id != "":
		var cur2: Dictionary = ItemsDB.find_item(str(it.get("slot", "")), equipped_id)
		if not cur2.is_empty():
			var d1: float = GameState.item_score(it)
			var d2: float = GameState.item_score(cur2)
			sub = ("↑ " + sub) if d1 > d2 + 0.01 else (("↓ " + sub) if d1 < d2 - 0.01 else ("= " + sub))
	if equipped_id != "" and equipped_id != eq_id:
		var cur: Dictionary = ItemsDB.find_item(str(it.get("slot", "")), equipped_id)
		if not cur.is_empty():
			var delta_text := ""
			var mine: Dictionary = it.get("stats", {})
			var theirs: Dictionary = cur.get("stats", {})
			var keys: Array = ["dmg", "hp", "def", "speed", "crit", "block"]
			for k in keys:
				var dv: float = float(mine.get(k, 0.0)) - float(theirs.get(k, 0.0))
				if absf(dv) < 0.001:
					continue
				var nm: String = str(ItemsDB.STAT_LABELS.get(k, k))
				var val: String = ("%+.2f" % dv) if k in ["speed", "crit"] else ("%+d" % int(round(dv)))
				delta_text += "%s %s  " % [nm, val]
			sub = sub + "   |   " + tr("сейчас: %s") % str(cur.get("name", ""))
			if delta_text != "":
				sub = sub + "   (" + delta_text.strip_edges() + ")"
	var label_panel: VBoxContainer = _row_panel(str(it.get("name", it.get("label", ""))), sub)
	var title_label: Label = label_panel.get_child(0) as Label
	if title_label != null:
		title_label.add_theme_color_override("font_color", it.get("color", Color(1, 1, 1)))
	var qi: int = int(it.get("quality", 0)) + 1
	var ip := "res://assets/images/equipment/%s_q%d.png" % [str(it.get("slot", "")), qi]
	if not ResourceLoader.exists(ip):
		ip = "res://assets/images/equipment/%s.png" % eq_id
	if not ResourceLoader.exists(ip) and it.slot == "shield":
		ip = "res://assets/images/shields/%s.png" % eq_id
	if ResourceLoader.exists(ip):
		row.add_child(_rarity_thumb(ip, 56, it.get("color", Color(0.8, 0.8, 0.85))))
	row.add_child(label_panel)
	if not owned and eq_id.contains("_v"):
		var nb := Label.new()
		nb.text = "NEW"
		nb.add_theme_font_size_override("font_size", 12)
		nb.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		nb.custom_minimum_size = Vector2(42, 0)
		nb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(nb)

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
	elif locked:
		btn = _row_btn(true, "", tr("нужен ур. %d") % req, Callable())
	elif GameState.coins >= price:
		btn = _row_btn(GameState.coins < price, "", tr("КУПИТЬ"), func() -> void:
			if GameState.spend_coins(price):
				GameState.purchase_equipment(eq_id)
				GameState.track("shop_buys")
				GameState.track("daily_shop")
				GameState.equip_item(eq_id)
				AudioManager.play("level")
				_rebuild())
	else:
		btn = _row_btn(GameState.coins < price, "", tr("НУЖНО %d м.") % price, Callable())
	row.add_child(btn)
	if owned:
		var lv2: int = GameState.item_level(eq_id)
		var cost: int = GameState.upgrade_cost(eq_id)
		var ub := Button.new()
		ub.text = tr("УЛУЧШИТЬ (%d)") % cost
		ub.custom_minimum_size = Vector2(150, 46)
		ub.disabled = GameState.coins < cost
		ub.add_theme_font_size_override("font_size", 12)
		ub.pressed.connect(func() -> void:
			if GameState.upgrade_item(eq_id):
				GameState.track("items_upgraded")
				AudioManager.play("level")
				_rebuild())
		row.add_child(ub)
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
	note.text = tr("Покупки за рубли — скоро. Найти нас:")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	items_box.add_child(note)
	for d: Dictionary in Economy.DONATIONS:
		var row := HBoxContainer.new()
		row.add_child(_row_panel(str(d.label), str(d.desc)))
		var lbl := Label.new()
		lbl.text = "%s: %s" % [str(d.label), str(d.get("handle", ""))]
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(170, 48)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.75))
		lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(lbl)
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
	["champion", "Чемпион"], ["princess", "Принцесса"],  ["kinetic", "Кинетик"], ["pyro", "Пиромант"], ["cryo", "Криомант"], ["psion", "Псайкер"], ["telekinetic", "Телекинетик"], ["kimaster", "Мастер КИ"], ["aurate", "Аурат"], ["graviton", "Гравитоник"], ["symbiote", "Симбиот"], ["empath", "Эмпат"], ["fist", "Кулачный"],
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
		var tex_panel := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.92, 0.94, 1.0, 0.16)
		sb.border_color = Color(1.0, 0.9, 0.6, 0.55)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		sb.set_content_margin_all(6)
		tex_panel.add_theme_stylebox_override("panel", sb)
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(96, 96)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var wp := "res://assets/images/weapons/%s.png" % str(pair[0])
		if ResourceLoader.exists(wp):
			tex.texture = load(wp)
		tex_panel.add_child(tex)
		cell.add_child(tex_panel)
		var nm := Label.new()
		nm.text = tr(str(pair[1]))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(nm)
		grid.add_child(cell)


func _build_class_gallery() -> void:
	var head := Label.new()
	head.text = tr("КЛАССЫ (выбери своего)")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 20)
	items_box.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	items_box.add_child(grid)
	for i in CLASS_WPN.size():
		var pair: Array = CLASS_WPN[i]
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(210, 190)
		cell.flat = true
		var vb := VBoxContainer.new()
		vb.custom_minimum_size = Vector2(200, 180)
		cell.add_child(vb)
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(140, 140)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var cp := "res://assets/images/classes_full/%s.png" % str(pair[0])
		if ResourceLoader.exists(cp):
			tex.texture = load(cp)
		vb.add_child(tex)
		var nm := Label.new()
		nm.text = tr(str(pair[1]))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 14)
		if i == GameState.avatar:
			nm.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			nm.text = "★ " + nm.text
		vb.add_child(nm)
		var ci := i
		if ci >= 8 and not (ci in GameState.owned_avatars):
			var price := 20
			var pl := Label.new()
			pl.text = "🔒 %d 💎" % price
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
			vb.add_child(pl)
			cell.pressed.connect(func() -> void:
				if GameState.buy_class(ci, price):
					AudioManager.play("level")
					Toast.show(tr("Класс открыт"))
					_rebuild()
				else:
					AudioManager.play("deny")
					Toast.show(tr("Не хватает кристаллов")))
		else:
			cell.pressed.connect(func() -> void:
				GameState.avatar = ci
				GameState.save_settings()
				AudioManager.play("level")
				Toast.show(tr("Класс выбран"))
				_rebuild())
		grid.add_child(cell)


func _build_page_tabs() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in SHOP_PAGES.size():
		var b := Button.new()
		b.text = tr(str(SHOP_PAGES[i][0]))
		b.custom_minimum_size = Vector2(0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 13)
		b.disabled = i == _shop_page
		var idx: int = i
		b.pressed.connect(func() -> void:
			_shop_page = idx
			AudioManager.play("click")
			_rebuild())
		row.add_child(b)
	items_box.add_child(row)


func _build_pager() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(70, 44)
	prev.disabled = _shop_page <= 0
	prev.pressed.connect(func() -> void:
		_shop_page = maxi(0, _shop_page - 1)
		AudioManager.play("click")
		_rebuild())
	row.add_child(prev)
	var mid := Label.new()
	mid.text = "%d / %d" % [_shop_page + 1, SHOP_PAGES.size()]
	mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_font_size_override("font_size", 16)
	row.add_child(mid)
	var nxt := Button.new()
	nxt.text = "▶"
	nxt.custom_minimum_size = Vector2(70, 44)
	nxt.disabled = _shop_page >= SHOP_PAGES.size() - 1
	nxt.pressed.connect(func() -> void:
		_shop_page = mini(SHOP_PAGES.size() - 1, _shop_page + 1)
		AudioManager.play("click")
		_rebuild())
	row.add_child(nxt)
	items_box.add_child(row)


func _build_sets_page() -> void:
	var head := Label.new()
	head.text = tr("НАБОРЫ (СЕТЫ)")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 20)
	items_box.add_child(head)
	var hint := Label.new()
	hint.text = tr("2 предмета: +3% HP · 4: +5% HP и урон · 6: +10% HP, +8% урон, +5% скорость")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	items_box.add_child(hint)

	var counts: Dictionary = GameState.equipment_set_counts()
	var sets: Array = ["стража", "легиона", "степи", "бездны", "империи"]
	for s in sets:
		var have: int = int(counts.get(s, 0))
		var row := _row_panel("Сет «%s»" % s, "%d / 6   ·   %s" % [have, tr("собери предметы этого сета")])
		var title: Label = row.get_child(0) as Label
		if title != null:
			title.add_theme_color_override("font_color",
				Color(1.0, 0.86, 0.4) if have >= 6 else Color(0.85, 0.9, 1.0))
		items_box.add_child(row)


func _rarity_thumb(path: String, px: int, col: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.14, 0.85)
	sb.set_corner_radius_all(10)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(px, px)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = load(path)
	panel.add_child(tex)
	return panel

func _sale_label(base_price: int) -> String:
	if not Economy.sale_active():
		return "%d ₽" % base_price
	return "%d ₽  (-40%%)" % Economy.price_with_sale(base_price)


func _build_companions() -> void:
	var head := Label.new()
	head.text = tr("КОМПАНЬОНЫ")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 18)
	items_box.add_child(head)
	var owned: bool = GameState.companion_id >= 3
	var row := _row_panel("Тень (компаньон)", 
		(tr("уже с тобой") if owned else tr("25 💎 · атакует врагов рядом")))
	var btn := Button.new()
	btn.text = tr("КУПЛЕНО") if owned else tr("КУПИТЬ 25 💎")
	btn.custom_minimum_size = Vector2(200, 48)
	btn.disabled = owned
	btn.pressed.connect(func() -> void:
		if GameState.crystals < 25:
			Toast.show(tr("Нужно 25 кристаллов"))
			return
		GameState.crystals -= 25
		GameState.companion_id = 3
		GameState.save_settings()
		AudioManager.play("level")
		Toast.show(tr("Компаньон получен: ТЕНЬ"))
		_rebuild())
	items_box.add_child(row)
	items_box.add_child(btn)
