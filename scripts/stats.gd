extends Control
## ПРОФИЛЬ ИГРОКА — персональная статистика и достижения. Дип-Про, 2026-10-24.

const ACH_NAMES := {
	"first_blood": "Первая кровь", "wave5": "Волна 5", "wave10": "Волна 10",
	"combo5": "Комбо x5", "combo10": "Комбо x10", "no_damage": "Без урона",
	"boss1": "Первый босс", "collector": "Коллекционер", "legendary": "Ключ Разлома",
	"coins100": "100 монет", "shield_master": "Щит-мастер", "wave20": "Оператор",
}

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.11, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var t := Label.new()
	t.text = tr("ПРОФИЛЬ ИГРОКА")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 30)
	t.position = Vector2(0, 16)
	t.size = Vector2(720, 38)
	add_child(t)

	var sc := ScrollContainer.new()
	sc.position = Vector2(40, 70)
	sc.size = Vector2(640, 1000)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(640, 0)
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)

	var skin: Dictionary = GameState.current_skin()
	var names: Array = []
	for id in GameState.arena_ach:
		if ACH_NAMES.has(id):
			names.append(ACH_NAMES[id])

	v.add_child(_row(tr("Монеты"), "%d" % GameState.coins))
	v.add_child(_row(tr("Реликвии"), "%d" % GameState.relics_total))
	v.add_child(_row(tr("Постоянные ножи"), "%d" % GameState.extra_knives))
	v.add_child(_row(tr("Ачивки"), "%d / 12" % GameState.arena_ach.size()))
	v.add_child(_row(tr("Скин"), str(skin.get("label", "—"))))
	v.add_child(_row(tr("Аватар"), "#%d" % (GameState.avatar + 1)))
	v.add_child(_row(tr("Рекорд"), "%d" % GameState.high_score))
	v.add_child(_row(tr("Собрано реликвий (всего)"), "%d" % GameState.relics_total))

	var h := Label.new()
	h.text = tr("ДОСТИЖЕНИЯ")
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color(0.6, 0.95, 0.8))
	v.add_child(h)
	if names.is_empty():
		var e := Label.new()
		e.text = tr("Пока нет — играй в Арене!")
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(e)
	else:
		for n in names:
			var l := Label.new()
			l.text = "• " + tr(str(n))
			l.add_theme_font_size_override("font_size", 17)
			v.add_child(l)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.position = Vector2(60, 1120)
	back.size = Vector2(600, 56)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/empire.tscn"))
	add_child(back)

func _row(label: String, value: String) -> Control:
	var hb := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 19)
	hb.add_child(l)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 19)
	val.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	hb.add_child(val)
	return hb
