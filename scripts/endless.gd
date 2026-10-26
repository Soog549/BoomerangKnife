extends Node2D

## Бесконечный режим: волны целей с нарастающей сложностью.
## Счёт ведёт ScoreManager (попадания, возвраты, бонус за волну) —
## единый источник правды, как в основном режиме.

const KNIFE_SCENE := preload("res://scenes/knife.tscn")
const TARGET_SCENE := preload("res://scenes/target.tscn")

var active_knife: Knife
var game_over := false
var paused := false
var wave := 1
var shield_active := false
var gold_knife := false
var wave_targets_remaining := 0
var _boss_this_wave := false
var speed_mult := 1.0

@onready var spawn_point: Marker2D = $KnifeSpawn
@onready var wave_label: Label = $UI/HUD/WaveLabel
@onready var score_label: Label = $UI/HUD/ScoreLabel
@onready var mult_label: Label = $UI/HUD/MultiplierTag
@onready var lives_label: Label = $UI/HUD/LivesLabel
@onready var best_label: Label = $UI/HUD/BestLabel
@onready var game_over_screen: Control = $UI/GameOver
@onready var stats_label: Label = $UI/GameOver/Panel/VBox/StatsLabel
@onready var gameover_best_label: Label = $UI/GameOver/Panel/VBox/BestLabel
@onready var pause_menu: Control = $UI/PauseMenu
@onready var pause_button: Button = $UI/PauseButton
@onready var banner_demo: Control = $UI/BannerDemo

func _ready() -> void:
	_add_player_character()
	_add_player_arms()
	randomize()
	speed_mult = GameState.knife_speed_mult()
	ScoreManager.reset()
	_connect_ui()
	_banner_setup()
	_apply_boosters()
	_start_wave(1)
	game_over_screen.hide()
	pause_menu.hide()
	var hud := get_node_or_null("UI/HUD")
	if hud != null:
		hud.offset_top += 40.0
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	AudioManager.play("click")
	AudioManager.play_music("gameplay")
	YandexSDK.set_gameplay(true)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Autoshot.begin(self)


func _process(delta: float) -> void:
	Autoshot.tick(delta)

func _banner_setup() -> void:
	pass  # banner off in gameplay
	if AdService.is_demo_mode():
		banner_demo.visible = false

func _exit_tree() -> void:
	AdService.hide_banner()
	GameState.gold_knife_active = false

func _connect_ui() -> void:
	ScoreManager.lives_changed.connect(func(v): lives_label.text = tr("ЖИЗНИ: %d") % v)
	ScoreManager.score_changed.connect(func(v): score_label.text = tr("СЧЁТ: %d") % v)
	ScoreManager.multiplier_changed.connect(func(m: float): mult_label.text = tr("МНОЖИТЕЛЬ x%.1f") % m)
	score_label.text = tr("СЧЁТ: %d") % ScoreManager.score
	lives_label.text = tr("ЖИЗНИ: %d") % ScoreManager.lives
	mult_label.text = tr("МНОЖИТЕЛЬ x%.1f") % ScoreManager.multiplier
	best_label.text = tr("РЕКОРД ВОЛНЫ: %d") % GameState.endless_best_wave

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

func _unhandled_input(event: InputEvent) -> void:
	if game_over or paused:
		return
	if event is InputEventScreenTouch and event.pressed:
		_throw(_aim_from_event(event))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_throw(_aim_from_event(event))

func _throw(aim: Vector2) -> void:
	if paused:
		return
	if active_knife == null or not is_instance_valid(active_knife):
		_spawn_knife()
	if active_knife.is_held():
		AudioManager.play("throw")
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
	return best.predict_position(_flight_time_to(best))

func _flight_time_to(t: Target) -> float:
	var knife_speed := 1250.0 * speed_mult
	return t.global_position.distance_to(spawn_point.global_position) / maxf(knife_speed, 1.0)

func _start_wave(wave_number: int) -> void:
	wave = wave_number
	wave_label.text = tr("ВОЛНА: %d") % wave
	_wave_bonus(wave)
	_spawn_wave_targets(wave)
	_ensure_knife()

func _wave_bonus(_wave_number: int) -> void:
	# Бонус за волну очков НЕ даёт: счёт — только фактические попадания.
	pass

func _spawn_wave_targets(wave_number: int) -> void:
	for t in get_tree().get_nodes_in_group("target"):
		t.queue_free()
	_boss_this_wave = false

	var target_count := clampi(1 + wave_number / 4, 1, 4)
	var positions := LevelDefs.positions_for_count(target_count)

	var speed := (0.8 + wave_number * 0.05) * GameState.target_speed_mult()
	wave_targets_remaining = target_count

	for i in target_count:
		var t: Target = TARGET_SCENE.instantiate()
		t.add_to_group("target")
		var segs := clampi(3 + wave_number / 3, 3, 9)
		var golden := wave_number >= 2 and randf() < 0.35
		# Типы: босс с 20-й волны (редко), броня с 8-й, реген с 15-й,
		# движущиеся с 5-й. Босс — не чаще одного за волну.
		var type: int = Target.Type.NORMAL
		if wave_number >= 20 and i > 0 and randf() < 0.03 + wave_number * 0.005 and not _boss_this_wave:
			_boss_this_wave = true
			type = Target.Type.BOSS
		elif wave_number >= 15 and randf() < 0.1 + wave_number * 0.015:
			type = Target.Type.REGEN
		elif wave_number >= 8 and randf() < 0.12 + wave_number * 0.015:
			type = Target.Type.ARMORED
		elif wave_number >= 5 and randf() < 0.1 + wave_number * 0.02:
			type = Target.Type.MOVING
		var moving := type == Target.Type.MOVING
		if moving or type == Target.Type.BOSS:
			golden = false
		t.setup(segs, speed, golden, moving, type)
		t.global_position = positions[i]
		t.all_segments_filled.connect(_on_target_cleared)
		add_child(t)

func _ensure_knife() -> void:
	if active_knife == null or not is_instance_valid(active_knife):
		_spawn_knife()

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
	if get_tree().get_nodes_in_group("target").size() == 0:
		return
	if active_knife != null and is_instance_valid(active_knife) and active_knife.is_held():
		return
	call_deferred("_spawn_knife")

func _on_target_cleared() -> void:
	if game_over:
		return
	wave_targets_remaining -= 1
	if wave_targets_remaining <= 0:
		_advance_wave()

func _advance_wave() -> void:
	AudioManager.play("level")
	FX.confetti(Vector2(360, 300), 40)
	GameState.record_level()
	GameState.report_level(wave + 1)
	GameState.add_coins(Economy.endless_wave_reward(wave))
	_clear_knives()
	call_deferred("_start_wave", wave + 1)

func _clear_knives() -> void:
	if active_knife != null and is_instance_valid(active_knife):
		active_knife.queue_free()
		active_knife = null
	for k in get_tree().get_nodes_in_group("stuck_knife"):
		k.queue_free()

func _end_game() -> void:
	game_over = true
	YandexSDK.set_gameplay(false)
	AudioManager.play("over")
	GameState.record_endless_run(wave, ScoreManager.score)
	OnlineService.submit_score(GameState.player_name, ScoreManager.score, tr("эндлесс"))
	stats_label.text = tr("Волна: %d • Счёт: %d") % [wave, ScoreManager.score]
	gameover_best_label.text = tr("Рекорд волн: %d") % GameState.endless_best_wave
	game_over_screen.show()

func _on_restart_pressed() -> void:
	AudioManager.play("click")
	YandexSDK.set_gameplay(false)
	get_tree().change_scene_to_file("res://scenes/endless.tscn")

func _on_gameover_menu_pressed() -> void:
	AudioManager.play("click")
	YandexSDK.set_gameplay(false)
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


func _add_player_character() -> void:
	var spr := Sprite2D.new()
	spr.name = "PlayerSprite"
	var av := "res://assets/images/avatars/avatar_%d.png" % GameState.avatar
	if ResourceLoader.exists(av):
		spr.texture = load(av)
	else:
		var tp := "res://assets/images/packs/%s/bg.jpg" % GameState.style_pack
		if ResourceLoader.exists(tp):
			spr.texture = load(tp)
	if spr.texture != null:
		var th: float = float(spr.texture.get_height())
		var k: float = 150.0 / maxf(th, 1.0)
		spr.scale = Vector2(k, k)
	spr.position = spawn_point.position + Vector2(0, -30)
	spr.z_index = 1
	add_child(spr)


func _add_player_arms() -> void:
	var base: Vector2 = spawn_point.position + Vector2(0, -30)
	var sk: Dictionary = GameState.current_skin()
	var cloth: Color = sk.get("blade", Color(0.3, 0.6, 1.0)).darkened(0.35)
	var skin_c := Color(0.93, 0.78, 0.62)
	for side in [-1, 1]:
		var arm := Polygon2D.new()
		arm.polygon = PackedVector2Array([
			Vector2(side * 22.0, -6.0), Vector2(side * 38.0, 10.0), Vector2(side * 32.0, 26.0),
			Vector2(side * 18.0, 14.0)])
		arm.color = cloth
		arm.position = base
		add_child(arm)
		var hand := Polygon2D.new()
		hand.polygon = PackedVector2Array([
			Vector2(side * 33.0, 22.0), Vector2(side * 40.0, 30.0), Vector2(side * 34.0, 36.0),
			Vector2(side * 28.0, 28.0)])
		hand.color = skin_c
		hand.position = base
		add_child(hand)
	var torso := Polygon2D.new()
	torso.polygon = PackedVector2Array([
		Vector2(-24.0, 6.0), Vector2(24.0, 6.0), Vector2(20.0, 46.0), Vector2(-20.0, 46.0)])
	torso.color = cloth
	torso.position = base
	add_child(torso)
