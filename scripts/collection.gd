extends Control
## КОЛЛЕКЦИЯ — 2 набора карточек по 2 в ряд: ЛОР (12) + ДОСТИЖЕНИЯ (12).
## Лор открывается по реликвиям; достижения — по прогрессу (реликвии/волны).
## Дип-Про, 2026-10-24.

const LORE := [
	["Империя ZWS", "Легенда", 0],
	["Бумеранг-нож", "Обычный", 0],
	["Скит", "Необычный", 1],
	["Принцесса Аврора", "Редкий", 2],
	["Аркт Первый", "Редкий", 3],
	["Кузня имплантов", "Необычный", 4],
	["Рубиновые шахты", "Редкий", 5],
	["Цикл памяти", "Эпический", 6],
	["Окраина", "Обычный", 7],
	["Пустошь", "Необычный", 8],
	["Рубеж", "Эпический", 9],
	["Космический оазис", "Легенда", 11],
]
const ACH := [
	["Первая кровь", "ОБЫЧНО", "first_blood"], ["Волна 5", "РЕДКОЕ", "wave5"], ["Волна 10", "ЭПИК", "wave10"],
	["Комбо x5", "РЕДКОЕ", "combo5"], ["Комбо x10", "ЭПИК", "combo10"], ["Без урона", "РЕДКОЕ", "no_damage"],
	["Первый босс", "ЛЕГЕНДА", "boss1"], ["Коллекционер", "ЭПИК", "collector"], ["Ключ Разлома", "ЛЕГЕНДА", "legendary"],
	["100 монет", "ОБЫЧНО", "coins100"], ["Щит-мастер", "РЕДКОЕ", "shield_master"], ["Оператор", "ЛЕГЕНДА", "wave20"],
]
const RCOL := {
	"ОБЫЧНО": Color(0.72, 0.72, 0.78),
	"РЕДКОЕ": Color(0.30, 0.60, 1.00),
	"ЭПИК": Color(0.75, 0.35, 1.00),
	"ЛЕГЕНДА": Color(1.00, 0.80, 0.20),
}

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.12, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = tr("BOOMERANGKNIFE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	title.position = Vector2(0, 14)
	title.size = Vector2(720, 38)
	add_child(title)
	var intro := Label.new()
	intro.text = tr("Империя ZWS · собери реликвии, открой историю")
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_font_size_override("font_size", 16)
	intro.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	intro.position = Vector2(0, 50)
	intro.size = Vector2(720, 22)
	add_child(intro)
	var info := Label.new()
	info.text = tr("Реликвии: %d") % GameState.relics_total
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 18)
	info.position = Vector2(0, 76)
	info.size = Vector2(720, 26)
	add_child(info)

	var sc := ScrollContainer.new()
	sc.position = Vector2(30, 108)
	sc.size = Vector2(660, 1000)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(660, 0)
	col.add_theme_constant_override("separation", 10)
	sc.add_child(col)

	_render(col)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.position = Vector2(60, 1120)
	back.size = Vector2(600, 56)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(back)

func _header(txt: String) -> Label:
	var h := Label.new()
	h.text = txt
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 22)
	h.add_theme_color_override("font_color", Color(0.6, 0.95, 0.8))
	return h

func _grid(data: Array, pattern: String, by_ach: bool) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	for i in data.size():
		g.add_child(_cell(data[i], pattern % (i + 1), i, by_ach))
	return g

func _cell(row: Array, path: String, idx: int, by_ach: bool) -> Control:
	var nm: String = str(row[0])
	var rar: String = str(row[1])
	var unlocked: bool
	if by_ach:
		unlocked = GameState.arena_ach.has(str(row[2]))
	else:
		unlocked = GameState.relics_total >= int(row[2])
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(310, 300)
	var tex := TextureRect.new()
	var use_path := path
	if not by_ach:
		var warts2: Array = ["world_forest", "world_steppe", "world_ruin", "world_abyss",
			"world_neon", "world_ice", "world_electro", "world_cosmos"]
		use_path = "res://assets/images/worlds/%s.png" % str(warts2[idx % warts2.size()])
	if not by_ach and not ResourceLoader.exists(use_path):
		var warts: Array = ["world_forest", "world_steppe", "world_ruin", "world_abyss",
			"world_neon", "world_ice", "world_electro", "world_cosmos"]
		var wp := "res://assets/images/worlds/%s.png" % str(warts[idx % warts.size()])
		if ResourceLoader.exists(wp):
			use_path = wp
		else:
			use_path = "res://assets/images/packs/%s/card-%d.png" % [GameState.style_pack, (idx % 3) + 1]
	if by_ach and not ResourceLoader.exists(use_path):
		use_path = "res://assets/images/packs/%s/ach-%d.png" % [GameState.style_pack, (idx % 3) + 1]
	if ResourceLoader.exists(use_path):
		tex.texture = load(use_path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(310, 400)
	tex.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.22, 0.22, 0.28, 1)
	v.add_child(tex)
	var nl := Label.new()
	nl.text = tr(nm) if unlocked else "???"
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.add_theme_font_size_override("font_size", 18)
	v.add_child(nl)
	var rl := Label.new()
	rl.text = tr(rar) if unlocked else (tr("НЕ ОТКРЫТО") if by_ach else (tr("Нужно реликвий: %d") % int(row[2])))
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rl.add_theme_font_size_override("font_size", 15)
	rl.add_theme_color_override("font_color", RCOL.get(rar, Color.WHITE) if unlocked else Color(0.6, 0.6, 0.7))
	v.add_child(rl)
	var btn := Button.new()
	btn.text = tr("ПОДРОБНЕЕ")
	btn.custom_minimum_size = Vector2(310, 40)
	btn.pressed.connect(func() -> void: _open_detail(nm, rar, path, unlocked))
	v.add_child(btn)
	return v


func _open_detail(nm: String, rar: String, path: String, unlocked: bool) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var box := Control.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(box)
	var tex := TextureRect.new()
	if unlocked and ResourceLoader.exists(path):
		tex.texture = load(path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.position = Vector2(60, 120)
	tex.size = Vector2(600, 800)
	box.add_child(tex)
	var t := Label.new()
	t.text = tr(nm) if unlocked else "???"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 36)
	t.size = Vector2(720, 50)
	t.add_theme_font_size_override("font_size", 28)
	box.add_child(t)
	var r := Label.new()
	r.text = tr(rar) if unlocked else tr("НЕ ОТКРЫТО")
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.position = Vector2(0, 940)
	r.size = Vector2(720, 30)
	r.add_theme_font_size_override("font_size", 20)
	box.add_child(r)
	var dl := Label.new()
	dl.text = _lore_text(nm, rar, unlocked)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.position = Vector2(60, 980)
	dl.size = Vector2(600, 120)
	dl.add_theme_font_size_override("font_size", 16)
	dl.add_theme_color_override("font_color", Color(0.86, 0.9, 1.0, 0.95))
	box.add_child(dl)
	var close := Button.new()
	close.text = tr("ЗАКРЫТЬ")
	close.position = Vector2(60, 990)
	close.size = Vector2(600, 56)
	close.pressed.connect(func() -> void: layer.queue_free())
	box.add_child(close)


var _coll_tab := 0
var _coll_page := 0
const COLL_PER := 6


func _coll_data() -> Array:
	return LORE if _coll_tab == 0 else ACH


func _render(col: VBoxContainer) -> void:
	for ch in col.get_children():
		ch.queue_free()
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	for i in 2:
		var b := Button.new()
		b.text = tr("ЛОР") if i == 0 else tr("ДОСТИЖЕНИЯ")
		b.custom_minimum_size = Vector2(0, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = i == _coll_tab
		var idx: int = i
		b.pressed.connect(func() -> void:
			_coll_tab = idx
			_coll_page = 0
			AudioManager.play("click")
			_render(col))
		tabs.add_child(b)
	col.add_child(tabs)

	var data := _coll_data()
	var pages: int = maxi(1, int(ceil(float(data.size()) / float(COLL_PER))))
	_coll_page = clampi(_coll_page, 0, pages - 1)

	var pager := HBoxContainer.new()
	pager.add_theme_constant_override("separation", 8)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(70, 44)
	prev.disabled = _coll_page <= 0
	prev.pressed.connect(func() -> void:
		_coll_page = maxi(0, _coll_page - 1)
		_render(col))
	pager.add_child(prev)
	var mid := Label.new()
	mid.text = "%d / %d" % [_coll_page + 1, pages]
	mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pager.add_child(mid)
	var nxt := Button.new()
	nxt.text = "▶"
	nxt.custom_minimum_size = Vector2(70, 44)
	nxt.disabled = _coll_page >= pages - 1
	nxt.pressed.connect(func() -> void:
		_coll_page = mini(pages - 1, _coll_page + 1)
		_render(col))
	pager.add_child(nxt)
	col.add_child(pager)
	if _coll_tab == 1:
		var opened := 0
		for a in ACH:
			if GameState.arena_ach.has(str(a[2])):
				opened += 1
		var pl := Label.new()
		pl.text = tr("Открыто %d / %d") % [opened, ACH.size()]
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_size_override("font_size", 14)
		pl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
		col.add_child(pl)

	var from_i: int = _coll_page * COLL_PER
	var to_i: int = mini(data.size(), from_i + COLL_PER)
	var page_data: Array = data.slice(from_i, to_i)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	var pattern: String = ("res://assets/images/fanclub/cards/card-%02d.png" if _coll_tab == 0
		else "res://assets/images/fanclub/achievements/ach-%02d.png")
	for i in page_data.size():
		g.add_child(_cell(page_data[i], pattern % (from_i + i + 1), from_i + i, _coll_tab == 1))
	col.add_child(g)


const LORE_TEXT := {
	"Империя ZWS": "Государство, которое торгует памятью. Здесь память — валюта, а забвение — роскошь.",
	"Бумеранг-нож": "Оружие Оператора. Возвращается к хозяину, пока тот помнит, кто он.",
	"Скит": "Кибер-ящер, спутник с характером. Ворчит, но прикрывает спину.",
	"Принцесса Аврора": "Наследница, ставшая Оператором. Её удары — приказ, а не просьба.",
	"Аркт Первый": "Первый Оператор. Его имя — единственное, что не смогли стереть.",
	"Кузня имплантов": "Здесь платят памятью за силу. Кузнецы не спрашивают, что ты забудешь.",
	"Рубиновые шахты": "Красные жилы под городом. Каждый кристалл — чей-то украденный день.",
	"Цикл памяти": "Колесо, что крутит империю. Пока оно вертится, никто не умирает окончательно.",
	"Окраина": "Начало пути. Здесь ещё помнят старые песни и старые обиды.",
	"Пустошь": "Земля, где память выгорела. Живое держится на упрямстве.",
	"Рубеж": "Граница, за которой память не возвращается. Отсюда не пишут писем.",
	"Космический оазис": "Последнее место, где память хранят добровольно. И самое опасное.",
}


func _lore_text(nm: String, rar: String, unlocked: bool) -> String:
	var base: String = str(LORE_TEXT.get(nm, "Реликвия империи. Открывается по мере прохождения."))
	if not unlocked:
		return "Закрыто. " + base
	return base
