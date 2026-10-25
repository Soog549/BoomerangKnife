extends Node2D

## Арена дуэли: два игрока одновременно. Левый тап = Игрок 1, правый = Игрок 2.
## Оба используют одинаковую случайную экипировку (skin + цель), заданную в duel_config.
## Побеждает тот, кто первым наберёт rounds побед.

const KNIFE_SCENE := preload("res://scenes/knife.tscn")
const TARGET_SCENE := preload("res://scenes/target.tscn")

var rounds_total := 3
var current_round := 1
var win_score_p1 := 0
var win_score_p2 := 0

var knife_p1: Knife
var knife_p2: Knife
var target_p1: Target
var target_p2: Target
var game_over := false
var paused := false
var _duel_variant := "split"   # режим дуэли для выплаты награды | duel variant used for payout
var _enemy_on := false
var _enemy_pos := Vector2(360, 520)
var _enemy_dir := 1.0
var _enemy_axis := "y"
var _shared_target := false

@onready var round_label: Label = $UI/HUD/RoundLabel
@onready var score_label: Label = $UI/HUD/ScoreLabel
@onready var spawn_p1: Marker2D = $SpawnP1
@onready var spawn_p2: Marker2D = $SpawnP2
@onready var msg_label: Label = $UI/MsgLabel
@onready var game_over_screen: Control = $UI/GameOver
@onready var gameover_title: Label = $UI/GameOver/Panel/VBox/Title
@onready var gameover_final: Label = $UI/GameOver/Panel/VBox/FinalLabel
@onready var pause_menu: Control = $UI/PauseMenu
@onready var banner_demo: Control = $UI/BannerDemo

func _ready() -> void:
	randomize()
	rounds_total = int(GameState.duel_config.get("rounds", 3))
	var variant := str(GameState.duel_config.get("variant", "split"))
	_duel_variant = variant
	if variant == "shared":
		var dv := get_node_or_null("Divider")
		if dv != null:
			dv.visible = false
		var bg2 := get_node_or_null("BackgroundP2")
		if bg2 != null:
			bg2.visible = false
		spawn_p1.position = Vector2(210, 1050)
		spawn_p2.position = Vector2(510, 1050)
		_shared_target = true
	elif variant == "net":
		var dvn := get_node_or_null("Divider")
		if dvn != null:
			dvn.visible = false
		var bgn := get_node_or_null("BackgroundP2")
		if bgn != null:
			bgn.visible = false
		spawn_p1.position = Vector2(360, 1050)
		msg_label.text = tr("ОНЛАЙН: весь экран — твой вид. Синхронизация — следующий этап (упрощаем).")
	elif variant == "solo":
		for nm in ["TargetP2", "KnifeP2", "ScoreP2"]:
			var nd := get_node_or_null(nm)
			if nd != null:
				nd.visible = false
		var dv4 := get_node_or_null("Divider")
		if dv4 != null:
			dv4.visible = false
		var bg24 := get_node_or_null("BackgroundP2")
		if bg24 != null:
			bg24.visible = false
		spawn_p1.position = Vector2(360, 1050)
		msg_label.text = tr("ТРЕНИРОВКА (соло): бросай нож, отрабатывай точность.")
	elif variant == "mob":
		spawn_p1.position = Vector2(180, 1050)
		spawn_p2.position = Vector2(540, 380)
		_enemy_on = true
		_enemy_pos = Vector2(360, 430)
		_enemy_axis = "x"
		msg_label.text = tr("ПРОТИВ МОБА: цель-моб на дальней стороне.")
	# Подсказка
	msg_label.text = tr("Левая половина — Игрок 1 • Правая — Игрок 2 • тап = бросок в точку, повторный в полёте = доворот")
	var dbg := get_node_or_null("Background")
	if dbg != null and dbg is TextureRect:
		var pbg := "res://assets/images/packs/%s/bg.png" % GameState.style_pack
		if ResourceLoader.exists(pbg):
			dbg.texture = load(pbg)
	_banner_setup()
	_start_round(1)
	pause_menu.hide()
	game_over_screen.hide()
	AudioManager.play("click")
	AudioManager.play_music("duel")
	YandexSDK.set_gameplay(true)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Autoshot.begin(self)


func _process(delta: float) -> void:
	if _enemy_on and not paused and not game_over:
		if _enemy_axis == "x":
			_enemy_pos.x += _enemy_dir * 140.0 * delta
			if _enemy_pos.x > 600.0:
				_enemy_pos.x = 600.0
				_enemy_dir = -1.0
			elif _enemy_pos.x < 120.0:
				_enemy_pos.x = 120.0
				_enemy_dir = 1.0
		else:
			_enemy_pos.y += _enemy_dir * 120.0 * delta
			if _enemy_pos.y > 900.0:
				_enemy_pos.y = 900.0
				_enemy_dir = -1.0
			elif _enemy_pos.y < 380.0:
				_enemy_pos.y = 380.0
				_enemy_dir = 1.0
		queue_redraw()
	Autoshot.tick(delta)

func _banner_setup() -> void:
	banner_demo.visible = false  # в геймплее баннер не показываем

func _exit_tree() -> void:
	AdService.hide_banner()

func _unhandled_input(event: InputEvent) -> void:
	if game_over or paused:
		return
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(_aim_from_event(event))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(_aim_from_event(event))

## Мировая координата, куда смотрит тап/клик (с учётом камеры и стрейча).
func _aim_from_event(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return get_global_mouse_position()
	if event is InputEventScreenTouch:
		return (get_canvas_transform().affine_inverse() * event.position) as Vector2
	return Vector2(360, 300)

func _handle_tap(world_pos: Vector2) -> void:
	if world_pos.x < 360.0:
		if knife_p1 != null and is_instance_valid(knife_p1):
			if knife_p1.is_held():
				knife_p1.throw_toward(world_pos)
			else:
				knife_p1.rethrow_now(world_pos)
	else:
		if knife_p2 != null and is_instance_valid(knife_p2):
			if knife_p2.is_held():
				knife_p2.throw_toward(world_pos)
			else:
				knife_p2.rethrow_now(world_pos)

func _predict(t: Target) -> Vector2:
	if t == null or not is_instance_valid(t):
		return Vector2(360, 300)
	var spawn_pos := spawn_p1.global_position
	var knife_speed := 1250.0 * GameState.knife_speed_mult()
	var flight := t.global_position.distance_to(spawn_pos) / maxf(knife_speed, 1.0)
	return t.predict_position(flight)

func _draw() -> void:
	if _enemy_on:
		pass
	else:
		return
	draw_circle(_enemy_pos, 46.0, Color(0.85, 0.3, 0.4))
	draw_circle(_enemy_pos, 28.0, Color(0.25, 0.08, 0.12))
	draw_circle(_enemy_pos + Vector2(-12, -8), 7.0, Color(1, 1, 1, 0.9))
	draw_circle(_enemy_pos + Vector2(12, -8), 7.0, Color(1, 1, 1, 0.9))

func _start_round(round_number: int) -> void:
	current_round = round_number
	round_label.text = tr("РАУНД %d / %d") % [round_number, rounds_total]
	score_label.text = tr("Игрок 1: %d : %d : Игрок 2") % [win_score_p1, win_score_p2]
	_clear_all()
	var cfg: Dictionary = GameState.duel_config
	var skin_i: int = GameState.forced_skin
	if skin_i < 0:
		skin_i = randi() % GameState.SKINS.size()
	GameState.forced_skin = skin_i
	var segs: int = cfg.get("segments", 6)
	var speed: float = cfg.get("speed", 1.2)
	var golden: bool = cfg.get("golden", true)
	var moving: bool = cfg.get("moving", false)

	if _shared_target:
		target_p1 = _spawn_target(Vector2(360, 300), segs, speed, golden, moving, _on_p1_clear)
		target_p2 = null
	elif _duel_variant in ["solo", "net"]:
		target_p1 = _spawn_target(Vector2(360, 300), segs, speed, golden, moving, _on_p1_clear)
		target_p2 = null
	else:
		target_p1 = _spawn_target(Vector2(180, 300), segs, speed, golden, moving, _on_p1_clear)
		target_p2 = _spawn_target(Vector2(540, 300), segs, speed, golden, moving, _on_p2_clear)
	knife_p1 = _spawn_knife(spawn_p1.global_position, 360.0)
	if target_p2 != null or _shared_target:
		knife_p2 = _spawn_knife(spawn_p2.global_position, 360.0)

func _spawn_target(pos: Vector2, segs: int, speed: float, golden: bool, moving: bool, cb: Callable) -> Target:
	var t: Target = TARGET_SCENE.instantiate()
	t.setup(segs, speed, golden, moving)
	t.global_position = pos
	t.all_segments_filled.connect(cb)
	add_child(t)
	return t

func _spawn_knife(pos: Vector2, x_limit: float) -> Knife:
	var k: Knife = KNIFE_SCENE.instantiate()
	k.global_position = pos
	k.return_point = pos
	var player := 1 if pos == spawn_p1.global_position else 2
	k.got_caught.connect(func(): _respawn_knife(player))
	k.got_stuck.connect(func(): _respawn_knife(player))
	k.broke_on_knife.connect(func(_at: Variant): _respawn_knife(player))
	add_child(k)
	return k

func _respawn_knife(player: int) -> void:
	if game_over or paused:
		return
	call_deferred("_do_respawn_knife", player)

func _do_respawn_knife(player: int) -> void:
	if game_over or paused:
		return
	if player == 1:
		knife_p1 = _spawn_knife(spawn_p1.global_position, 360.0)
	else:
		knife_p2 = _spawn_knife(spawn_p2.global_position, 360.0)

func _on_p1_clear() -> void:
	_end_round(1)

func _on_p2_clear() -> void:
	if _shared_target:
		_end_round(1)
		return
	_end_round(2)

func _end_round(winner: int) -> void:
	if game_over:
		return
	if winner == 1:
		win_score_p1 += 1
		msg_label.text = tr("Раунд выиграл Игрок 1!")
	else:
		win_score_p2 += 1
		msg_label.text = tr("Раунд выиграл Игрок 2!")

	# Проверка окончания дуэли
	if win_score_p1 >= rounds_total or win_score_p2 >= rounds_total:
		_finish_duel()
		return
	# Автопереход к следующему раунду с небольшой паузой
	await get_tree().create_timer(1.0).timeout
	if paused or game_over:
		return
	_start_round(current_round + 1)

func _finish_duel() -> void:
	game_over = true
	YandexSDK.set_gameplay(false)
	var p1_won := win_score_p1 > win_score_p2
	# Осколки — только за реальную победу Игрока 1 в боевых режимах (не solo/net).
	# Shards only for a real Player 1 win in battle modes (not solo/net).
	var shards_ok: bool = p1_won and _duel_variant in ["split", "shared", "mob"]
	gameover_title.text = tr("ПОБЕДИЛ ИГРОК 1") if p1_won else tr("ПОБЕДИЛ ИГРОК 2")
	gameover_final.text = tr("%d : %d  (+%d монет победителю)") % [win_score_p1, win_score_p2, Economy.DUEL_WIN_REWARD]
	if p1_won and _duel_variant != "solo":
		GameState.add_coins(Economy.DUEL_WIN_REWARD)
	if shards_ok:
		GameState.add_duel_shards(Economy.SHARDS_PER_DUEL_WIN)
	if p1_won and _duel_variant != "solo":
		GameState.record_duel_win()
	# Записываем в лидерборд
	OnlineService.submit_score(tr("Игрок %s") % ("1" if p1_won else "2"), max(win_score_p1, win_score_p2), tr("дуэль"))
	GameState.forced_skin = -1
	AudioManager.play("level")
	game_over_screen.show()

func _clear_all() -> void:
	for node in [knife_p1, knife_p2, target_p1, target_p2]:
		if node == null or not is_instance_valid(node):
			continue
		if node != null and is_instance_valid(node):
			node.queue_free()
	knife_p1 = null
	knife_p2 = null
	for t in get_tree().get_nodes_in_group("target"):
		t.queue_free()
	for k in get_tree().get_nodes_in_group("stuck_knife"):
		k.queue_free()

func _on_restart_pressed() -> void:
	AudioManager.play("click")
	GameState.forced_skin = -1
	YandexSDK.set_gameplay(false)
	get_tree().change_scene_to_file("res://scenes/duel.tscn")

func _on_gameover_menu_pressed() -> void:
	AudioManager.play("click")
	GameState.forced_skin = -1
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
