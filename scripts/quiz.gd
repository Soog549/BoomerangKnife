extends Control

## Викторина о игре (как «сквиз» для зрителей/игроков). 5 вопросов, награда за 4+.

const QS := [
	{"q": "Сколько классов в игре?", "a": ["23", "33", "43"], "ok": 1},
	{"q": "Что возвращается к хозяину?", "a": ["Щит", "Бумеранг-нож", "Копьё"], "ok": 1},
	{"q": "Сколько стилей графики?", "a": ["10", "19", "25"], "ok": 1},
	{"q": "Что даёт Милосердие в конце локации?", "a": ["Монеты", "Кристаллы", "Осколки"], "ok": 1},
	{"q": "Кто компаньон за 25 кристаллов?", "a": ["Скит", "Аврора", "Тень"], "ok": 2},
]

var idx := 0
var correct := 0
var done := false
var vb: VBoxContainer


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var vp: Vector2 = get_viewport_rect().size
	vb = VBoxContainer.new()
	vb.position = Vector2(32, 40)
	vb.size = Vector2(vp.x - 64, vp.y - 160)
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)
	var dots := Label.new()
	dots.name = "ProgressDots"
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.position = Vector2(0, vp.y - 320)
	dots.size = Vector2(vp.x, 40)
	dots.add_theme_font_size_override("font_size", 26)
	dots.add_theme_color_override("font_color", Color(0.45, 0.75, 0.9))
	add_child(dots)
	var hint := Label.new()
	hint.text = tr("Выбери правильный ответ · награда за 4+ из 5")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, vp.y - 200)
	hint.size = Vector2(vp.x, 30)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 0.85))
	add_child(hint)
	_render()


func _render() -> void:
	for c in vb.get_children():
		c.queue_free()
	var pd := get_node_or_null("ProgressDots")
	if pd is Label:
		var s := ""
		for i in QS.size():
			s += ("●" if i < idx else ("◉" if i == idx else "○")) + "  "
		(pd as Label).text = s
	var vp: Vector2 = get_viewport_rect().size
	var t := Label.new()
	t.text = "ВИКТОРИНА · ВОПРОС %d/%d" % [mini(idx + 1, QS.size()), QS.size()]
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(t)

	if done:
		var r := Label.new()
		r.text = "Правильно: %d из %d" % [correct, QS.size()]
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.add_theme_font_size_override("font_size", 22)
		vb.add_child(r)
		var rew := Label.new()
		rew.text = "+5 кристаллов!" if correct >= 4 else "Попробуй ещё — нужно 4 правильных"
		rew.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rew.add_theme_color_override("font_color", Color(1, 0.86, 0.45))
		vb.add_child(rew)
		var again := Button.new()
		again.text = "ЕЩЁ РАЗ"
		again.custom_minimum_size = Vector2(0, 52)
		again.pressed.connect(func() -> void:
			idx = 0
			correct = 0
			done = false
			_render())
		vb.add_child(again)
		return

	var q: Dictionary = QS[idx]
	var ql := Label.new()
	ql.text = str(q["q"])
	ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ql.add_theme_font_size_override("font_size", 18)
	vb.add_child(ql)

	var answers: Array = q["a"]
	for i in answers.size():
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, str(answers[i])]
		b.custom_minimum_size = Vector2(0, 56)
		var pick: int = i
		b.pressed.connect(func() -> void:
			if pick == int(q["ok"]):
				correct += 1
			idx += 1
			if idx >= QS.size():
				done = true
				if correct >= 4:
					GameState.crystals += 5
					GameState.save_settings()
			_render())
		vb.add_child(b)

	var back := Button.new()
	back.text = "НАЗАД"
	back.custom_minimum_size = Vector2(200, 48)
	back.position = Vector2(32, vp.y - 90)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/empire.tscn"))
	add_child(back)
