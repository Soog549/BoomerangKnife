extends Control
## КОЛЛЕКЦИЯ — 2 набора карточек по 2 в ряд: ЛОР (12) + ДОСТИЖЕНИЯ (12).
## Лор открывается по реликвиям; достижения — по прогрессу (реликвии/волны).
## Дип-Про, 2026-10-24.

const LORE := [
	["Оператор", "ОБЫЧНО", 0], ["Смотритель", "РЕДКОЕ", 0], ["Рой-бегун", "ОБЫЧНО", 0],
	["Кибер-дрон", "РЕДКОЕ", 2], ["Аномалия", "ЭПИК", 3], ["Босс Эхо", "ЛЕГЕНДА", 5],
	["Ядро", "ЭПИК", 4], ["Аренщик", "ОБЫЧНО", 1], ["Оператор · Зона", "РЕДКОЕ", 2],
	["Смотритель · Империя", "ЛЕГЕНДА", 6], ["Рой-бегун · Лёд", "ОБЫЧНО", 1],
	["Кибер-дрон · Рой", "ЭПИК", 4],
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

	col.add_child(_header(tr("КАРТОЧКИ ЛОРА")))
	col.add_child(_grid(LORE, "res://assets/images/fanclub/cards/card-%02d.png", false))
	col.add_child(_header(tr("КАРТОЧКИ ДОСТИЖЕНИЙ")))
	col.add_child(_grid(ACH, "res://assets/images/fanclub/achievements/ach-%02d.png", true))

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
	v.custom_minimum_size = Vector2(310, 470)
	var tex := TextureRect.new()
	if ResourceLoader.exists(path):
		tex.texture = load(path)
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
	var close := Button.new()
	close.text = tr("ЗАКРЫТЬ")
	close.position = Vector2(60, 990)
	close.size = Vector2(600, 56)
	close.pressed.connect(func() -> void: layer.queue_free())
	box.add_child(close)
