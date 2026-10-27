extends Control
## МОЯ ИГРА — персонализация: скин, сложность, управление, стик, авто-прицел, звук, язык.
## ДиП-Флеш-17, 2026-10-21.

const DIFFS := ["easy", "normal", "hard"]
const DIFF_NAMES := {"easy": "Лёгкая", "normal": "Обычная", "hard": "Хард"}
const CTRL := ["auto", "touch", "keyboard"]
const CTRL_NAMES := {"auto": "Авто", "touch": "Касание", "keyboard": "Клавиатура"}
const JOYS := [0.8, 1.0, 1.25, 1.5]
const LANGS := ["ru", "en"]

var box: VBoxContainer

func _ready() -> void:
	AudioManager.play("click")
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.12, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = tr("МОЯ ИГРА")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.position = Vector2(0, 24)
	title.size = Vector2(720, 40)
	add_child(title)
	var sc := ScrollContainer.new()
	sc.position = Vector2(60, 80)
	sc.size = Vector2(600, 1020)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(600, 0)
	box.add_theme_constant_override("separation", 10)
	sc.add_child(box)
	_rebuild()
	var back := Button.new()
	back.text = "НАЗАД"
	back.position = Vector2(60, 1120)
	back.size = Vector2(600, 56)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(back)

const STYLES := ["base", "imperial", "epic", "space", "anime", "eurasia", "norse", "kids", "cyber", "dark"]

func _row(label: String, value: String, cb: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 20)
	h.add_child(l)
	var b := Button.new()
	b.text = value
	b.custom_minimum_size = Vector2(220, 48)
	b.pressed.connect(cb)
	h.add_child(b)
	box.add_child(h)

func _rebuild() -> void:
	for c in box.get_children():
		c.queue_free()
	var skin: Dictionary = GameState.current_skin()
	_row(tr("Скин"), str(skin.get("label", "—")), _next_skin)
	_row(tr("Стиль"), GameState.style_pack.to_upper(), _next_style)
	_row(tr("Сложность"), DIFF_NAMES.get(GameState.difficulty, "—"), _next_diff)
	_row(tr("Управление"), CTRL_NAMES.get(GameState.control_mode, "—"), _next_ctrl)
	_row(tr("Размер стика"), "%d%%" % int(GameState.joy_scale * 100.0), _next_joy)
	_row(tr("Авто-прицел"), "ВКЛ" if GameState.auto_aim else "ВЫКЛ", _toggle_aim)
	_row(tr("Дроп с мобов"), "ВКЛ" if GameState.arena_drops else "ВЫКЛ", _toggle_drops)
	_row(tr("Режим выживания"), "ВКЛ" if GameState.survival_mode else "ВЫКЛ", _toggle_survival)
	_row(tr("Музыка"), "%d%%" % int(GameState.music_volume * 100.0), _music_plus)
	_row(tr("Трек"), tr("по скину") if GameState.music_track < 1 else str(GameState.music_track), _next_track)
	_row(tr("Звуки"), "%d%%" % int(GameState.sfx_volume * 100.0), _sfx_plus)
	_row(tr("Язык"), GameState.locale.to_upper(), _next_lang)

func _save() -> void:
	GameState.save_settings()
	_rebuild()

func _next_skin() -> void:
	var owned: Array = GameState.owned_skins
	if owned.is_empty():
		owned = [0]
	var idx: int = owned.find(GameState.selected_skin)
	GameState.selected_skin = int(owned[(idx + 1) % owned.size()])
	_save()

func _next_diff() -> void:
	var i: int = DIFFS.find(GameState.difficulty)
	GameState.difficulty = DIFFS[(i + 1) % DIFFS.size()]
	_save()

func _next_ctrl() -> void:
	var i: int = CTRL.find(GameState.control_mode)
	if i < 0:
		i = 0
	GameState.control_mode = CTRL[(i + 1) % CTRL.size()]
	_save()

func _next_joy() -> void:
	var i: int = JOYS.find(GameState.joy_scale)
	if i < 0:
		i = 1
	GameState.joy_scale = JOYS[(i + 1) % JOYS.size()]
	_save()

func _toggle_aim() -> void:
	GameState.auto_aim = not GameState.auto_aim
	_save()

func _toggle_drops() -> void:
	GameState.arena_drops = not GameState.arena_drops
	_save()

func _toggle_survival() -> void:
	GameState.survival_mode = not GameState.survival_mode
	_save()

func _music_plus() -> void:
	GameState.music_volume = fmod(GameState.music_volume + 0.2, 1.2)
	if GameState.music_volume > 1.0:
		GameState.music_volume = 0.0
	# громкость читается из GameState в AudioManager
	_save()

func _sfx_plus() -> void:
	GameState.sfx_volume = fmod(GameState.sfx_volume + 0.2, 1.2)
	if GameState.sfx_volume > 1.0:
		GameState.sfx_volume = 0.0
	# громкость читается из GameState в AudioManager
	_save()

func _next_lang() -> void:
	var i: int = LANGS.find(GameState.locale)
	if i < 0:
		i = 0
	GameState.locale = LANGS[(i + 1) % LANGS.size()]
	_save()

func _next_track() -> void:
	GameState.music_track += 1
	if GameState.music_track > 20:
		GameState.music_track = -1
	AudioManager.play_skin_music()
	_save()


func _next_style() -> void:
	var i: int = STYLES.find(GameState.style_pack)
	GameState.style_pack = STYLES[(i + 1) % STYLES.size()]
	_save()
