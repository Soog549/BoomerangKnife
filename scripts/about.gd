extends Control

const CHANGELOG := [
	"1.0.202 — второй шанс после поражения, индикаторы испытаний",
	"1.0.201 — сезонный пропуск и ежедневные испытания",
	"1.0.200 — ID игрока, сквозной трекер заданий",
	"1.0.199 — цвет брони, титулы, рамки профиля",
	"1.0.198 — акцент, размер кнопок, пресеты, КАК ИГРАТЬ",
	"1.0.196 — магазин: улучшение предметов, вкладка СЕТЫ",
	"1.0.188 — иконки снаряжения по качеству",
]

## Об игре: версия, ID игрока, ссылки, поддержка.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.10, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vp: Vector2 = get_viewport_rect().size
	var vb := VBoxContainer.new()
	vb.position = Vector2(32, 40)
	vb.size = Vector2(vp.x - 64, vp.y - 180)
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)

	var title := Label.new()
	title.text = "BOOMERANGKNIFE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	vb.add_child(title)

	var ver := Label.new()
	ver.text = tr("Версия: %s") % str(ProjectSettings.get_setting("application/config/version", "1.0"))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 15)
	vb.add_child(ver)

	var pid := Label.new()
	pid.text = tr("ID игрока: %s") % GameState.ensure_player_id()
	pid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pid.add_theme_font_size_override("font_size", 15)
	pid.add_theme_color_override("font_color", Color(0.75, 0.86, 1.0))
	vb.add_child(pid)

	var studio := Label.new()
	studio.text = tr("Студия ZWS · империя игр")
	studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	studio.add_theme_font_size_override("font_size", 14)
	studio.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	vb.add_child(studio)

	var cl := Label.new()
	cl.text = tr("ЧТО НОВОГО")
	cl.add_theme_font_size_override("font_size", 16)
	cl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	vb.add_child(cl)
	for line in CHANGELOG:
		var l2 := Label.new()
		l2.text = str(line)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l2.add_theme_font_size_override("font_size", 12)
		l2.add_theme_color_override("font_color", Color(0.8, 0.86, 0.95))
		vb.add_child(l2)

	for d in Economy.DONATIONS:
		var b := Button.new()
		b.text = "%s — %s" % [str(d.label), str(d.desc)]
		b.custom_minimum_size = Vector2(0, 46)
		b.add_theme_font_size_override("font_size", 13)
		var url := str(d.url)
		b.pressed.connect(func() -> void:
			AudioManager.play("click")
			OS.shell_open(url))
		vb.add_child(b)

	var back := Button.new()
	back.text = tr("НАЗАД")
	back.custom_minimum_size = Vector2(200, 52)
	back.position = Vector2(32, vp.y - 96)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/settings.tscn"))
	add_child(back)
