extends Node2D
## АРЕНА МОБОВ v4: ОДИН плавающий джойстик на всё поле (скрыт), поле подсвечено,
## радиус зависит от сложности; тап = бросок ножа (авто-прицел); WASD/стрелки + Пробел на ПК.
## ДиП-Флеш-17, 2026-10-21. Портрет 720x1280.

const W := 720.0
const H := 1280.0
const AREA_TOP := 140.0
const AREA_BOTTOM := 1230.0
const MOVE_SPEED := 460.0
const DEAD := 0.13
const TAP_MAX := 26.0

const MOB_TYPES := {
	"runner":  {"hp": 20.0, "speed": 55.0, "cd": 1.4, "proj": "needle",  "col": Color(0.88, 0.30, 0.40), "r": 44.0},
	"drone":   {"hp": 40.0, "speed": 38.0, "cd": 2.4, "proj": "shuriken","col": Color(0.72, 0.30, 1.00), "r": 54.0},
	"anomaly": {"hp": 70.0, "speed": 24.0, "cd": 3.8, "proj": "stone",   "col": Color(1.00, 0.82, 0.30), "r": 64.0},
	"boss":    {"hp": 240.0, "speed": 16.0, "cd": 2.6, "proj": "stone",  "col": Color(0.75, 0.15, 0.25), "r": 84.0},
}
const PROJ := {
	"needle":   {"speed": 520.0, "r": 8.0,  "dmg": 5.0,  "col": Color(1.0, 0.25, 0.35)},
	"shuriken": {"speed": 380.0, "r": 17.0, "dmg": 8.0,  "col": Color(0.85, 0.35, 1.0)},
	"stone":    {"speed": 240.0, "r": 24.0, "dmg": 15.0, "col": Color(0.95, 0.80, 0.45)},
}
const LOOT := [
	{"name": "Осколок", "col": Color(0.72, 0.72, 0.78), "coins": 3, "score": 0, "w": 65},
	{"name": "Реликт", "col": Color(0.30, 0.60, 1.00), "coins": 8, "score": 5, "w": 22},
	{"name": "Ядро аномалии", "col": Color(0.75, 0.35, 1.00), "coins": 20, "score": 15, "w": 10},
	{"name": "Ключ Разлома", "col": Color(1.00, 0.80, 0.20), "coins": 50, "score": 40, "w": 3},
]

var hp := 100.0
var max_hp := 100.0
var shield := 50.0
var max_shield := 50.0
var regen_t := 0.0
var score := 0
var coins := 0
var wave := 1
var wave_t := 0.0
var spawn_t := 0.0
var wave_quota := 0
var wave_killed := 0
var wave_gap := 0.0
var over := false
var t_anim := 0.0
var flash := 0.0
var shake := 0.0
var dmg_pop: Array = []
var slowmo_t := 0.0
var hitstop_t := 0.0
var banner_t := 0.0
var banner_n := 0
var combo := 0
var combo_t := 0.0
var best_combo := 0
var rings: Array = []
var relics := 0
var blocked_dmg := 0.0
var mob_seq := 0
var _practice_kind := ""
var max_knives := 3
var ammo := 1
var started := false
var shop_layer: CanvasLayer
var shop_panel: Control
var shop_info: Label
var replay_btn: Button
var toast_t := 0.0
var toast_text := ""
var toast_col := Color(1, 1, 1)
var paused := false
var _pl: CanvasLayer
var _pm: Control

var px := W * 0.5
var py := 1160.0
var mobs: Array = []
var projectiles: Array = []
var knives: Array = []
var drops: Array = []
var knife_tex: Texture2D = null
var shield_tex: Texture2D = null
var mob_tex := {}
var proj_tex := {}
var arena_bg: Texture2D = null

# плавающий джойстик (скрыт, пока не тронули)
var joy_on := false
var joy_origin := Vector2.ZERO
var joy_vec := Vector2.ZERO
var joy_drag := 0.0
var move_idx := -1
var aim_idx := -1
var field_bottom := 1180.0
var damaged := false
var _ground_mode := false
var _rush_mode := false
var _survival_arena := false
var _anim_t := 0.0
var _rig_state := "idle"
var _rig_t := 0.0
var avatar_tex: Texture2D = null
var rig_head: Texture2D = null
var rig_torso: Texture2D = null
var rig_leg_l: Texture2D = null
var rig_leg_r: Texture2D = null
var stick_r := 62.0

func _ready() -> void:
	var dcfg: Dictionary = GameState.duel_config
	if str(dcfg.get("variant", "")) == "train":
		var lvl: int = clampi(int(dcfg.get("mob_level", 1)), 1, 3)
		_practice_kind = ["runner", "drone", "anomaly"][lvl - 1]
	var kp := "res://assets/images/packs/%s/knife-%d.png" % [GameState.style_pack, (GameState.selected_skin % 3) + 1]
	if ResourceLoader.exists(kp):
		knife_tex = load(kp)
	elif ResourceLoader.exists("res://assets/images/knives/knife_gold.png"):
		knife_tex = load("res://assets/images/knives/knife_gold.png")
	var sp := ""
	var sid := GameState.equipped_in("shield")
	if sid != "":
		sp = "res://assets/images/shields/%s.png" % sid
	if sp == "" or not ResourceLoader.exists(sp):
		var si: int = (GameState.selected_skin % 12) + 1
		sp = "res://assets/images/shields/shield_%02d.png" % si
	var shp := "res://assets/images/packs/%s/shield-%d.png" % [GameState.style_pack, (GameState.selected_skin % 3) + 1]
	if ResourceLoader.exists(shp):
		shield_tex = load(shp)
	elif ResourceLoader.exists(sp):
		shield_tex = load(sp)
	for kind in ["runner", "drone", "anomaly", "boss"]:
		var arr := []
		for v in [1, 2]:
			var mp := "res://assets/images/arena/mob-%s-%d.png" % [kind, v]
			var pk := ""
			if kind != "boss":
				var ki: int = ["runner", "drone", "anomaly"].find(kind) + 1
				pk = "res://assets/images/packs/%s/mob-%d.png" % [GameState.style_pack, ki]
			if pk != "" and ResourceLoader.exists(pk):
				mp = pk
			if ResourceLoader.exists(mp):
				arr.append(load(mp))
		if not arr.is_empty():
			mob_tex[kind] = arr
	for pk in ["needle", "shuriken", "stone"]:
		var pp := "res://assets/images/arena/proj-%s.png" % pk
		if ResourceLoader.exists(pp):
			proj_tex[pk] = load(pp)
	var pbg := "res://assets/images/packs/%s/bg.jpg" % GameState.style_pack
	if ResourceLoader.exists(pbg):
		arena_bg = load(pbg)
	elif ResourceLoader.exists("res://assets/images/arena/arena-bg.png"):
		arena_bg = load("res://assets/images/arena/arena-bg.png")
	if GameState.difficulty == "easy":
		max_hp = 120.0
		max_shield = 60.0
	elif GameState.difficulty == "hard":
		max_hp = 80.0
		max_shield = 40.0
	hp = max_hp
	shield = max_shield
	max_knives = clampi(3 + GameState.extra_knives, 3, 8)
	ammo = max_knives
	_spawn_mob()
	field_bottom = float(H) - 110.0
	max_hp *= GameState.class_bonus("hp")
	hp = max_hp
	const CF := ["warrior", "rogue", "mage", "archer", "knight", "berserker", "assassin", "paladin",
		"druid", "monk", "pirate", "samurai", "ninja", "viking", "gunslinger", "alchemist",
		"necromancer", "engineer", "bounty_hunter", "shaman", "champion", "princess", "fist",
		"kinetic", "pyro", "cryo", "psion", "telekinetic", "kimaster", "aurate", "graviton",
		"symbiote", "empath"]
	var ci: int = clampi(GameState.avatar, 0, CF.size() - 1)
	var ap := "res://assets/images/classes_full/%s.png" % CF[ci]
	if not ResourceLoader.exists(ap):
		ap = "res://assets/images/classes/%s.png" % CF[ci]
	if not ResourceLoader.exists(ap):
		ap = "res://assets/images/avatars/avatar_%d.png" % GameState.avatar
	if ResourceLoader.exists(ap):
		avatar_tex = load(ap)
	var rp := "res://assets/images/rig/%s/" % CF[ci]
	if ResourceLoader.exists(rp + "head.png"):
		rig_head = load(rp + "head.png")
		rig_torso = load(rp + "torso.png")
		rig_leg_l = load(rp + "leg_l.png")
		rig_leg_r = load(rp + "leg_r.png")
	_build_pause()
	PauseUI.normalize(_pm)
	_build_action_buttons()
	_build_shop()
	_ground_mode = GameState.frontier_mode
	if _ground_mode:
		GameState.difficulty = "hard"
		GameState.frontier_mode = false
	if GameState.rush_mode:
		_rush_mode = true
		GameState.rush_mode = false
		_ground_mode = true
	if GameState.survival_arena:
		_survival_arena = true
		GameState.survival_arena = false
		_ground_mode = true
	replay_btn = Button.new()
	replay_btn.text = tr("ПОВТОР")
	replay_btn.position = Vector2(W * 0.5 - 120.0, H * 0.38 + 160.0)
	replay_btn.size = Vector2(240, 56)
	replay_btn.visible = false
	replay_btn.pressed.connect(_restart)
	add_child(replay_btn)

func _spawn_mob() -> void:
	mob_seq += 1
	if _practice_kind != "":
		var pt: Dictionary = MOB_TYPES[_practice_kind]
		var ph: float = float(pt["hp"]) + float(wave) * 4.0
		mobs.append({
			"kind": _practice_kind, "x": randf_range(90.0, W - 90.0), "y": -40.0,
			"hp": ph, "max": ph, "cd": (float(pt["cd"]) + 0.8) * _diff_cd_mult(), "t": 0.0, "r": float(pt["r"]),
			"col": pt["col"], "speed": float(pt["speed"]) * 0.7, "proj": str(pt["proj"]), "var": randi() % 2, "id": mob_seq,
		})
		return
	if wave % 3 == 0 and not _boss_alive():
		var bt: Dictionary = MOB_TYPES["boss"]
		mobs.append({
			"kind": "boss", "x": W * 0.5, "y": -70.0,
			"hp": float(bt["hp"]) + float(wave) * 18.0, "max": float(bt["hp"]) + float(wave) * 18.0,
			"cd": float(bt["cd"]) * _diff_cd_mult(), "t": 0.0, "r": float(bt["r"]),
			"col": bt["col"], "speed": float(bt["speed"]), "proj": str(bt["proj"]), "var": randi() % 2, "id": mob_seq,
		})
		return
	var kinds: Array = ["runner", "runner", "drone"]
	if wave >= 2:
		kinds.append("drone")
	if wave >= 3:
		kinds.append("anomaly")
	var k: String = str(kinds[randi() % kinds.size()])
	if _rush_mode:
		k = "boss"
	var t: Dictionary = MOB_TYPES[k]
	var diff := 1.0
	if GameState.difficulty == "easy":
		diff = 0.8
	elif GameState.difficulty == "hard":
		diff = 1.3
	var base_hp: float = (float(t["hp"]) + float(wave) * 6.0) * diff
	mobs.append({
		"kind": k, "x": randf_range(90.0, W - 90.0), "y": -40.0,
		"hp": base_hp, "max": base_hp,
		"cd": float(t["cd"]) * _diff_cd_mult(), "t": 0.0, "r": float(t["r"]),
		"col": t["col"], "speed": float(t["speed"]), "proj": str(t["proj"]), "var": randi() % 2, "id": mob_seq,
	})

func _boss_alive() -> bool:
	for m in mobs:
		if str(m["kind"]) == "boss":
			return true
	return false

func _in_field(p: Vector2) -> bool:
	return p.y > AREA_TOP - 40.0 and p.y < field_bottom + 80.0

func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_toggle_pause()
		return
	if not GameState.arena_tutorial_done:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			GameState.arena_tutorial_done = true
			GameState.save_settings()
			shop_panel.visible = true
			return
	if not started:
		return
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		if e is InputEventScreenTouch:
			var st := e as InputEventScreenTouch
			var tp: Vector2 = get_canvas_transform().affine_inverse() * st.position
			if st.pressed:
				if move_idx < 0:
					if _in_field(tp):
						move_idx = st.index
						joy_on = true
						joy_origin = st.position
						joy_vec = Vector2.ZERO
						joy_drag = 0.0
				elif aim_idx < 0:
					aim_idx = st.index
					_throw_at(tp)
			else:
				if st.index == move_idx:
					move_idx = -1
					joy_on = false
					joy_vec = Vector2.ZERO
					joy_drag = 0.0
				elif st.index == aim_idx:
					aim_idx = -1
		elif e is InputEventScreenDrag:
			var sd := e as InputEventScreenDrag
			var dp: Vector2 = get_canvas_transform().affine_inverse() * sd.position
			if sd.index == move_idx:
				var td: Vector2 = dp - joy_origin
				joy_drag = td.length()
				if td.length() > stick_r:
					td = td.normalized() * stick_r
				joy_vec = td / stick_r
			elif sd.index == aim_idx:
				_throw_at(dp)
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var mpos: Vector2 = get_canvas_transform().affine_inverse() * mb.position
			if over:
				_restart()
				return
			if _in_field(mpos):
				joy_on = true
				joy_origin = mpos
				joy_vec = Vector2.ZERO
				joy_drag = 0.0
			else:
				_throw_auto()
		elif not mb.pressed:
			if joy_on and joy_drag < TAP_MAX:
				_throw_auto()
			joy_on = false
			joy_vec = Vector2.ZERO
			joy_drag = 0.0
	elif e is InputEventMouseMotion and joy_on:
		var mm := e as InputEventMouseMotion
		var d: Vector2 = (get_canvas_transform().affine_inverse() * mm.position) - joy_origin
		joy_drag = d.length()
		if d.length() > stick_r:
			d = d.normalized() * stick_r
		joy_vec = d / stick_r

func _restart() -> void:
	hp = max_hp
	shield = max_shield
	regen_t = 0.0
	score = 0
	coins = 0
	wave = 1
	max_knives = clampi(3 + GameState.extra_knives, 3, 8)
	ammo = max_knives
	started = false
	wave_t = 0.0
	spawn_t = 0.0
	wave_quota = 0
	wave_killed = 0
	wave_gap = 0.0
	wave = 0
	px = W * 0.5
	py = 1160.0
	mobs.clear()
	projectiles.clear()
	knives.clear()
	drops.clear()
	over = false
	started = false
	shop_panel.visible = true
	_refresh_shop()
	_spawn_mob()

func _throw_at(target: Vector2) -> void:
	if paused or over:
		return
	if ammo <= 0:
		AudioManager.play("deny")
		return
	var from := Vector2(px, py - 30.0)
	var dir := (target - from).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	ammo -= 1
	AudioManager.play("throw")
	rig_play("attack")
	knives.append({"x": from.x, "y": from.y, "sx": from.x, "sy": from.y, "vx": dir.x * 950.0 * GameState.class_bonus("throw"), "vy": dir.y * 950.0 * GameState.class_bonus("throw"), "straight": true})

func _throw_auto() -> void:
	if ammo <= 0:
		AudioManager.play("deny")
		return
	ammo -= 1
	AudioManager.play("throw")
	if GameState.auto_aim:
		knives.append({"x": px, "y": py - 30.0})
	else:
		knives.append({"x": px, "y": py - 30.0, "sx": px, "sy": py - 30.0, "vx": 0.0, "vy": -950.0, "straight": true})

func _process(dt: float) -> void:
	_anim_t += dt
	if replay_btn != null:
		replay_btn.visible = over
	if over:
		queue_redraw()
		return
	if not GameState.arena_tutorial_done:
		queue_redraw()
		return
	if not started:
		queue_redraw()
		return
	t_anim += dt
	flash = max(0.0, flash - dt * 2.2)
	shake = max(0.0, shake - dt * 45.0)
	if slowmo_t > 0.0:
		slowmo_t -= dt
		if slowmo_t <= 0.0:
			Engine.time_scale = 1.0
	elif hitstop_t > 0.0:
		hitstop_t -= dt / maxf(Engine.time_scale, 0.1)
		if hitstop_t <= 0.0:
			Engine.time_scale = 1.0
	var dp2: Array = []
	for dp in dmg_pop:
		dp["t"] = float(dp["t"]) + dt
		dp["y"] = float(dp["y"]) - 40.0 * dt
		if float(dp["t"]) < 0.8:
			dp2.append(dp)
	dmg_pop = dp2
	banner_t = max(0.0, banner_t - dt)
	combo_t = max(0.0, combo_t - dt)
	toast_t = max(0.0, toast_t - dt)
	if combo_t <= 0.0:
		combo = 0
	var keep_r: Array = []
	for r in rings:
		r["t"] = float(r["t"]) - dt
		r["rad"] = float(r["rad"]) + dt * 220.0
		if float(r["t"]) > 0.0:
			keep_r.append(r)
	rings = keep_r
	position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) if shake > 0.0 else Vector2.ZERO
	# радиус стика зависит от сложности (волны)
	stick_r = clamp(66.0 - float(wave) * 2.0, 44.0, 66.0) * GameState.joy_scale
	var mv := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.y += 1.0
	if Input.is_action_just_pressed("ui_accept"):
		_throw_auto()
	if mv.length() > 1.0:
		mv = mv.normalized()
	if joy_on and joy_vec.length() > DEAD:
		mv = joy_vec.normalized() * clamp((joy_vec.length() - DEAD) / (1.0 - DEAD), 0.0, 1.0)
	px = clamp(px + mv.x * MOVE_SPEED * dt, 50.0, W - 50.0)
	py = clamp(py + mv.y * MOVE_SPEED * dt, AREA_TOP, field_bottom)

	wave_t += dt
	if false and wave_t > 15.0:
		wave_t = 0.0
		wave += 1
		if not damaged and GameState.unlock_arena_ach("no_damage"):
			_ach_toast(tr("Без единой царапины"))
		damaged = false
		if wave == 100:
			GameState.extra_knives = mini(GameState.extra_knives + 1, 4)
			GameState.save_settings()
			ammo += 1
			toast_text = tr("100 ВОЛН! ПОСТОЯННЫЙ НОЖ +1")
			toast_col = Color(1.0, 0.85, 0.3)
			toast_t = 3.0
		if wave == 5 and GameState.chapter_quest == "mobs":
			GameState.chapter_quest = "shop"
			GameState.save_settings()
			_toast_line(tr("ЗАЙДИ В МАГАЗИН: МЕЧ · БРОНЯ · ЩИТ"))
		if wave == 5 and GameState.unlock_arena_ach("wave5"):
			_ach_toast(tr("ВОЛНА 5"))
		if wave == 10 and GameState.unlock_arena_ach("wave10"):
			_ach_toast(tr("ВОЛНА 10"))
		if wave == 20 and GameState.unlock_arena_ach("wave20"):
			_ach_toast(tr("ОПЕРАТОР"))
		banner_n = wave
		banner_t = 1.6
		AudioManager.play("level")
	spawn_t += dt
	if wave_quota <= 0:
		wave += 1
		wave_quota = 1 if _rush_mode else mini(3 + wave, 12)
		wave_killed = 0
		banner_n = wave
		banner_t = 1.6
		rig_play("win")
		AudioManager.play("level")
		if wave == 5 and GameState.unlock_arena_ach("wave5"):
			_ach_toast(tr("ВОЛНА 5"))
		if wave == 10 and GameState.unlock_arena_ach("wave10"):
			_ach_toast(tr("ВОЛНА 10"))
		if wave == 20 and GameState.unlock_arena_ach("wave20"):
			_ach_toast(tr("ОПЕРАТОР"))
		if wave == 100:
			GameState.extra_knives = mini(GameState.extra_knives + 1, 4)
			GameState.save_settings()
			ammo += 1
	if wave_killed < wave_quota and mobs.size() < mini(wave_quota, 6) and spawn_t > 0.55:
		spawn_t = 0.0
		_spawn_mob()
		wave_killed += 1
	if mobs.is_empty() and wave_killed >= wave_quota:
		wave_gap += dt
		if wave_gap > 1.8:
			wave_gap = 0.0
			wave_quota = 0
			if not damaged and GameState.unlock_arena_ach("no_damage"):
				_ach_toast(tr("Без единой царапины"))
			damaged = false

	for m in mobs:
		m["y"] = float(m["y"]) + float(m["speed"]) * dt
		m["t"] = float(m["t"]) + dt
		m["flash"] = max(0.0, float(m.get("flash", 0.0)) - dt * 3.5)
		if float(m["t"]) >= float(m["cd"]):
			m["t"] = 0.0
			var p: Dictionary = PROJ[str(m["proj"])]
			var dx: float = px - float(m["x"])
			var dy: float = py - float(m["y"])
			var dist: float = max(1.0, sqrt(dx * dx + dy * dy))
			var spd: float = float(p["speed"])
			projectiles.append({"x": m["x"], "y": m["y"], "vx": dx / dist * spd, "vy": dy / dist * spd,
				"r": float(p["r"]), "dmg": float(p["dmg"]), "col": p["col"], "kind": str(m["proj"])})

	var keep_p: Array = []
	for p in projectiles:
		p["x"] = float(p["x"]) + float(p["vx"]) * dt
		p["y"] = float(p["y"]) + float(p["vy"]) * dt
		if float(p["y"]) > H + 40.0 or float(p["x"]) < -60.0 or float(p["x"]) > W + 60.0:
			continue
		var dxp: float = float(p["x"]) - px
		var dyp: float = float(p["y"]) - py
		var rr: float = float(p["r"]) + 24.0
		if dxp * dxp + dyp * dyp < rr * rr:
			var dmg: float = float(p["dmg"])
			regen_t = 0.0
			flash = 0.65
			shake = 3.5
			AudioManager.play("hit")
			if shield > 0.0:
				rig_play("block")
				shield -= dmg
				blocked_dmg += dmg
				if blocked_dmg >= 1000.0 and GameState.unlock_arena_ach("shield_master"):
					_ach_toast(tr("ЩИТ-МАСТЕР"))
				if shield < 0.0:
					damaged = true
					hp += shield
					shield = 0.0
			else:
				damaged = true
				rig_play("hurt")
				hp -= dmg
			if hp <= 0.0:
				hp = 0.0
				Telemetry.event("arena_end", {"wave": wave, "score": score, "coins": coins})

				if (_rush_mode or _survival_arena) and wave > 1:
					var rec: bool = GameState.record_mode_wave(_rush_mode, wave - 1)
					if rec:
						toast_text = tr("НОВЫЙ РЕКОРД: %d") % (wave - 1)
						toast_col = Color(1.0, 0.85, 0.3)
						toast_t = 3.0
				if not damaged and GameState.unlock_arena_ach("no_damage"):
					_ach_toast(tr("Без единой царапины"))
				over = true
			continue
		keep_p.append(p)
	projectiles = keep_p

	var keep_k: Array = []
	for kn in knives:
		if bool(kn.get("back", false)):
			var bx: float = px - float(kn["x"])
			var by: float = py - float(kn["y"])
			var bd: float = sqrt(bx * bx + by * by)
			var hits_b: Array = kn.get("hit", [])
			for m in mobs:
				if int(m.get("id", -1)) in hits_b:
					continue
				var db: float = Vector2(float(m["x"]) - float(kn["x"]), float(m["y"]) - float(kn["y"])).length()
				if db < float(m["r"]) + 18.0:
					hits_b.append(int(m.get("id", -1)))
					m["hp"] = float(m["hp"]) - 15.0
					m["flash"] = 0.18
					rings.append({"x": m["x"], "y": m["y"], "t": 0.3, "rad": float(m["r"])})
					if float(m["hp"]) <= 0.0:
						score += 10 + wave
						combo += 1
						combo_t = 2.0
						mobs.erase(m)
						break
			kn["hit"] = hits_b
			if bd < 30.0:
				ammo = mini(ammo + 1, max_knives)
				AudioManager.play("return")
				continue
			kn["x"] = float(kn["x"]) + bx / bd * 1100.0 * dt
			kn["y"] = float(kn["y"]) + by / bd * 1100.0 * dt
			keep_k.append(kn)
			continue
		var target: Dictionary = {}
		if kn.has("straight"):
			kn["x"] = float(kn["x"]) + float(kn["vx"]) * dt
			kn["y"] = float(kn["y"]) + float(kn["vy"]) * dt
			var sx: float = float(kn.get("sx", px))
			var sy: float = float(kn.get("sy", py))
			var flown: float = Vector2(float(kn["x"]) - sx, float(kn["y"]) - sy).length()
			if flown > 820.0 or float(kn["x"]) < -60.0 or float(kn["x"]) > float(W) + 60.0 or float(kn["y"]) < -60.0 or float(kn["y"]) > field_bottom + 60.0:
				kn["back"] = true
				keep_k.append(kn)
				continue
			for m in mobs:
				var ds: float = Vector2(float(m["x"]) - float(kn["x"]), float(m["y"]) - float(kn["y"])).length()
				if ds < float(m["r"]) + 16.0:
					target = m
					break
			if target.is_empty():
				keep_k.append(kn)
				continue
		else:
			var best: float = 1e9
			var hits0: Array = kn.get("hit", [])
			for m in mobs:
				if int(m.get("id", -1)) in hits0:
					continue
				var d: float = Vector2(float(m["x"]) - float(kn["x"]), float(m["y"]) - float(kn["y"])).length()
				if d < best:
					best = d
					target = m
			if target.is_empty():
				kn["back"] = true
				keep_k.append(kn)
				continue
			var dir: Vector2 = Vector2(float(target["x"]) - float(kn["x"]), float(target["y"]) - float(kn["y"])).normalized()
			kn["x"] = float(kn["x"]) + dir.x * 900.0 * dt
			kn["y"] = float(kn["y"]) + dir.y * 900.0 * dt
			var dd: float = Vector2(float(target["x"]) - float(kn["x"]), float(target["y"]) - float(kn["y"])).length()
			if dd > float(target["r"]) + 14.0:
				keep_k.append(kn)
				continue
		if not target.is_empty():
			if kn.has("straight"):
				kn.erase("straight")
			target["hp"] = float(target["hp"]) - 15.0
			target["flash"] = 0.18
			hitstop_t = 0.045
			Engine.time_scale = 0.15
			dmg_pop.append({"x": float(target["x"]), "y": float(target["y"]) - float(target["r"]), "txt": "15", "t": 0.0})
			if float(target["hp"]) <= 0.0:
				score += 10 + wave
				combo += 1
				combo_t = 2.0
				best_combo = maxi(best_combo, combo)
				if GameState.unlock_arena_ach("first_blood"):
					_ach_toast(tr("ПЕРВАЯ КРОВЬ"))
				if combo >= 5 and GameState.unlock_arena_ach("combo5"):
					_ach_toast(tr("КОМБО x5"))
				if combo >= 10 and GameState.unlock_arena_ach("combo10"):
					_ach_toast(tr("КОМБО x10"))
				if str(target["kind"]) == "boss" and GameState.unlock_arena_ach("boss1"):
					_ach_toast(tr("ПЕРВЫЙ БОСС"))
				rings.append({"x": target["x"], "y": target["y"], "t": 0.35, "rad": float(target["r"])})
				AudioManager.play("hit_crit")
				if randf() < _drop_chance():
					var rr_kill := randf()
					if rr_kill < 0.30:
						drops.append({"x": target["x"], "y": target["y"], "vy": 90.0, "kind": "health"})
					elif rr_kill < 0.75:
						drops.append({"x": target["x"], "y": target["y"], "vy": 90.0, "kind": "loot", "rar": _roll_loot()})
					else:
						drops.append({"x": target["x"], "y": target["y"], "vy": 90.0, "kind": "coin"})
				if str(target["kind"]) == "boss":
					slowmo_t = 0.5
					Engine.time_scale = 0.35
					max_knives = mini(max_knives + 1, 5)
					ammo += 1
					toast_text = tr("БОСС ПАЛ! НОЖ +1 (%d/5)") % max_knives
					toast_col = Color(1.0, 0.85, 0.3)
					toast_t = 2.2
				mobs.erase(target)
			var hs: Array = kn.get("hit", [])
			hs.append(int(target.get("id", -1)))
			kn["hit"] = hs
			var more := false
			for m2 in mobs:
				if int(m2.get("id", -1)) not in hs:
					more = true
					break
			kn["back"] = not more
		keep_k.append(kn)
	knives = keep_k

	var keep_d: Array = []
	for dp in drops:
		dp["y"] = float(dp["y"]) + float(dp["vy"]) * dt
		if float(dp["y"]) > H + 30.0:
			continue
		var dxd: float = float(dp["x"]) - px
		var dyd: float = float(dp["y"]) - py
		if dxd * dxd + dyd * dyd < 40.0 * 40.0:
			if str(dp["kind"]) == "health":
				hp = min(max_hp, hp + 12.0)
				AudioManager.play("shield")
			elif str(dp["kind"]) == "loot":
				var ri: int = int(dp.get("rar", 0))
				var L: Dictionary = LOOT[clampi(ri, 0, 3)]
				var rc: int = maxi(1, int(round(float(L["coins"]) * _reward_mult())))
				coins += rc
				GameState.add_coins(rc)
				score += int(L["score"])
				if ri >= 2:
					relics += 1
					GameState.relics_total += 1
					GameState.save_settings()
					if GameState.relics_total >= 10 and GameState.unlock_arena_ach("collector"):
						_ach_toast(tr("КОЛЛЕКЦИОНЕР"))
					if ri == 3 and GameState.unlock_arena_ach("legendary"):
						_ach_toast(tr("КЛЮЧ РАЗЛОМА"))
				toast_text = str(L["name"])
				toast_col = L["col"]
				toast_t = 1.8
				AudioManager.play("crystal" if ri >= 2 else "coin")
			else:
				coins += 1
				GameState.coins += 1
				if GameState.coins >= 100 and GameState.unlock_arena_ach("coins100"):
					_ach_toast(tr("100 МОНЕТ"))
				score += 2
				AudioManager.play("coin")
			continue
		keep_d.append(dp)
	drops = keep_d

	var keep_m: Array = []
	for m in mobs:
		if float(m["y"]) > H + 40.0:
			continue
		keep_m.append(m)
	mobs = keep_m

	if hp <= 0.0:
		hp = 0.0
		if not over:
			AudioManager.play("defeat")
			GameState.save_settings()
		over = true
	else:
		regen_t += dt
		if regen_t > 2.0 and shield < max_shield:
			shield = min(max_shield, shield + 12.0 * dt)
	queue_redraw()

func _draw() -> void:
	if arena_bg:
		draw_texture_rect(arena_bg, Rect2(0, 0, W, H), false)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.06, 0.07, 0.12))
	for m in mobs:
		var mx: float = float(m["x"])
		var my: float = float(m["y"])
		var mr: float = float(m["r"])
		var texs = mob_tex.get(str(m["kind"]), [])
		if not texs.is_empty():
			var tx: Texture2D = texs[int(m.get("var", 0)) % texs.size()]
			var msz: float = minf(mr * 3.2, W * 0.30)
			var ph: float = float(m.get("var", 0)) * 1.7 + mx * 0.01
			var mbob: float = sin(_anim_t * 3.6 + ph) * (3.4 if msz > 90.0 else 2.2)
			var msw: float = sin(_anim_t * 2.4 + ph) * 0.045
			draw_set_transform(Vector2(mx, my + mbob), msw, Vector2.ONE)
			draw_texture_rect(tx, Rect2(-msz * 0.5, -msz * 0.5, msz, msz), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_circle(Vector2(mx, my), mr, m["col"])
			draw_circle(Vector2(mx, my), mr * 0.55, Color(0.05, 0.05, 0.08, 0.8))
		var fl: float = float(m.get("flash", 0.0))
		if fl > 0.0:
			draw_circle(Vector2(mx, my), mr + 2.0, Color(1, 1, 1, minf(0.9, fl * 4.0)))
		var w: float = mr * 2.0 * (float(m["hp"]) / float(m["max"]))
		draw_rect(Rect2(mx - mr, my - mr - 12.0, w, 5.0), Color(0.9, 0.25, 0.25))
	for p in projectiles:
		var qx: float = float(p["x"])
		var qy: float = float(p["y"])
		var pt: Texture2D = proj_tex.get(str(p["kind"]), null)
		if pt != null:
			var psz: float = float(p["r"]) * 4.5
			draw_texture_rect(pt, Rect2(qx - psz * 0.5, qy - psz * 0.5, psz, psz), false)
			continue
		if str(p["kind"]) == "needle":
			var nx: float = qx - float(p["vx"]) * 0.03
			var ny: float = qy - float(p["vy"]) * 0.03
			draw_line(Vector2(nx, ny), Vector2(qx, qy), Color(1, 0.75, 0.75, 0.35), 7.0)
			draw_line(Vector2(nx, ny), Vector2(qx, qy), p["col"], 3.0)
			draw_circle(Vector2(qx, qy), 3.0, Color(1, 1, 1, 0.9))
		elif str(p["kind"]) == "shuriken":
			var rr2: float = float(p["r"])
			for i in 4:
				var ang: float = t_anim * 9.0 + float(i) * PI * 0.5
				var tip := Vector2(qx + cos(ang) * rr2, qy + sin(ang) * rr2)
				var side := Vector2(qx + cos(ang + 0.7) * rr2 * 0.35, qy + sin(ang + 0.7) * rr2 * 0.35)
				draw_line(Vector2(qx, qy), tip, p["col"], 4.0)
				draw_line(Vector2(qx, qy), side, p["col"], 3.0)
			draw_circle(Vector2(qx, qy), 4.0, Color(1, 1, 1, 0.85))
		else:
			var sr: float = float(p["r"])
			draw_circle(Vector2(qx + 2.0, qy + 3.0), sr, Color(0, 0, 0, 0.35))
			draw_circle(Vector2(qx, qy), sr, p["col"])
			draw_circle(Vector2(qx - sr * 0.3, qy - sr * 0.3), sr * 0.35, Color(1, 1, 1, 0.25))
	for dp in drops:
		var ddx: float = float(dp["x"])
		var ddy: float = float(dp["y"])
		if str(dp["kind"]) == "health":
			draw_circle(Vector2(ddx, ddy), 14.0, Color(0.25, 0.95, 0.45))
			draw_line(Vector2(ddx - 7.0, ddy), Vector2(ddx + 7.0, ddy), Color(1, 1, 1), 3.0)
			draw_line(Vector2(ddx, ddy - 7.0), Vector2(ddx, ddy + 7.0), Color(1, 1, 1), 3.0)
		elif str(dp["kind"]) == "loot":
			var L: Dictionary = LOOT[clampi(int(dp.get("rar", 0)), 0, 3)]
			var lc: Color = L["col"]
			var pts := PackedVector2Array([
				Vector2(ddx, ddy - 14.0), Vector2(ddx + 12.0, ddy),
				Vector2(ddx, ddy + 14.0), Vector2(ddx - 12.0, ddy),
			])
			draw_colored_polygon(pts, lc)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(1, 1, 1, 0.9), 2.0)
		else:
			draw_circle(Vector2(ddx, ddy), 12.0, Color(0.95, 0.8, 0.25))
			draw_circle(Vector2(ddx, ddy), 7.0, Color(1.0, 0.92, 0.55))
	for kn in knives:
		var kx: float = float(kn["x"])
		var ky: float = float(kn["y"])
		if knife_tex:
			draw_texture_rect(knife_tex, Rect2(kx - 18.0, ky - 18.0, 36.0, 36.0), false)
		else:
			draw_circle(Vector2(kx, ky), 10.0, Color(0.95, 0.8, 0.3))
	# игрок (масштаб 1.45 — корабль не должен проигрывать мобам)
	if _ground_mode and (rig_torso != null or avatar_tex != null):
		_draw_rig(px, py, 196.0, 196.0 * 0.72, avatar_tex.get_size())
	if _ground_mode:
		if shield > 0.0:
			var gsa: float = clampf(shield / max_shield, 0.15, 1.0)
			draw_arc(Vector2(px, py), 54.0, 0.0, TAU, 40, Color(0.55, 0.9, 1.0, 0.5 * gsa), 3.0)
		return
	var sk: Dictionary = GameState.current_skin()
	var hull: Color = sk.get("blade", Color(0.35, 0.75, 1.0))
	var glow_c: Color = sk.get("blade", Color(0.5, 0.9, 1.0)).lightened(0.35)
	draw_set_transform(Vector2(px, py), 0.0, Vector2(1.45, 1.45))
	# выхлоп
	for k in 3:
		draw_circle(Vector2(0.0, 26.0 + k * 10.0), 9.0 - k * 2.0, Color(1.0, 0.65, 0.2, 0.55))
	# корпус
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -34.0), Vector2(22.0, 14.0), Vector2(8.0, 10.0),
		Vector2(12.0, 26.0), Vector2(0.0, 18.0), Vector2(-12.0, 26.0),
		Vector2(-8.0, 10.0), Vector2(-22.0, 14.0)]), hull.darkened(0.25))
	# крылья
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18.0, 8.0), Vector2(-34.0, 24.0), Vector2(-14.0, 22.0)]), hull.darkened(0.5))
	draw_colored_polygon(PackedVector2Array([
		Vector2(18.0, 8.0), Vector2(34.0, 24.0), Vector2(14.0, 22.0)]), hull.darkened(0.5))
	# кабина
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -20.0), Vector2(9.0, 4.0), Vector2(0.0, 8.0), Vector2(-9.0, 4.0)]), glow_c)
	# двигатели
	draw_line(Vector2(-10.0, 24.0), Vector2(-10.0, 34.0), Color(1.0, 0.6, 0.2, 0.8), 4.0)
	draw_line(Vector2(10.0, 24.0), Vector2(10.0, 34.0), Color(1.0, 0.6, 0.2, 0.8), 4.0)
	# контур корпуса
	draw_arc(Vector2(0.0, -2.0), 30.0, 0.0, TAU, 24, glow_c.lightened(0.15), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# ЩИТ = аура вокруг (не перекрывает обзор)
	if shield > 0.0:
		var sa: float = clampf(shield / max_shield, 0.15, 1.0)
		var pulse: float = 1.0 + 0.05 * sin(Time.get_ticks_msec() / 260.0)
		draw_circle(Vector2(px, py), 54.0 * pulse, Color(glow_c.r, glow_c.g, glow_c.b, 0.10 * sa))
		draw_arc(Vector2(px, py), 54.0 * pulse, 0.0, TAU, 40, Color(glow_c.r, glow_c.g, glow_c.b, 0.55 * sa), 3.0)
		draw_arc(Vector2(px, py), 60.0 * pulse, 0.0, TAU, 40, Color(1, 1, 1, 0.22 * sa), 2.0)
	# ПЛАВАЮЩИЙ ДЖОЙСТИК (только пока тронут)
	if joy_on:
		draw_circle(joy_origin, stick_r, Color(0.15, 0.18, 0.25, 0.55))
		draw_arc(joy_origin, stick_r, 0.0, TAU, 32, Color(0.4, 0.8, 1.0, 0.6), 2.0)
		draw_circle(joy_origin + joy_vec * stick_r, 22.0, Color(0.4, 0.8, 1.0, 0.85))
	# HUD
	draw_set_transform(Vector2(0, 40))
	draw_rect(Rect2(40, 56, W - 80, 16), Color(0.12, 0.12, 0.18))
	var ratio: float = hp / max_hp
	var col := Color(0.9, 0.25, 0.25)
	if ratio > 0.6:
		col = Color(0.3, 0.85, 0.5)
	elif ratio > 0.3:
		col = Color(0.95, 0.75, 0.25)
	draw_rect(Rect2(42, 58, (W - 84) * ratio, 12), col)
	draw_rect(Rect2(40, 76, W - 80, 8), Color(0.10, 0.12, 0.20))
	draw_rect(Rect2(42, 77, (W - 84) * (shield / max_shield), 6), glow_c)
	draw_rect(Rect2(40, 56, W - 80, 16), glow_c.darkened(0.4), false, 2.0)
	draw_rect(Rect2(40, 76, W - 80, 8), glow_c.darkened(0.4), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(44, 44), tr("HP %d/%d   ЩИТ %d") % [int(hp), int(max_hp), int(shield)], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1))
	if combo > 1:
		draw_string(ThemeDB.fallback_font, Vector2(0, 240), tr("КОМБО x%d") % combo, HORIZONTAL_ALIGNMENT_CENTER, W, 34, Color(1.0, 0.85, 0.3, minf(1.0, combo_t)))
	if toast_t > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(0, 300), toast_text, HORIZONTAL_ALIGNMENT_CENTER, W, 30, Color(toast_col.r, toast_col.g, toast_col.b, minf(1.0, toast_t)))
	for r in rings:
		draw_arc(Vector2(float(r["x"]), float(r["y"])), float(r["rad"]), 0.0, TAU, 28, Color(1, 0.9, 0.5, maxf(0.0, float(r["t"]) / 0.35)), 4.0)
	var hint := "Тяни в поле - движение · Тап - нож · WASD/Пробел"
	if GameState.control_mode == "keyboard":
		if DisplayServer.is_touchscreen_available():
			hint = tr("Свайп по полю — движение · тап — бросок · удерживай — цель")
		else:
			hint = tr("WASD/стрелки - движение · ПКМ/пробел - бросок · нажимай и тяни - цель")
	elif GameState.control_mode == "touch":
		hint = tr("Тяни в поле - движение · Тап - бросок ножа")
	draw_string(ThemeDB.fallback_font, Vector2(44, 190), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.9, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(44, 150), tr("СЧЁТ %d · МОНЕТЫ %d · ВОЛНА %d · НОЖИ %d") % [score, coins, wave, ammo], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1))
	draw_set_transform(Vector2.ZERO)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(1.0, 0.15, 0.2, 0.35 * flash))
	for dp in dmg_pop:
		var da: float = 1.0 - float(dp["t"]) / 0.8
		draw_string(ThemeDB.fallback_font, Vector2(float(dp["x"]) - 12.0, float(dp["y"])), str(dp["txt"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(1.0, 0.95, 0.5, da))
	if banner_t > 0.0:
		var a: float = minf(1.0, banner_t)
		draw_rect(Rect2(0, H * 0.72, W, 70), Color(0.05, 0.08, 0.12, 0.65 * a))
		draw_string(ThemeDB.fallback_font, Vector2(0, H * 0.72 + 50), tr("ВОЛНА %d") % banner_n, HORIZONTAL_ALIGNMENT_CENTER, W, 38, Color(0.55, 0.95, 0.75, a))
	if not GameState.arena_tutorial_done:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.62))
		draw_string(ThemeDB.fallback_font, Vector2(0, 420), tr("ЗАЩИТА РУБЕЖА") if GameState.frontier_mode else tr("АРЕНА РАЗЛОМА"), HORIZONTAL_ALIGNMENT_CENTER, W, 40, Color(0.6, 0.95, 0.8))
		draw_string(ThemeDB.fallback_font, Vector2(0, 500), tr("Тяни по полю — движение"), HORIZONTAL_ALIGNMENT_CENTER, W, 26, Color(1, 1, 1))
		draw_string(ThemeDB.fallback_font, Vector2(0, 545), tr("Тап — бросок ножа"), HORIZONTAL_ALIGNMENT_CENTER, W, 26, Color(1, 1, 1))
		draw_string(ThemeDB.fallback_font, Vector2(0, 590), tr("II / ESC — пауза"), HORIZONTAL_ALIGNMENT_CENTER, W, 26, Color(1, 1, 1))
		draw_string(ThemeDB.fallback_font, Vector2(0, 700), tr("НАЖМИ, ЧТОБЫ НАЧАТЬ"), HORIZONTAL_ALIGNMENT_CENTER, W, 24, Color(1.0, 0.85, 0.3))
	if over:
		draw_rect(Rect2(0, H * 0.38, W, 180), Color(0, 0, 0, 0.75))
		draw_string(ThemeDB.fallback_font, Vector2(0, H * 0.38 + 70), tr("ПОРАЖЕНИЕ"), HORIZONTAL_ALIGNMENT_CENTER, W, 46, Color(1, 0.35, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(0, H * 0.38 + 120), "Счёт: %d - ЛКМ для рестарта" % score, HORIZONTAL_ALIGNMENT_CENTER, W, 24, Color(1, 1, 1))

func _roll_loot() -> int:
	var total := 0
	for L in LOOT:
		total += int(L["w"])
	var r := randi() % maxi(total, 1)
	var acc := 0
	for i in LOOT.size():
		acc += int(LOOT[i]["w"])
		if r < acc:
			return i
	return 0

func _ach_toast(txt: String) -> void:
	toast_text = txt
	toast_col = Color(1.0, 0.85, 0.3)
	toast_t = 2.0

func _reward_mult() -> float:
	match GameState.difficulty:
		"easy":
			return 0.7
		"hard":
			return 1.5
		"survival":
			return 1.3
		_:
			return 1.0

func _diff_cd_mult() -> float:
	match GameState.difficulty:
		"easy":
			return 1.35
		"hard":
			return 0.80
		"survival":
			return 0.72
		_:
			return 1.0

func _drop_chance() -> float:
	if not GameState.arena_drops:
		return 0.0
	if GameState.survival_mode:
		return 0.05
	if GameState.difficulty == "easy":
		return 0.30
	if GameState.difficulty == "hard":
		return 0.16
	return 0.22

func _build_shop() -> void:
	shop_layer = CanvasLayer.new()
	shop_layer.layer = 11
	shop_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(shop_layer)
	shop_panel = Control.new()
	shop_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	shop_layer.add_child(shop_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_panel.add_child(dim)
	var vb := VBoxContainer.new()
	vb.position = Vector2(W * 0.5 - 170.0, 300.0)
	vb.size = Vector2(340.0, 560.0)
	vb.add_theme_constant_override("separation", 10)
	shop_panel.add_child(vb)
	var t := Label.new()
	t.text = tr("ПЕРЕД РАУНДОМ")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	vb.add_child(t)
	shop_info = Label.new()
	shop_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_info.add_theme_font_size_override("font_size", 16)
	vb.add_child(shop_info)
	vb.add_child(_shop_btn(tr("+1 НОЖ — 200"), func() -> void: _shop_buy("knife1")))
	vb.add_child(_shop_btn(tr("+2 НОЖА — 350"), func() -> void: _shop_buy("knife2")))
	vb.add_child(_shop_btn(tr("ЩИТ +50 — 100"), func() -> void: _shop_buy("shield")))
	vb.add_child(_shop_btn(tr("HP +50 — 150"), func() -> void: _shop_buy("hp")))
	vb.add_child(_shop_btn(tr("НАЧАТЬ"), func() -> void: _start_round()))
	vb.add_child(_shop_btn(tr("В МЕНЮ"), func() -> void: _to_menu()))
	_refresh_shop()
	shop_panel.visible = GameState.arena_tutorial_done

func _shop_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 56)
	b.pressed.connect(cb)
	return b

func _refresh_shop() -> void:
	if shop_info != null:
		shop_info.text = tr("Монеты: %d | Ножи: %d | Щит: %d | HP: %d") % [GameState.coins, max_knives, int(shield), int(hp)]

func _shop_buy(kind: String) -> void:
	var price := 0
	if kind == "knife1":
		price = 200
	elif kind == "knife2":
		price = 350
	elif kind == "shield":
		price = 100
	elif kind == "hp":
		price = 150
	if GameState.coins < price:
		AudioManager.play("deny")
		return
	GameState.coins -= price
	if kind == "knife1":
		max_knives = mini(max_knives + 1, 5)
		ammo += 1
	elif kind == "knife2":
		max_knives = mini(max_knives + 2, 5)
		ammo += 2
	elif kind == "shield":
		max_shield += 50.0
		shield = max_shield
	elif kind == "hp":
		max_hp += 50.0
		hp = max_hp
	GameState.save_settings()
	AudioManager.play("buy")
	_refresh_shop()

func _start_round() -> void:
	started = true
	ammo = max_knives
	shop_panel.visible = false
	wave_t = 0.0
	spawn_t = 0.0

func _build_pause() -> void:
	_pl = CanvasLayer.new()
	_pl.layer = 12
	_pl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pl)
	_pm = Control.new()
	_pm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pm.process_mode = Node.PROCESS_MODE_ALWAYS
	_pm.visible = false
	_pm.mouse_filter = Control.MOUSE_FILTER_STOP
	_pl.add_child(_pm)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pm.add_child(dim)
	var vb := VBoxContainer.new()
	vb.position = Vector2(W * 0.5 - 150.0, H * 0.40)
	vb.size = Vector2(300.0, 200.0)
	_pm.add_child(vb)
	var b1 := Button.new()
	b1.text = tr("ПРОДОЛЖИТЬ")
	b1.custom_minimum_size = Vector2(300, 60)
	b1.pressed.connect(_toggle_pause)
	vb.add_child(b1)
	var b2 := Button.new()
	b2.text = tr("В МЕНЮ")
	b2.custom_minimum_size = Vector2(300, 60)
	b2.pressed.connect(_to_menu)
	vb.add_child(b2)
	var pb := Button.new()
	pb.text = "II"
	pb.position = Vector2(W - 94.0, 96.0)
	pb.size = Vector2(64, 48)
	pb.process_mode = Node.PROCESS_MODE_ALWAYS
	pb.z_index = 100
	pb.pressed.connect(_toggle_pause)
	_pl.add_child(pb)

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	_pm.visible = paused

func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _build_action_buttons() -> void:
	var x: float = 574.0
	if GameState.btn_side == "left":
		x = 26.0
	var melee_btn := Button.new()
	melee_btn.text = "УДАР"
	melee_btn.position = Vector2(x, 1080.0)
	melee_btn.size = Vector2(120, 120)
	melee_btn.modulate = Color(1, 1, 1, 0.55)
	melee_btn.pressed.connect(_melee)
	_pl.add_child(melee_btn)
	var throw_btn := Button.new()
	throw_btn.text = "БРОСОК"
	throw_btn.position = Vector2(x - 132.0 if GameState.btn_side == "right" else x + 132.0, 1080.0)
	throw_btn.size = Vector2(116, 116)
	throw_btn.modulate = Color(1, 1, 1, 0.55)
	throw_btn.pressed.connect(_throw_auto)
	_pl.add_child(throw_btn)


func _melee() -> void:
	if paused or over:
		return
	AudioManager.play("hit")
	var reach: float = 105.0
	var hit_any := false
	for m in mobs:
		var d: float = Vector2(float(m["x"]) - px, float(m["y"]) - py).length()
		if d <= reach + float(m["r"]):
			m["hp"] = float(m["hp"]) - 25.0
			m["flash"] = 0.2
			dmg_pop.append({"x": float(m["x"]), "y": float(m["y"]) - float(m["r"]), "txt": "25", "t": 0.0})
			rings.append({"x": m["x"], "y": m["y"], "t": 0.35, "rad": float(m["r"])})
			if float(m["hp"]) <= 0.0:
				score += 10 + wave
				combo += 1
				combo_t = 2.0
				mobs.erase(m)
			hit_any = true
			break
	if not hit_any:
		rings.append({"x": px, "y": py, "t": 0.25, "rad": 70.0})


func _toast_line(txt: String) -> void:
	toast_text = txt
	toast_col = Color(1.0, 0.85, 0.3)
	toast_t = 3.0


func rig_play(state: String) -> void:
	_rig_state = state
	_rig_t = 0.0


func _draw_rig(px: float, py: float, gh: float, gw: float, ts: Vector2) -> void:
	# ЕСТЬ ЧАСТИ — настоящий риг из отдельных слоёв
	if rig_torso != null:
		_rig_t += get_process_delta_time()
		var br: float = sin(_anim_t * 4.2) * 1.8
		var stride: float = sin(_anim_t * 7.0) * 0.13
		var lean: float = 0.0
		var head_dx: float = 0.0
		match _rig_state:
			"attack":
				lean = 0.12 * sin(clampf(_rig_t / 0.28, 0.0, 1.0) * PI)
				head_dx = 6.0
				if _rig_t > 0.32:
					rig_play("idle")
			"block":
				lean = -0.06
				if _rig_t > 0.6:
					rig_play("idle")
			"hurt":
				head_dx = sin(_rig_t * 55.0) * 4.0 * clampf(1.0 - _rig_t / 0.4, 0.0, 1.0)
				if _rig_t > 0.45:
					rig_play("idle")
			"win":
				if _rig_t > 1.2:
					rig_play("idle")
		var hip: Vector2 = Vector2(px, py - gh * 0.40)
		# ноги
		var lw: float = rig_leg_l.get_width() * (gh * 0.46 / rig_leg_l.get_height())
		draw_set_transform(Vector2(px - gw * 0.15, hip.y), -stride, Vector2.ONE)
		draw_texture_rect(rig_leg_l, Rect2(-lw * 0.5, 0, lw, gh * 0.46), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_set_transform(Vector2(px + gw * 0.15, hip.y), stride, Vector2.ONE)
		draw_texture_rect(rig_leg_r, Rect2(-lw * 0.5, 0, lw, gh * 0.46), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# торс
		var tw2: float = rig_torso.get_width() * (gh * 0.46 / rig_torso.get_height())
		var th2: float = gh * 0.46
		draw_set_transform(Vector2(px, hip.y - th2 * 0.02), lean, Vector2.ONE)
		draw_texture_rect(rig_torso, Rect2(-tw2 * 0.5, -th2 + br, tw2, th2), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# голова
		var hw2: float = rig_head.get_width() * (gh * 0.24 / rig_head.get_height())
		draw_set_transform(Vector2(px + head_dx, hip.y - th2 + br * 1.4 - gh * 0.02), lean * 1.3, Vector2.ONE)
		draw_texture_rect(rig_head, Rect2(-hw2 * 0.5, -gh * 0.24, hw2, gh * 0.24), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	_rig_t += get_process_delta_time()
	var breathing: float = sin(_anim_t * 4.2) * 2.6
	var sway: float = sin(_anim_t * 5.4) * 2.2
	var lean: float = -abs(sin(_anim_t * 2.1)) * 1.5
	var s_legs := Vector2(sway, breathing * 0.3)
	var s_torso := Vector2(0.0, breathing + lean)
	var s_head := Vector2(0.0, breathing * 1.5 + lean * 1.6)
	var r_head := 0.0
	var r_torso := 0.0
	var crouch := 0.0
	match _rig_state:
		"attack":
			var k: float = clampf(_rig_t / 0.28, 0.0, 1.0)
			var punch: float = sin(k * PI)
			s_torso.x += 14.0 * punch
			s_head.x += 18.0 * punch
			r_torso = 0.10 * punch
			r_head = 0.16 * punch
			s_legs.y -= 4.0 * punch
			if _rig_t > 0.32:
				rig_play("idle")
		"block":
			crouch = 8.0
			s_torso.x -= 5.0
			r_torso = -0.05
			s_head.y += 3.0
			if _rig_t > 0.6:
				rig_play("idle")
		"hurt":
			var sh: float = sin(_rig_t * 60.0) * 6.0 * clampf(1.0 - _rig_t / 0.4, 0.0, 1.0)
			s_torso.x += sh
			s_head.x += sh * 1.4
			r_torso = 0.12 * clampf(1.0 - _rig_t / 0.4, 0.0, 1.0)
			if _rig_t > 0.45:
				rig_play("idle")
		"win":
			s_head.y -= 6.0 + sin(_anim_t * 8.0) * 2.0
			s_torso.y -= 4.0
			if _rig_t > 1.2:
				rig_play("idle")
	var base_y: float = py + crouch
	# ноги: две половины, попеременный шаг от бедра
	var step_amp: float = 0.10
	var stride: float = sin(_anim_t * 7.0) * step_amp
	var hip_y: float = base_y - gh * 0.42
	# левая нога
	draw_set_transform(Vector2(px - gw * 0.16 + s_legs.x, hip_y), -stride, Vector2.ONE)
	draw_texture_rect_region(avatar_tex, Rect2(-gw * 0.22, -gh * 0.02 + s_legs.y * 0.4, gw * 0.44, gh * 0.46),
		Rect2(ts.x * 0.12, ts.y * 0.56, ts.x * 0.38, ts.y * 0.44))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# правая нога
	draw_set_transform(Vector2(px + gw * 0.16 + s_legs.x, hip_y), stride, Vector2.ONE)
	draw_texture_rect_region(avatar_tex, Rect2(-gw * 0.22, -gh * 0.02 + s_legs.y * 0.4, gw * 0.44, gh * 0.46),
		Rect2(ts.x * 0.50, ts.y * 0.56, ts.x * 0.38, ts.y * 0.44))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# торс (с наклоном вокруг таза)
	draw_set_transform(Vector2(px + s_torso.x, base_y - gh * 0.36), r_torso, Vector2.ONE)
	draw_texture_rect_region(avatar_tex, Rect2(-gw * 0.5, -gh * 0.44 + s_torso.y, gw, gh * 0.46),
		Rect2(ts.x * 0.08, ts.y * 0.24, ts.x * 0.84, ts.y * 0.40))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# голова
	draw_set_transform(Vector2(px + s_head.x, base_y - gh * 0.80), r_head, Vector2.ONE)
	draw_texture_rect_region(avatar_tex, Rect2(-gw * 0.5, -gh * 0.18 + s_head.y, gw, gh * 0.28),
		Rect2(ts.x * 0.10, ts.y * 0.00, ts.x * 0.80, ts.y * 0.26))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
