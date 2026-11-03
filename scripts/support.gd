extends Control

const FAQ := [
	["Как бросать нож?", "Коснись цели — нож летит и возвращается. Свайп двигает персонажа."],
	["Как сменить класс?", "Настройки → КЛАСС (стрелки). В профиле можно выбрать образ."],
	["Как продолжить забег?", "В меню появится «ПРОДОЛЖИТЬ: <режим>», либо на экране перед раундом."],
	["Где сохраняется прогресс?", "Автоматически после каждой волны и уровня. Настройки → СОХРАНИТЬ ПРОФИЛЬ."],
	["Не приходят монеты за рекламу", "Проверь лимит на сегодня — в магазине показан таймер сброса."],
	["Как сменить стиль графики?", "Настройки → СТИЛЬ. 19 стилей, превью показывает выбранный."],
]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = GameState.ui_bg_color()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vp: Vector2 = get_viewport_rect().size
	var sc := ScrollContainer.new()
	sc.position = Vector2(28, 30)
	sc.size = Vector2(vp.x - 56, vp.y - 150)
	add_child(sc)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(vp.x - 56, 0)
	vb.add_theme_constant_override("separation", 12)
	sc.add_child(vb)

	var title := Label.new()
	title.text = tr("ПОДДЕРЖКА · ЧАСТЫЕ ВОПРОСЫ")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", GameState.accent())
	vb.add_child(title)

	for qa in FAQ:
		var q := Label.new()
		q.text = "• " + str(qa[0])
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.add_theme_font_size_override("font_size", 16)
		q.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		vb.add_child(q)
		var a := Label.new()
		a.text = "   " + str(qa[1])
		a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		a.add_theme_font_size_override("font_size", 14)
		a.add_theme_color_override("font_color", Color(0.82, 0.88, 0.96))
		vb.add_child(a)

	var tg := Label.new()
	tg.text = tr("Сообщество Яндекс Игр: Telegram @VGSnaPorohe")
	tg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tg.custom_minimum_size = Vector2(0, 48)
	tg.add_theme_color_override("font_color", Color(0.6, 0.9, 0.75))
	vb.add_child(tg)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2(28, vp.y - 96)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/settings.tscn"))
	add_child(back)
