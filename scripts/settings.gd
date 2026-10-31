extends Control

const APP_VERSION := ""
const STYLE_ORDER := ["base", "imperial", "epic", "space", "anime", "eurasia", "norse", "kids", "cyber", "dark", "icon-flat", "noir", "holiday", "wuxia", "biomech", "arcade"]
var _row_values: Array = []
const DIFF_ORDER := ["easy", "normal", "hard", "survival"]

@onready var volume_label: Label = $Center/VBox/VolumeLabel
@onready var volume_slider: HSlider = $Center/VBox/VolumeSlider
@onready var music_label: Label = $Center/VBox/MusicLabel
@onready var music_slider: HSlider = $Center/VBox/MusicSlider
@onready var sfx_label: Label = $Center/VBox/SFXLabel
@onready var sfx_slider: HSlider = $Center/VBox/SFXSlider
@onready var shake_toggle: CheckButton = $Center/VBox/ShakeToggle
@onready var particles_toggle: CheckButton = $Center/VBox/ParticlesToggle
@onready var landscape_toggle: CheckButton = $Center/VBox/LandscapeToggle
@onready var name_edit: LineEdit = $Center/VBox/NameEdit
@onready var name_hint: Label = $Center/VBox/NameHint
@onready var yandex_auth_label: Label = $Center/VBox/YandexAuthLabel
@onready var yandex_auth_button: Button = $Center/VBox/YandexAuthButton
@onready var lang_option: OptionButton = $Center/VBox/LanguageOption
@onready var avatar_option: OptionButton = $Center/VBox/AvatarRow/AvatarOption
@onready var avatar_preview: TextureRect = $Center/VBox/AvatarRow/AvatarPreview

const AVATAR_TYPES := [
	"Воин",
	"Разбойник",
	"Маг",
	"Лучник",
	"Рыцарь",
	"Берсерк",
	"Ассасин",
	"Паладин",
	"Друид",
	"Монах",
	"Пират",
	"Самурай",
	"Ниндзя",
	"Викинг",
	"Стрелок",
	"Алхимик",
	"Некромант",
	"Инженер",
	"Охотник",
	"Шаман",
	"Чемпион",
	"Принцесса",
	"Кулачный",
	"Кинетик",
	"Пиромант",
	"Криомант",
	"Псайкер",
	"Телекинетик",
	"Мастер КИ",
	"Аурат",
	"Гравитоник",
	"Симбиот",
	"Эмпат",
]
const AVATAR_PATHS := [
	"res://assets/images/avatars/avatar_0.png",
	"res://assets/images/avatars/avatar_1.png",
	"res://assets/images/avatars/avatar_2.png",
	"res://assets/images/avatars/avatar_3.png",
	"res://assets/images/avatars/avatar_4.png",
	"res://assets/images/avatars/avatar_5.png",
	"res://assets/images/avatars/avatar_6.png",
	"res://assets/images/avatars/avatar_7.png",
	"res://assets/images/avatars/avatar_8.png",
	"res://assets/images/avatars/avatar_9.png",
	"res://assets/images/avatars/avatar_10.png",
	"res://assets/images/avatars/avatar_11.png",
	"res://assets/images/avatars/avatar_12.png",
	"res://assets/images/avatars/avatar_13.png",
	"res://assets/images/avatars/avatar_14.png",
	"res://assets/images/avatars/avatar_15.png",
	"res://assets/images/avatars/avatar_16.png",
	"res://assets/images/avatars/avatar_17.png",
	"res://assets/images/avatars/avatar_18.png",
	"res://assets/images/avatars/avatar_19.png",
	"res://assets/images/avatars/avatar_20.png",
	"res://assets/images/avatars/avatar_21.png",
]

func _ready() -> void:
	_normalize_layout()
	_add_personal_rows()
	_add_footer()

func _normalize_layout() -> void:
	var center := get_node_or_null("Center")
	if center is Control:
		(center as Control).position = Vector2(UIKit.M, 36)
		(center as Control).size = Vector2(UIKit.W - UIKit.M * 2.0, UIKit.H - 72.0)
	var vb := get_node_or_null("Center/VBox")
	if vb is Control:
		(vb as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bb := get_node_or_null("Center/VBox/BackButton")
	if bb is Button:
		var b := bb as Button
		b.get_parent().remove_child(b)
		add_child(b)
		b.position = Vector2(UIKit.M, UIKit.H - UIKit.M - UIKit.BTN_H)
		b.size = Vector2(200.0, UIKit.BTN_H)


func _add_personal_rows() -> void:
	_row_values.clear()
	var vb := get_node_or_null("Center/VBox")
	if vb == null:
		return
	vb.add_child(_prow(tr("КЛАСС"), AVATAR_TYPES[clampi(GameState.avatar, 0, AVATAR_TYPES.size() - 1)], _cycle_class))
	vb.add_child(_prow(tr("СТИЛЬ"), GameState.style_pack.to_upper(), _cycle_style))
	vb.add_child(_prow(tr("СЛОЖНОСТЬ"), tr(GameState.difficulty.to_upper()), _cycle_diff))
	vb.add_child(_prow(tr("УПРАВЛЕНИЕ"), tr(GameState.control_mode.to_upper()), _cycle_mode))
	vb.add_child(_prow(tr("АВТОПРИЦЕЛ"), tr("ВКЛ") if GameState.auto_aim else tr("ВЫКЛ"), _cycle_aim))
	vb.add_child(_prow(tr("ДРОП"), tr("ВКЛ") if GameState.arena_drops else tr("ВЫКЛ"), _cycle_drop))
	vb.add_child(_prow(tr("ВЫЖИВАНИЕ"), tr("ВКЛ") if GameState.survival_mode else tr("ВЫКЛ"), _cycle_surv))
	vb.add_child(_prow(tr("КНОПКИ"), tr("СПРАВА") if GameState.btn_side == "right" else tr("СЛЕВА"), _cycle_btn_side))
	vb.add_child(_prow(tr("СКИН"), str(GameState.current_skin().get("label", "—")), _cycle_skin))
	vb.add_child(_profile_row())


func _profile_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var exp_b := Button.new()
	exp_b.text = tr("СОХРАНИТЬ ПРОФИЛЬ")
	exp_b.custom_minimum_size = Vector2(0, 44)
	exp_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exp_b.pressed.connect(func() -> void:
		var p := GameState.export_profile_to_downloads()
		var msg := tr("Профиль сохранён") if p != "" else tr("Не удалось сохранить")
		_show_toast(msg + ((": " + p) if p != "" else "")))
	row.add_child(exp_b)
	var imp_b := Button.new()
	imp_b.text = tr("ЗАГРУЗИТЬ")
	imp_b.custom_minimum_size = Vector2(0, 44)
	imp_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	imp_b.pressed.connect(func() -> void:
		var dl := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
		var path := dl.path_join("boomerangknife_profile.cfg") if dl != "" else "user://bk_profile_backup.cfg"
		if GameState.import_profile(path):
			_show_toast(tr("Профиль загружен"))
			get_tree().reload_current_scene()
		else:
			_show_toast(tr("Файл профиля не найден")))
	row.add_child(imp_b)
	return row


func _show_toast(txt: String) -> void:
	var l := Label.new()
	l.text = txt
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	l.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	l.offset_top = -120
	l.offset_bottom = -40
	l.offset_left = -400
	l.offset_right = 400
	add_child(l)
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(l):
			l.queue_free())


func _prow(title: String, value: String, cb: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(180, 0)
	row.add_child(l)
	var prev_b := Button.new()
	prev_b.text = "◀"
	prev_b.custom_minimum_size = Vector2(56, 44)
	prev_b.pressed.connect(func() -> void: cb.call(-1))
	row.add_child(prev_b)
	var v := Label.new()
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	var next_b := Button.new()
	next_b.text = "▶"
	next_b.custom_minimum_size = Vector2(56, 44)
	next_b.pressed.connect(func() -> void: cb.call(1))
	row.add_child(next_b)
	_row_values.append(v)
	return row


func _cycle_class(d: int) -> void:
	var owned: Array = GameState.owned_avatars
	if owned.is_empty():
		owned = [0]
	var idx: int = owned.find(GameState.avatar)
	GameState.avatar = int(owned[(idx + d + owned.size()) % owned.size()])
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild_settings()


func _cycle_style(d: int) -> void:
	var i: int = STYLE_ORDER.find(GameState.style_pack)
	GameState.style_pack = STYLE_ORDER[(i + d + STYLE_ORDER.size()) % STYLE_ORDER.size()]
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild_settings()


func _cycle_diff(d: int) -> void:
	var i: int = DIFF_ORDER.find(GameState.difficulty)
	GameState.difficulty = DIFF_ORDER[(i + d + DIFF_ORDER.size()) % DIFF_ORDER.size()]
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild_settings()


func _cycle_skin(d: int) -> void:
	var n: int = GameState.SKINS.size()
	if n <= 0:
		return
	GameState.selected_skin = (GameState.selected_skin + d + n) % n
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild_settings()


func _cycle_btn_side(d: int) -> void:
	GameState.btn_side = "right" if GameState.btn_side == "left" else "left"
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild_settings()


func _rebuild_settings() -> void:
	if _row_values.size() >= 9:
		_row_values[0].text = AVATAR_TYPES[clampi(GameState.avatar, 0, AVATAR_TYPES.size() - 1)]
		_row_values[1].text = GameState.style_pack.to_upper()
		_row_values[2].text = tr(GameState.difficulty.to_upper())
		_row_values[3].text = GameState.control_mode.to_upper()
		_row_values[4].text = tr("ВКЛ") if GameState.auto_aim else tr("ВЫКЛ")
		_row_values[5].text = tr("ВКЛ") if GameState.arena_drops else tr("ВЫКЛ")
		_row_values[6].text = tr("ВКЛ") if GameState.survival_mode else tr("ВЫКЛ")
		_row_values[7].text = tr("СПРАВА") if GameState.btn_side == "right" else tr("СЛЕВА")
		_row_values[8].text = str(GameState.current_skin().get("label", "—"))


func _add_footer() -> void:
	var vb := get_node_or_null("Center/VBox")
	if vb == null:
		return
	var pers := Button.new()
	pers.text = tr("ПЕРСОНАЛИЗАЦИЯ (моя игра)")
	pers.custom_minimum_size = Vector2(0, 48)
	pers.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/my_game.tscn"))
	vb.add_child(pers)
	var diag := Button.new()
	diag.text = tr("ДИАГНОСТИКА")
	diag.custom_minimum_size = Vector2(0, 48)
	diag.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/diagnostics.tscn"))
	vb.add_child(diag)
	var ver := Label.new()
	var vstr: String = str(ProjectSettings.get_setting("application/config/version", "dev"))
	ver.text = tr("Версия %s") % vstr
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 14)
	ver.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	vb.add_child(ver)

	AudioManager.play("click")
	volume_slider.value = GameState.volume * 100.0
	music_slider.value = GameState.music_volume * 100.0
	sfx_slider.value = GameState.sfx_volume * 100.0
	shake_toggle.button_pressed = GameState.shake_enabled
	particles_toggle.button_pressed = GameState.particles_enabled
	landscape_toggle.button_pressed = GameState.landscape_mode
	# Переключение ориентации доступно только на Android (на десктопе/вебе — скрыто)
	landscape_toggle.visible = OS.get_name() == "Android"
	volume_label.text = tr("Общая: %d") % int(volume_slider.value)
	music_label.text = tr("Музыка: %d") % int(music_slider.value)
	sfx_label.text = tr("Звуки: %d") % int(sfx_slider.value)
	name_edit.text = GameState.player_name
	# Яндекс Игры: вход только по кнопке, гость — по умолчанию
	yandex_auth_label.visible = YandexSDK.is_web
	yandex_auth_button.visible = YandexSDK.is_web and not YandexSDK.is_signed_in()
	YandexSDK.player_refreshed.connect(_on_player_refreshed)
	_update_auth_status()
	for pair in L10N.LANGS:
		lang_option.add_item(pair[1])
	lang_option.selected = L10N.index_of(GameState.locale)
	for i in AVATAR_TYPES.size():
		avatar_option.add_item(tr(AVATAR_TYPES[i]))
	avatar_option.selected = GameState.avatar
	_update_avatar_preview()

func _on_player_refreshed(name: String, signed_in: bool) -> void:
	_update_auth_status()
	if signed_in and (GameState.player_name == tr("Игрок") or GameState.player_name.is_empty()):
		name_edit.text = GameState.player_name

func _update_auth_status() -> void:
	yandex_auth_button.visible = YandexSDK.is_web and not YandexSDK.is_signed_in()
	if YandexSDK.is_signed_in():
		yandex_auth_label.text = tr("Вошли как: %s") % GameState.player_name
	else:
		yandex_auth_label.text = tr("Гость")

func _on_yandex_auth_pressed() -> void:
	AudioManager.play("click")
	YandexSDK.request_login()

func _on_language_selected(index: int) -> void:
	AudioManager.play("click")
	L10N.apply_locale(L10N.LANGS[index][0])

func _update_avatar_preview() -> void:
	var idx := clampi(GameState.avatar, 0, AVATAR_PATHS.size() - 1)
	avatar_preview.texture = load(AVATAR_PATHS[idx])

func _on_avatar_selected(index: int) -> void:
	AudioManager.play("click")
	GameState.avatar = index
	GameState.save_settings()
	_update_avatar_preview()

func _on_volume_changed(value: float) -> void:
	GameState.volume = value / 100.0
	GameState.save_settings()
	volume_label.text = tr("Общая: %d") % int(value)
	AudioManager.update_volumes()
	AudioManager.play("click")

func _on_music_changed(value: float) -> void:
	GameState.music_volume = value / 100.0
	GameState.save_settings()
	music_label.text = tr("Музыка: %d") % int(value)
	AudioManager.update_volumes()

func _on_sfx_changed(value: float) -> void:
	GameState.sfx_volume = value / 100.0
	GameState.save_settings()
	sfx_label.text = tr("Звуки: %d") % int(value)
	AudioManager.update_volumes()
	AudioManager.play("click")

func _on_shake_toggled(on: bool) -> void:
	GameState.shake_enabled = on
	GameState.save_settings()
	AudioManager.play("click")

func _on_particles_toggled(on: bool) -> void:
	GameState.particles_enabled = on
	GameState.save_settings()
	AudioManager.play("click")

func _on_landscape_toggled(on: bool) -> void:
	GameState.landscape_mode = on
	GameState.save_settings()
	GameState.apply_orientation()
	AudioManager.play("click")

func _on_name_submitted(new_text: String) -> void:
	var trimmed := new_text.strip_edges()
	if trimmed.is_empty():
		trimmed = tr("Игрок")
	GameState.player_name = trimmed
	name_edit.text = trimmed
	name_hint.text = tr("Имя сохранено!")
	GameState.save_settings()
	AudioManager.play("click")

func _on_name_focus_exited() -> void:
	_on_name_submitted(name_edit.text)

func _on_back_pressed() -> void:
	_on_name_submitted(name_edit.text)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _cycle_mode(d: int) -> void:
	var modes := ["auto", "touch", "keyboard"]
	var i: int = modes.find(GameState.control_mode)
	GameState.control_mode = str(modes[(i + d + modes.size()) % modes.size()])
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild_settings()


func _cycle_aim(d: int) -> void:
	GameState.auto_aim = not GameState.auto_aim
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild_settings()


func _cycle_drop(d: int) -> void:
	GameState.arena_drops = not GameState.arena_drops
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild_settings()


func _cycle_surv(d: int) -> void:
	GameState.survival_mode = not GameState.survival_mode
	GameState.save_settings()
	AudioManager.play("click")
	_rebuild_settings()
