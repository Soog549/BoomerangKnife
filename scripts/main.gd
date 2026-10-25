extends Node2D

const KNIFE_SCENE := preload("res://scenes/knife.tscn")
const TARGET_SCENE := preload("res://scenes/target.tscn")

var active_knife: Knife
var game_over := false
var revive_used := false
var levels_completed := 0
var shield_active := false  # бустер/снаряжение: защищает от первого промаха
var gold_knife := false      # расходник «золотой нож»

var speed_mult := 1.0

var tutorial_overlay: CanvasLayer = null

@onready var spawn_point: Marker2D = $KnifeSpawn
@onready var score_label: Label = $UI/HUD/ScoreLabel
@onready var lives_label: Label = $UI/HUD/LivesLabel
@onready var level_label: Label = $UI/HUD/LevelLabel
@onready var mult_label: Label = $UI/HUD/MultiplierTag
@onready var game_over_screen: Control = $UI/GameOver
@onready var final_score_label: Label = $UI/GameOver/Panel/VBox/FinalScore
@onready var best_score_label: Label = $UI/GameOver/Panel/VBox/BestScore
@onready var recommendation_label: Label = $UI/GameOver/Panel/VBox/Recommendation
@onready var pause_button: Button = $UI/PauseButton
@onready var pause_menu: Control = $UI/PauseMenu

var paused := false

@onready var art_background: TextureRect = $ArtBackground

func _ready() -> void:
	_add_character_preview()
	randomize()
	speed_mult = GameState.knife_speed_mult()
	_try_load_background()
	ScoreManager.reset()
	_connect_ui()
	_apply_boosters()
	_start_level()
	game_over_screen.hide()
	pause_menu.hide()
	if not GameState.tutorial_done:
		tutorial_overlay = preload("res://scripts/tutorial_overlay.gd").new()
		add_child(tutorial_overlay)
		tutorial_overlay.begin()
	AudioManager.play("click")
	AudioManager.play_music("gameplay")
	YandexSDK.set_gameplay(true)
	# Скрываем курсор ОС во время геймплея (для чистых скриншотов витрины);
	# клики/тапы продолжают работать через InputEvent. | hide OS cursor during gameplay
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Autoshot.begin(self)


func _process(delta: float) -> void:
	Autoshot.tick(delta)


func _input(event: InputEvent) -> void:
	# F12 — сохранить кадр экрана в PNG (скриншот витрины, без курсора).
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		_save_screenshot()


func _save_screenshot() -> void:
	var img := get_viewport().get_texture().get_image()
	var dir := "user://screenshots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var ts := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/shot_%s.png" % [dir, ts]
	img.save_png(ProjectSettings.globalize_path(path))
	print("SCRENSHOT:", ProjectSettings.globalize_path(path))

func _try_load_background() -> void:
	var tex := Assets.load_tex("background", "bg_main")
	if tex != null:
		art_background.texture = tex
		art_background.stretch_mode = TextureRect.STRETCH_SCALE
		art_background.visible = true
		$Background.visible = false

func _add_character_preview() -> void:
	var cp = preload("res://scripts/character_preview.gd").new()
	cp.name = "CharPreview"
	cp.position = Vector2(10.0, 930.0)
	cp.size = Vector2(360.0, 300.0)
	add_child(cp)

func _connect_ui() -> void:
	ScoreManager.score_changed.connect(func(v): if is_instance_valid(score_label): score_label.text = tr("СЧЁТ: %d") % v)
	ScoreManager.lives_changed.connect(func(v): if is_instance_valid(lives_label): lives_label.text = tr("ЖИЗНИ: %d") % v)
	ScoreManager.level_changed.connect(func(v): if is_instance_valid(level_label): level_label.text = tr("УРОВЕНЬ: %d") % v)
	ScoreManager.multiplier_changed.connect(func(v): if is_instance_valid(mult_label): mult_label.text = tr("МНОЖИТЕЛЬ x%.1f") % v)
	score_label.text = tr("СЧЁТ: %d") % ScoreManager.score
	lives_label.text = tr("ЖИЗНИ: %d") % ScoreManager.lives
	level_label.text = tr("УРОВЕНЬ: %d") % ScoreManager.level
	mult_label.text = tr("МНОЖИТЕЛЬ x%.1f") % ScoreManager.multiplier


## Расходует экипированный бустер на этот забег и тикает временные глифы.
func _apply_boosters() -> void:
	GameState.tick_temp_glyphs()
	match GameState.armed_booster:
		"heart":
			if GameState.consume_booster("heart"):
				ScoreManager.set_lives(ScoreManager.lives + 1)
				AudioManager.play("level")
		"shield":
			if GameState.consume_booster("shield"):
				shield_active = true
				AudioManager.play("return")
		"magnet":
			if GameState.consume_booster("magnet"):
				ScoreManager.booster_magnet = true
				AudioManager.play("return")
		"talisman":
			if GameState.consume_booster("talisman"):
				ScoreManager.booster_talisman = true
				AudioManager.play("level")
		_:
			pass
	# Бустер одноразовый — снимаем после применения.
	GameState.armed_booster = ""
	GameState.save_settings()
	# Пассивный щит от снаряжения.
	if not shield_active and GameState.equip_shield_enabled():
		shield_active = true
		AudioManager.play("return")
	# Расходник «Золотой нож»: каждый удар засчитывает 2 сегмента.
	gold_knife = GameState.consume_consumable("gold_knife")
	GameState.gold_knife_active = gold_knife

func _throw(aim: Vector2) -> void:
	if paused:
		return
	if active_knife == null or not is_instance_valid(active_knife):
		_spawn_knife()
	if active_knife.is_held():
		AudioManager.play("throw")
		if tutorial_overlay != null:
			tutorial_overlay.on_first_throw()
		active_knife.throw_toward(aim, speed_mult)
		return
	if active_knife.is_flying():
		active_knife.rethrow_now(aim, speed_mult)

## Мировая координата, куда смотрит тап/клик (с учётом камеры и стрейча).
func _aim_from_event(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return get_global_mouse_position()
	if event is InputEventScreenTouch:
		return (get_canvas_transform().affine_inverse() * event.position) as Vector2
	return Vector2(360, 300)

func _target_pos() -> Vector2:
	var targets := get_tree().get_nodes_in_group("target")
	var best: Target = null
	for t in targets:
		if not t.alive:
			continue
		if best == null or t.global_position.distance_to(spawn_point.global_position) < best.global_position.distance_to(spawn_point.global_position):
			best = t
	if best == null:
		return Vector2(360, 300)
	return _predict_target(best)

## Упреждение: для движущейся цели целься не в текущую позицию, а туда,
## где она будет к моменту прилёта ножа.
func _predict_target(t: Target) -> Vector2:
	var knife_speed := 1250.0 * speed_mult
	var dist := t.global_position.distance_to(spawn_point.global_position)
	var flight_time := dist / maxf(knife_speed, 1.0)
	return t.predict_position(flight_time)

func _start_level() -> void:
	_clear_target()
	_spawn_targets()
	_spawn_knife()

func _spawn_targets() -> void:
	var configs := LevelDefs.configs_for_level(ScoreManager.level)
	for cfg: Dictionary in configs:
		var t: Target = TARGET_SCENE.instantiate()
		t.add_to_group("target")
		var segs: int = max(cfg.segments, GameState.difficulty_data().base_segs)
		var speed: float = cfg.speed * GameState.target_speed_mult()
		t.setup(segs, speed, cfg.golden, cfg.moving, cfg.get("type", Target.Type.NORMAL))
		t.global_position = Vector2(cfg.x, cfg.y)
		t.all_segments_filled.connect(_on_target_cleared)
		add_child(t)

func _clear_target() -> void:
	for t in get_tree().get_nodes_in_group("target"):
		t.queue_free()

func _spawn_knife() -> void:
	active_knife = KNIFE_SCENE.instantiate() as Knife
	active_knife.global_position = spawn_point.global_position
	active_knife.return_point = spawn_point.global_position
	active_knife.got_caught.connect(_on_knife_caught)
	active_knife.broke_on_knife.connect(_on_knife_broke)
	active_knife.got_stuck.connect(_on_knife_stuck)
	add_child(active_knife)

func _on_knife_caught() -> void:
	ScoreManager.register_catch()
	GameState.record_catch()
	if GameState.regen_enabled() and ScoreManager.lives < 9:
		ScoreManager.set_lives(ScoreManager.lives + 1)

func _on_knife_broke(at: Vector2) -> void:
	AudioManager.play("break")
	FX.burst(at, Color(1, 0.3, 0.3), 20)
	FX.shake(0.3, 8)
	if shield_active:
		shield_active = false
		AudioManager.play("return")
		FX.burst(at, Color(0.5, 0.9, 1.0), 20)
		call_deferred("_spawn_knife")
		return
	ScoreManager.register_miss()
	if ScoreManager.lives <= 0:
		_end_game()
		return
	call_deferred("_spawn_knife")

func _on_knife_stuck() -> void:
	if active_knife != null and is_instance_valid(active_knife) and active_knife.is_held():
		return
	call_deferred("_spawn_knife")

func _on_target_cleared() -> void:
	# Проверяем: очистились ли ВСЕ цели текущего уровня
	for t in get_tree().get_nodes_in_group("target"):
		if t != null and is_instance_valid(t) and t.alive:
			return
	AudioManager.play("level")
	FX.confetti(Vector2(360, 300), 50)
	if tutorial_overlay != null:
		tutorial_overlay.on_target_cleared()
	ScoreManager.next_level()
	levels_completed += 1
	GameState.report_level(ScoreManager.level)
	GameState.record_level()
	GameState.add_coins(Economy.level_reward())
	_clear_knives()
	_start_level()
	if levels_completed % 3 == 0:
		await get_tree().create_timer(1.0).timeout
		AdService.show_interstitial()

func _clear_knives() -> void:
	if active_knife != null and is_instance_valid(active_knife):
		active_knife.queue_free()
	for k in get_tree().get_nodes_in_group("stuck_knife"):
		k.queue_free()

func _check_game_over() -> void:
	if ScoreManager.lives <= 0:
		_end_game()

func _end_game() -> void:
	game_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	YandexSDK.set_gameplay(false)
	AudioManager.play("over")
	best_score_label.text = tr("РЕКОРД: %d") % max(ScoreManager.score, GameState.high_score)
	var is_record := ScoreManager.score > GameState.high_score
	final_score_label.text = tr("СЧЁТ: %d") % ScoreManager.score
	if is_record:
		GameState.high_score = ScoreManager.score
		GameState.save_settings()
		final_score_label.text = tr("СЧЁТ: %d (НОВЫЙ РЕКОРД!)") % ScoreManager.score
	recommendation_label.text = _recommendation()
	GameState.record_run()
	OnlineService.submit_score(GameState.player_name, ScoreManager.score, tr("классика"))
	game_over_screen.show()

func _recommendation() -> String:
	if ScoreManager.multiplier < 3.0:
		return tr("Подсказка: держи серию — множитель растёт!")
	if GameState.has_mode("greed"):
		return tr("Подсказка: жадность даёт бонус к очкам — точнее бросай!")
	return tr("Подсказка: попробуй сложность «Сложный» для х2 очков!")

func _on_restart_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
func _on_revive_pressed() -> void:
	AudioManager.play("click")
	if revive_used:
		return
	revive_used = true
	AdService.show_rewarded()
	var ok: bool = await AdService.rewarded_completed
	if not ok:
		revive_used = false
		return
	GameState.record_ad_watched()
	GameState.add_coins(Economy.COINS_PER_REVIVE)
	if not game_over:
		return
	# Восстанавливаем жизнь и продолжаем
	ScoreManager.set_lives(1)
	game_over = false
	game_over_screen.hide()
	_spawn_knife()
	AudioManager.play("level")
	YandexSDK.set_gameplay(true)

func _on_gameover_menu_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_pause_pressed() -> void:
	_toggle_pause()

func _on_resume_pressed() -> void:
	AudioManager.play("click")
	_toggle_pause()

func _on_pause_menu_pressed() -> void:
	AudioManager.play("click")
	get_tree().paused = false
	YandexSDK.set_gameplay(false)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _toggle_pause() -> void:
	if game_over:
		return
	paused = not paused
	get_tree().paused = paused
	pause_menu.visible = paused
	YandexSDK.set_gameplay(not paused)
	AudioManager.play("click")

func _unhandled_input(event: InputEvent) -> void:
	if game_over or paused:
		return
	if event is InputEventScreenTouch and event.pressed:
		_throw(_aim_from_event(event))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_throw(_aim_from_event(event))
