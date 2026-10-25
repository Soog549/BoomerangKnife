extends Control

## Главное меню: общий список разделов, внутри — под-кнопки.
## Разделы: ИГРАТЬ / ПЕРСОНАЖ / ЛИДЕРЫ И НАГРАДЫ / МАГАЗИН / НАСТРОЙКИ.

const MENU_VIEWS := {
	"root": [
		["sub", "play", "ИГРАТЬ"],
		["sub", "character", "ПЕРСОНАЖ"],
		["sub", "rewards", "ЛИДЕРЫ И НАГРАДЫ"],
		["go", "res://scenes/shop.tscn", "МАГАЗИН"],
		["go", "res://scenes/my_game.tscn", "МОЯ ИГРА"],
		["go", "res://scenes/collection.tscn", " КОЛЛЕКЦИЯ"],
		["go", "res://scenes/settings.tscn", "НАСТРОЙКИ"],
		["quit", "", "ВЫХОД"],
	],
	"play": [
		["go", "res://scenes/game.tscn", "КЛАССИКА"],
		["go", "res://scenes/endless.tscn", "БЕСКОНЕЧНЫЙ"],
		["go", "res://scenes/duel.tscn", "ДУЭЛЬ"],
		["go", "res://scenes/mob_arena.tscn", "АРЕНА (МОБЫ)"],
		["go", "res://scenes/td.tscn", "ТД (ПРОТО)"],
		["back", "", "НАЗАД"],
	],
	"character": [
		["go", "res://scenes/profile.tscn", "ПРОФИЛЬ"],
		["go", "res://scenes/loadout.tscn", "ЭКИПИРОВКА"],
		["go", "res://scenes/inventory.tscn", "ИНВЕНТАРЬ"],
		["go", "res://scenes/glyphs.tscn", "ГЛИФЫ"],
		["back", "", "НАЗАД"],
	],
	"rewards": [
		["go", "res://scenes/leaderboard.tscn", "ЛИДЕРЫ И ТУРНИР"],
		["go", "res://scenes/achievements.tscn", "ДОСТИЖЕНИЯ"],
		["go", "res://scenes/objectives.tscn", "ЦЕЛИ"],
		["go", "res://scenes/daily_rewards.tscn", "ЕЖЕДНЕВНАЯ НАГРАДА"],
		["back", "", "НАЗАД"],
	],
}

@onready var high_score_label: Label = $HighScoreLabel
@onready var wallet_label: Label = $WalletLabel
@onready var menu_list: VBoxContainer = $MenuList

var _view := "root"

func _ready() -> void:
	AudioManager.play("click")
	_apply_pack_bg()
	_show_splash()
	_build_profile_panel()
	AudioManager.play_music("menu")
	Achievements.check_all()
	GameState.apply_orientation()
	# Яндекс Игры: кнопка «выход» не работает в iframe — прячем на web
	_build_view("root")
	high_score_label.text = tr("РЕКОРД: %d") % GameState.high_score
	wallet_label.text = tr("Монеты: %d") % GameState.coins
	GameState.coins_changed.connect(func(total): if is_instance_valid(wallet_label): wallet_label.text = tr("Монеты: %d") % total)
	GameState.stats_changed.connect(func(): if is_instance_valid(high_score_label): high_score_label.text = tr("РЕКОРД: %d") % GameState.high_score)
	AdService.hide_banner()
	# Яндекс Игры: LoadingAPI.ready() — главное меню готово к взаимодействию
	YandexSDK.mark_ready()
	# Автопоказ ежедневной награды (если доступна) — дружелюбное напоминание
	if GameState.can_claim_daily():
		get_tree().call_deferred("change_scene_to_file", "res://scenes/daily_rewards.tscn")

func _build_profile_panel() -> void:
	notch_shift()
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 54)
	panel.custom_minimum_size = Vector2(330, 84)
	add_child(panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	panel.add_child(hb)
	var av := TextureRect.new()
	var p := "res://assets/images/avatars/avatar_%d.png" % GameState.avatar
	if ResourceLoader.exists(p):
		av.texture = load(p)
	av.custom_minimum_size = Vector2(68, 68)
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(av)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 3)
	hb.add_child(vb)
	var lvl := Label.new()
	lvl.text = "УРОВЕНЬ %d" % GameState.player_level
	lvl.add_theme_font_size_override("font_size", 18)
	vb.add_child(lvl)
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.value = GameState.player_xp % 100
	bar.custom_minimum_size = Vector2(0, 14)
	bar.show_percentage = false
	vb.add_child(bar)
	var cls := Label.new()
	cls.text = str(GameState.current_skin().get("label", "—"))
	cls.add_theme_font_size_override("font_size", 14)
	vb.add_child(cls)

func _show_splash() -> void:
	var p := "res://assets/images/packs/%s/splash.png" % GameState.style_pack
	if not ResourceLoader.exists(p):
		p = "res://assets/images/ui/splash-hd-1440x2560.png"
	if not ResourceLoader.exists(p):
		return
	var s := TextureRect.new()
	s.texture = load(p)
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(s)
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(s, "modulate:a", 0.0, 0.6)
	tw.tween_callback(s.queue_free)

func _build_view(view: String) -> void:
	_view = view
	for child in menu_list.get_children():
		child.queue_free()
	var items: Array = MENU_VIEWS.get(view, [])
	if items.is_empty():
		return
	for item: Array in items:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 64)
		btn.text = item[2]
		match item[0]:
			"sub":
				var target: String = item[1]
				btn.pressed.connect(func(): _build_view(target))
			"go":
				var path: String = item[1]
				btn.pressed.connect(func(): _go(path))
			"back":
				btn.pressed.connect(func(): _build_view("root"))
			"quit":
				btn.pressed.connect(_on_quit_pressed)
				if YandexSDK.is_web:
					btn.visible = false
		menu_list.add_child(btn)

func _go(path: String) -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file(path)

func _on_quit_pressed() -> void:
	AudioManager.play("click")
	if YandexSDK.is_web:
		return
	get_tree().quit()

func notch_shift() -> void:
	COINS_TABLO_build()
	for n in ["HighScoreLabel", "WalletLabel"]:
		var l := get_node_or_null(n)
		if l != null:
			l.visible = false
	return

	for n in ["HighScoreLabel", "WalletLabel"]:
		var l := get_node_or_null(n)
		if l != null:
			l.position.y += 40.0

func COINS_TABLO_build() -> void:
	var lvl := Label.new()
	lvl.name = "TABLO"
	lvl.position = Vector2(360, 54)
	lvl.size = Vector2(344, 84)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lvl.add_theme_font_size_override("font_size", 18)
	lvl.text = "Монеты: %d\nРекорд: %d\nУровень: %d" % [GameState.coins, GameState.high_score, GameState.player_level]
	add_child(lvl)

func _apply_pack_bg() -> void:
	var bg := get_node_or_null("Background")
	var p := "res://assets/images/packs/%s/bg.png" % GameState.style_pack
	if bg != null and ResourceLoader.exists(p):
		bg.texture = load(p)
		if bg is TextureRect:
			bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
