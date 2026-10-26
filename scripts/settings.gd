extends Control

const APP_VERSION := ""

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
]

func _ready() -> void:
	_add_footer()

func _add_footer() -> void:
	var vb := get_node_or_null("Center/VBox")
	if vb == null:
		return
	var pers := Button.new()
	pers.text = tr("ПЕРСОНАЛИЗАЦИЯ (моя игра)")
	pers.custom_minimum_size = Vector2(0, 48)
	pers.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/my_game.tscn"))
	vb.add_child(pers)
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
