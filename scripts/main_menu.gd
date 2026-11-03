extends Control

## Главное меню: общий список разделов, внутри — под-кнопки.
## Разделы: ИГРАТЬ / ПЕРСОНАЖ / ЛИДЕРЫ И НАГРАДЫ / МАГАЗИН / НАСТРОЙКИ.

const MENU_VIEWS := {
	"root": [
		["sub", "empire", "◆ ИМПЕРИЯ"],
		["quit", "", "ВЫХОД"],
	],
	"empire": [
		["sub", "play", "◆ ИГРАТЬ"],
		["sub", "character", "◆ ПЕРСОНАЖ"],
		["sub", "rewards", "◆ ЛИДЕРЫ И НАГРАДЫ"],
		["go", "res://scenes/empire.tscn", "◆ МИРЫ И ХАБ"],
		["back", "", "НАЗАД"],
	],
	"play": [
		["go", "res://scenes/game.tscn", "◆ КАМПАНИЯ"],
		["go", "res://scenes/endless.tscn", "◆ ЗАЩИТА РУБЕЖА"],
		["go", "res://scenes/duel.tscn", "◆ ДУЭЛЬ"],
		["go", "res://scenes/mob_arena.tscn", "◆ АРЕНА (МОБЫ)"],
		["go", "res://scenes/td.tscn", "◆ ОБОРОНА"],
		["back", "", "НАЗАД"],
	],
	"character": [
		["go", "res://scenes/profile.tscn", "◆ ПРОФИЛЬ"],
		["go", "res://scenes/loadout.tscn", "◆ ЭКИПИРОВКА"],
		["go", "res://scenes/inventory.tscn", "◆ ИНВЕНТАРЬ"],
		["go", "res://scenes/glyphs.tscn", "◆ ГЛИФЫ"],
		["back", "", "НАЗАД"],
	],
	"rewards": [
		["go", "res://scenes/leaderboard.tscn", "◆ ЛИДЕРЫ И ТУРНИР"],
		["go", "res://scenes/achievements.tscn", "◆ ДОСТИЖЕНИЯ"],
		["go", "res://scenes/objectives.tscn", "◆ ЦЕЛИ"],
		["go", "res://scenes/daily_rewards.tscn", "◆ ЕЖЕДНЕВНАЯ НАГРАДА"],
		["go", "res://scenes/stats.tscn", "◆ СТАТИСТИКА"],
		["back", "", "НАЗАД"],
	],
}

@onready var high_score_label: Label = $HighScoreLabel
@onready var wallet_label: Label = $WalletLabel
@onready var menu_list: VBoxContainer = $MenuList

var _view := "root"

func _ready() -> void:
	_apply_style_bg()
	if not GameState.onboarding_done:
		get_tree().change_scene_to_file("res://scenes/onboarding.tscn")
		return
	AudioManager.play("click")
	_apply_pack_bg()
	_show_splash()
	_build_profile_panel()
	_add_bottom_nav()
	AudioManager.play_for_style(GameState.style_pack)
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
	if is_instance_valid(high_score_label):
		high_score_label.visible = false
		high_score_label.text = ""
	if is_instance_valid(wallet_label):
		wallet_label.visible = false
		wallet_label.text = ""



func _build_profile_panel() -> void:
	notch_shift()
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 54)
	panel.custom_minimum_size = Vector2(420, 132)
	add_child(panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	panel.add_child(hb)
	var av := TextureRect.new()
	var cfiles: Array = ["warrior", "rogue", "mage", "archer", "knight", "berserker", "assassin", "paladin", "druid", "monk", "pirate", "samurai", "ninja", "viking", "gunslinger", "alchemist", "necromancer", "engineer", "bounty_hunter", "shaman", "champion", "princess", "fist", "kinetic", "pyro", "cryo", "psion", "telekinetic", "kimaster", "aurate", "graviton", "symbiote", "empath"]
	var cf: String = str(cfiles[clampi(GameState.avatar, 0, cfiles.size() - 1)])
	var p := "res://assets/images/classes/%s.png" % cf
	if not ResourceLoader.exists(p):
		p = "res://assets/images/avatars/avatar_%d.png" % GameState.avatar
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
	bar.custom_minimum_size = Vector2(0, 8)
	bar.show_percentage = false
	vb.add_child(bar)
	var cls := Label.new()
	cls.text = "СКИН: " + str(GameState.current_skin().get("label", "—"))
	cls.add_theme_font_size_override("font_size", 14)
	vb.add_child(cls)
	if GameState.login_streak > 1:
		var st := Label.new()
		st.text = "СЕРИЯ: %d дн." % GameState.login_streak
		st.add_theme_font_size_override("font_size", 14)
		st.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		vb.add_child(st)
	var go_char := Button.new()
	go_char.text = "▸ ПЕРСОНАЖ"
	go_char.custom_minimum_size = Vector2(0, 34)
	go_char.pressed.connect(func(): _go("res://scenes/profile.tscn"))
	var coins_l := Label.new()
	coins_l.text = "МОНЕТЫ %d" % GameState.coins
	coins_l.add_theme_font_size_override("font_size", 14)
	coins_l.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	vb.add_child(coins_l)
	var ready: int = GameState.daily_ready_count()
	if ready > 0:
		var dot := Label.new()
		dot.text = "● " + tr("Испытания: %d готово") % ready
		dot.add_theme_font_size_override("font_size", 13)
		dot.add_theme_color_override("font_color", Color(0.55, 0.95, 0.65))
		vb.add_child(dot)
	vb.add_child(go_char)

func _show_splash() -> void:
	var p := "res://assets/images/packs/%s/splash.jpg" % GameState.style_pack
	if not ResourceLoader.exists(p):
		p = "res://assets/images/ui/splash-hd-1440x2560.png"
	if not ResourceLoader.exists(p):
		return
	var s := TextureRect.new()
	s.texture = load(p)
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
	# DEDUPE_NAV — эти разделы уже есть в нижней панели
	var bottom_nav_labels := ["ИМПЕРИЯ", "МАГАЗИН", "КОЛЛЕКЦИЯ", "НАСТРОЙКИ"]
	var items: Array = MENU_VIEWS.get(view, [])
	if items.is_empty():
		return
	if view == "root":
		# Фиксированный слот под «ПРОДОЛЖИТЬ» — кнопки ниже не смещаются
		var cont_box := VBoxContainer.new()
		cont_box.name = "ContinueBox"
		cont_box.custom_minimum_size = Vector2(0, 132)
		cont_box.add_theme_constant_override("separation", 6)
		menu_list.add_child(cont_box)
		var modes_with := GameState.modes_with_saves()
		while modes_with.size() > 2:
			modes_with.pop_front()
		for m in modes_with:
			var mode: String = str(m)
			var cont := Button.new()
			cont.custom_minimum_size = Vector2(0, 62)
			var summ: String = GameState.mode_summary(mode)
			cont.text = tr("ПРОДОЛЖИТЬ: %s") % GameState.mode_label(mode) + (("  ·  " + summ) if summ != "" else "")
			cont.add_theme_font_size_override("font_size", 17)
			cont.pressed.connect(func(): _continue_mode(mode))
			cont_box.add_child(cont)
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

const MODE_SCENES := ["game", "endless", "duel", "mob_arena", "td"]

func _go(path: String) -> void:
	AudioManager.play("click")
	for m in MODE_SCENES:
		if path.ends_with("/%s.tscn" % m):
			GameState.last_mode_scene = path
			GameState.save_settings()
			break
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
	return  # отключено: дубль статов
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
	var p := "res://assets/images/packs/%s/bg.jpg" % GameState.style_pack
	if bg != null and ResourceLoader.exists(p):
		bg.texture = load(p)
		if bg is TextureRect:
			bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


func _add_shop_corner() -> void:
	var b := Button.new()
	b.name = "ShopCorner"
	b.text = "🛒"
	b.custom_minimum_size = Vector2(64, 56)
	b.position = Vector2(UIKit.W - UIKit.M - 64.0, UIKit.M)
	b.tooltip_text = tr("МАГАЗИН")
	b.pressed.connect(func() -> void:
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://scenes/shop.tscn"))
	add_child(b)


func _continue_mode(mode: String) -> void:
	GameState.continue_mode = mode
	match mode:
		"campaign":
			_go("res://scenes/game.tscn")
		"td":
			_go("res://scenes/td.tscn")
		"duel":
			_go("res://scenes/duel.tscn")
		"survival_world":
			_go("res://scenes/survival.tscn")
		_:
			GameState.frontier_mode = mode == "frontier"
			GameState.rush_mode = mode == "rush"
			GameState.survival_arena = mode == "survival"
			GameState.last_mode_scene = "res://scenes/mob_arena.tscn"
			_go("res://scenes/mob_arena.tscn")


func _add_bottom_nav() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var bar := HBoxContainer.new()
	bar.name = "BottomNav"
	bar.add_theme_constant_override("separation", 6)
	bar.position = Vector2(16, vp.y - 92)
	bar.size = Vector2(vp.x - 32, 76)
	add_child(bar)

	var items := [
		["ИГРАТЬ", "res://scenes/empire.tscn"],
		["ГЕРОЙ", "res://scenes/profile.tscn"],
		["МАГАЗИН", "res://scenes/shop.tscn"],
		["ЕЩЁ", "res://scenes/settings.tscn"],
	]
	for it in items:
		var b := Button.new()
		b.text = tr(str(it[0]))
		b.custom_minimum_size = Vector2(0, 72)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 14)
		var path: String = str(it[1])
		b.pressed.connect(func() -> void:
			AudioManager.play("click")
			get_tree().change_scene_to_file(path))
		bar.add_child(b)
		if str(it[0]) == "МАГАЗИН" and GameState.daily_ready_count() > 0:
			var dot := Label.new()
			dot.text = "●"
			dot.add_theme_font_size_override("font_size", 18)
			dot.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			dot.position = Vector2(b.position.x + b.size.x - 18.0, b.position.y - 6.0)
			bar.add_child(dot)

func _apply_style_bg() -> void:
	var p := "res://assets/images/packs/%s/bg.jpg" % GameState.style_pack
	if not ResourceLoader.exists(p):
		return
	var tr := TextureRect.new()
	tr.texture = load(p)
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	move_child(tr, 0)
	hide_legacy_bg()


func hide_legacy_bg() -> void:
	for c in get_children():
		if c is TextureRect and c != null:
			var nm := str(c.name).to_lower()
			if nm.contains("bg") or nm.contains("background"):
				(c as TextureRect).visible = false
