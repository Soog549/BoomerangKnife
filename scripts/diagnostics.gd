extends Control
## ДИАГНОСТИКА В ИГРЕ: самопроверка, телеметрия, экспорт отчёта.

var _out: RichTextLabel
var _info: Label


func _ready() -> void:
	_add_device_fit_block()
	AudioManager.play("click")
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.10, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "ДИАГНОСТИКА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.position = Vector2(0, 20)
	title.size = Vector2(720, 40)
	add_child(title)

	_info = Label.new()
	_info.position = Vector2(30, 70)
	_info.size = Vector2(660, 90)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_theme_font_size_override("font_size", 15)
	add_child(_info)

	_out = RichTextLabel.new()
	_out.position = Vector2(30, 170)
	_out.size = Vector2(660, 760)
	_out.bbcode_enabled = false
	_out.scroll_active = true
	_out.add_theme_font_size_override("normal_font_size", 14)
	add_child(_out)

	var vb := VBoxContainer.new()
	vb.position = Vector2(60, 950)
	vb.size = Vector2(600, 0)
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)
	_btn(vb, "САМОПРОВЕРКА", _self_check)
	_btn(vb, "ЭКСПОРТ ОТЧЁТА", _export)
	_btn(vb, "СБРОС ТЕЛЕМЕТРИИ", _reset)
	_btn(vb, "НАЗАД", func() -> void: get_tree().change_scene_to_file("res://scenes/settings.tscn"))

	_refresh()
	_self_check()


func _btn(parent: VBoxContainer, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(600, 52)
	b.pressed.connect(cb)
	parent.add_child(b)


func _refresh() -> void:
	var s := Telemetry.summary()
	_info.text = "Версия: %s\nПлатформа: %s\nСессия: %d c   ·   событий: %d   ·   ошибок: %d" % [
		str(ProjectSettings.get_setting("application/config/version", "dev")),
		OS.get_name(), int(s.session_sec), int(s.events), int(s.errors)]


func _self_check() -> void:
	var lines: Array[String] = []
	var ok := 0
	var fail := 0

	var add := func(name: String, good: bool) -> void:
		lines.append(("✔ " if good else "✘ ") + name)
		if good:
			ok += 1
		else:
			fail += 1
			Telemetry.error("selfcheck", {"check": name})

	var styles := ["base", "imperial", "epic", "space", "anime", "eurasia", "norse", "kids", "cyber", "dark"]
	add.call("Стиль выбран корректно", str(GameState.style_pack) in styles)
	add.call("Целей 509", Objectives.all().size() == 509)
	add.call("Миров 8", Worlds.LIST.size() == 8)
	add.call("Глифов ≥5", Economy.GLYPHS.size() >= 5)

	var runes_ok := true
	for i in range(1, 13):
		if not ResourceLoader.exists("res://assets/images/glyphs/rune-%02d.png" % i):
			runes_ok = false
	add.call("Руны 12", runes_ok)

	var packs_ok := true
	for st in styles:
		for f in ["mob-1.png", "tower-1.png", "knife-1.png", "shield-1.png", "bg.jpg"]:
			if not ResourceLoader.exists("res://assets/images/packs/%s/%s" % [st, f]):
				packs_ok = false
	add.call("Паки (моб/башня/нож/щит/фон)", packs_ok)

	add.call("Сцена меню доступна", ResourceLoader.exists("res://scenes/main_menu.tscn"))
	add.call("Телеметрия активна", Telemetry != null)
	add.call("Ассет-манифест на месте", ResourceLoader.exists("res://assets/manifest.json"))

	lines.append("")
	lines.append("ИТОГО: OK %d · FAIL %d" % [ok, fail])
	_out.text = "\n".join(lines)
	_refresh()


func _export() -> void:
	var p := Telemetry.flush_to_disk()
	var r := Telemetry.export_report()
	_out.text += "\n\nЭкспорт: %s\nОтчёт: %s" % [p, r]


func _reset() -> void:
	Telemetry._events.clear()
	Telemetry._errors = 0
	_out.text = "Телеметрия очищена."
	_refresh()


func _add_device_fit_block() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var box := VBoxContainer.new()
	box.name = "DeviceFitBox"
	box.position = Vector2(24.0, vp.y - 210.0)
	box.custom_minimum_size = Vector2(vp.x - 48.0, 0)
	add_child(box)

	var info := Label.new()
	info.name = "DeviceInfo"
	info.text = DeviceFit.summary()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 14)
	box.add_child(info)

	var res := Label.new()
	res.name = "FitResult"
	res.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	res.add_theme_font_size_override("font_size", 14)
	res.add_theme_color_override("font_color", Color(0.6, 0.95, 0.75))
	box.add_child(res)

	var b := Button.new()
	b.text = tr("ПОДОГНАТЬ ПОД ЭКРАН")
	b.custom_minimum_size = Vector2(0, 48)
	b.pressed.connect(func() -> void:
		var r: Dictionary = DeviceFit.fit(get_tree().current_scene)
		res.text = tr("Подгонка: элементов за краем %d, сдвинуто %d") % [int(r["clipped"]), int(r["moved"])]
		info.text = DeviceFit.summary()
		AudioManager.play("click"))
	box.add_child(b)
