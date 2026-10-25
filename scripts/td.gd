extends Node2D
## TD-ПРОТОТИП (T1): путь, 3 типа башен, волны, ядро, экономика.
## ДиП-Флеш-17, 2026-10-21. Портрет 720x1280.

const W := 720.0
const H := 1280.0
const CELL := 45.0
const GX := 16
const GY := 20
const CORE_HP := 20

var path: Array = []
var towers: Array = []
var mobs: Array = []
var beams: Array = []
var coins := 200
var core_hp := CORE_HP
var wave := 0
var wave_t := 0.0
var bounty_paid_wave := 0   # номер волны, за которую bounty уже выдан (защита от дублей) | wave whose bounty was paid (anti-duplicate)
var spawn_left := 0
var spawn_t := 0.0
var over := false
var sel_type := 0
var t_anim := 0.0
var tow_tex: Array = []
var core_tex: Texture2D = null
var mob_td_tex: Texture2D = null
var bg_tex: Texture2D = null
var replay_btn: Button
var paused := false
var _pl: CanvasLayer
var _pm: Control

const TOWER_TYPES := [
	{"name": "СТРЕЛОК", "cost": 50, "dmg": 20.0, "cd": 0.55, "range": 165.0, "col": Color(0.35, 0.75, 1.0)},
	{"name": "МОРОЗ",   "cost": 70, "dmg": 11.0, "cd": 0.9,  "range": 145.0, "col": Color(0.55, 0.9, 1.0)},
	{"name": "ЭНЕРГИЯ", "cost": 90, "dmg": 50.0, "cd": 1.4,  "range": 185.0, "col": Color(1.0, 0.55, 0.9)},
]

func _ready() -> void:
	for idx in range(3):
		var pp := "res://assets/images/packs/%s/tower-%d.png" % [GameState.style_pack, idx + 1]
		var p := "res://assets/images/td/tower-%s.png" % ["arrow", "frost", "energy"][idx]
		if ResourceLoader.exists(pp):
			tow_tex.append(load(pp))
		elif ResourceLoader.exists(p):
			tow_tex.append(load(p))
	if ResourceLoader.exists("res://assets/images/td/core.png"):
		core_tex = load("res://assets/images/td/core.png")
	if ResourceLoader.exists("res://assets/images/arena/mob-runner-1.png"):
		mob_td_tex = load("res://assets/images/arena/mob-runner-1.png")
	var pbg := "res://assets/images/packs/%s/bg.png" % GameState.style_pack
	if ResourceLoader.exists(pbg):
		bg_tex = load(pbg)
	elif ResourceLoader.exists("res://assets/images/arena/arena-bg.png"):
		bg_tex = load("res://assets/images/arena/arena-bg.png")
	path = _path_variant(randi() % 3)
	replay_btn = Button.new()
	replay_btn.text = tr("ПОВТОР")
	replay_btn.position = Vector2(W / 2 - 120.0, H * 0.5 + 40.0)
	replay_btn.size = Vector2(240, 56)
	replay_btn.visible = false
	replay_btn.pressed.connect(func() -> void:
		core_hp = CORE_HP
		coins = 200
		wave = 0
		mobs.clear()
		towers.clear()
		beams.clear()
		over = false
		path = _path_variant(randi() % 3)
		_start_wave())
	add_child(replay_btn)
	position.y = 100.0
	_start_wave()
	_build_pause()

func _path_variant(v: int) -> Array:
	if v == 0:
		return [Vector2(60, -40), Vector2(60, 180), Vector2(300, 180), Vector2(300, 380), Vector2(120, 380), Vector2(120, 600), Vector2(560, 600), Vector2(560, 780), Vector2(360, 780), Vector2(360, 840)]
	if v == 1:
		return [Vector2(360, -40), Vector2(360, 160), Vector2(620, 160), Vector2(620, 360), Vector2(120, 360), Vector2(120, 560), Vector2(600, 560), Vector2(600, 740), Vector2(240, 740), Vector2(240, 840), Vector2(360, 840)]
	return [Vector2(60, 60), Vector2(660, 60), Vector2(660, 240), Vector2(120, 240), Vector2(120, 420), Vector2(620, 420), Vector2(620, 600), Vector2(160, 600), Vector2(160, 760), Vector2(560, 760), Vector2(360, 780), Vector2(360, 840)]

func _on_path(pos: Vector2) -> bool:
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var seg := b - a
		var rel := pos - a
		if abs(rel.x) < 34.0 and abs(rel.y) < 34.0:
			return true
		if seg.length() > 1.0 and abs((rel.cross(seg.normalized()))) < 34.0 and rel.dot(seg.normalized()) > -34.0 and rel.dot(seg.normalized()) < seg.length() + 34.0:
			return true
	return false

func _start_wave() -> void:
	wave += 1
	AudioManager.play("level")
	spawn_left = 3 + wave * 2
	spawn_t = 0.0
	# bounty за каждую 5-ю волну: 10 + 5*wave, один раз за волну
	# bounty for every 5th wave: 10 + 5*wave, once per wave
	if wave % 5 == 0 and bounty_paid_wave != wave:
		bounty_paid_wave = wave
		GameState.add_coins(10 + 5 * int(wave))
		GameState.save_settings()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_toggle_pause()
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = to_local((e as InputEventMouseButton).position)
		if over:
			core_hp = CORE_HP
			coins = 200
			wave = 0
			bounty_paid_wave = 0
			mobs.clear()
			towers.clear()
			beams.clear()
			over = false
			path = _path_variant(randi() % 3)
			_start_wave()
			return
		# выбор типа башни (низ экрана)
		if p.y > 1010.0:
			for i in 3:
				var r := Rect2(20.0 + float(i) * 232.0, 1030.0, 220.0, 64.0)
				if r.has_point(p):
					sel_type = i
					return
			return
		# апгрейд существующей башни
		for tw in towers:
			if Vector2(float(tw["x"]), float(tw["y"])).distance_to(p) < 28.0:
				var lvl: int = int(tw.get("lvl", 1))
				if lvl < 3:
					var ttu: Dictionary = TOWER_TYPES[int(tw["type"])]
					var cost: int = int(float(ttu["cost"]) * 0.6 * float(lvl))
					if coins >= cost:
						coins -= cost
						tw["lvl"] = lvl + 1
				return
		# постановка башни
		var cell := Vector2(floor(p.x / CELL) * CELL + CELL * 0.5, floor(p.y / CELL) * CELL + CELL * 0.5)
		if _on_path(cell) or p.y > 920.0:
			return
		for tw in towers:
			if Vector2(tw["x"], tw["y"]).distance_to(cell) < 20.0:
				return
		var tt: Dictionary = TOWER_TYPES[sel_type]
		if coins >= int(tt["cost"]):
			coins -= int(tt["cost"])
			towers.append({"x": cell.x, "y": cell.y, "type": sel_type, "cd": 0.0, "lvl": 1})

func _process(dt: float) -> void:
	if replay_btn != null:
		replay_btn.visible = over
	if over:
		queue_redraw()
		return
	t_anim += dt
	if spawn_left <= 0 and mobs.is_empty():
		wave_t += dt
		if wave_t > 3.0:
			wave_t = 0.0
			_start_wave()
	if spawn_left > 0:
		spawn_t += dt
		if spawn_t > 0.9:
			spawn_t = 0.0
			spawn_left -= 1
			var is_boss: bool = (wave % 5 == 0) and (spawn_left == 0)
			var hp: float = 22.0 + float(wave) * 8.0
			var spd: float = 17.0 + float(wave) * 0.7
			var rr_m: float = 52.0
			if is_boss:
				hp *= 5.0
				spd *= 0.6
				rr_m = 88.0
			mobs.append({"t": 0.0, "hp": hp, "max": hp, "speed": spd, "r": rr_m, "boss": is_boss})
	# мобы
	var keep_m: Array = []
	for m in mobs:
		m["t"] = float(m["t"]) + float(m["speed"]) * dt / 10.0
		if float(m["t"]) >= float(path.size() - 1):
			core_hp -= 1
			if core_hp <= 0:
				core_hp = 0
				if not over:
					AudioManager.play("defeat")
					GameState.add_coins(10 + 5 * int(wave))
					GameState.save_settings()
				over = true
			continue
		keep_m.append(m)
	mobs = keep_m
	# башни
	for tw in towers:
		tw["cd"] = float(tw["cd"]) - dt
		if float(tw["cd"]) > 0.0:
			continue
		var tt: Dictionary = TOWER_TYPES[int(tw["type"])]
		var lvl: int = int(tw.get("lvl", 1))
		var rng: float = float(tt["range"]) + 18.0 * float(lvl - 1)
		var dmg: float = float(tt["dmg"]) * (1.0 + 0.6 * float(lvl - 1))
		var best: Dictionary = {}
		var bd: float = 1e9
		for m in mobs:
			var mp := _mob_pos(m)
			var d: float = Vector2(float(tw["x"]) - mp.x, float(tw["y"]) - mp.y).length()
			if d < bd and d <= rng:
				bd = d
				best = m
		if not best.is_empty():
			tw["cd"] = float(tt["cd"])
			best["hp"] = float(best["hp"]) - dmg
			beams.append({"a": Vector2(tw["x"], tw["y"]), "b": _mob_pos(best), "t": 0.12, "col": tt["col"]})
			if float(best["hp"]) <= 0.0:
				coins += 10
				AudioManager.play("coin")
				mobs.erase(best)
	# лучи
	var keep_b: Array = []
	for b in beams:
		b["t"] = float(b["t"]) - dt
		if float(b["t"]) > 0.0:
			keep_b.append(b)
	beams = keep_b
	queue_redraw()

func _mob_pos(m: Dictionary) -> Vector2:
	var i: int = int(m["t"])
	var f: float = float(m["t"]) - float(i)
	var a: Vector2 = path[mini(i, path.size() - 1)]
	var b: Vector2 = path[mini(i + 1, path.size() - 1)]
	return a.lerp(b, f)

func _draw() -> void:
	if bg_tex:
		draw_texture_rect(bg_tex, Rect2(0, 0, W, H), false)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.05, 0.06, 0.10))
	# сетка
	for x in range(GX + 1):
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, 900), Color(0.12, 0.16, 0.22))
	for y in range(15):
		draw_line(Vector2(0, y * CELL), Vector2(W, y * CELL), Color(0.12, 0.16, 0.22))
	# путь
	for i in range(path.size() - 1):
		draw_line(path[i], path[i + 1], Color(0.30, 0.45, 0.35), 46.0)
		draw_line(path[i], path[i + 1], Color(0.45, 0.70, 0.50), 26.0)
	# башни
	for tw in towers:
		var tt: Dictionary = TOWER_TYPES[int(tw["type"])]
		var c := Vector2(float(tw["x"]), float(tw["y"]))
		var lvl: int = int(tw.get("lvl", 1))
		if not tow_tex.is_empty():
			var tx: Texture2D = tow_tex[int(tw["type"]) % tow_tex.size()]
			var tsz: float = 56.0 + 6.0 * float(lvl - 1)
			draw_texture_rect(tx, Rect2(c.x - tsz * 0.5, c.y - tsz * 0.5, tsz, tsz), false)
		else:
			draw_circle(c, 22.0 + 3.0 * float(lvl - 1), tt["col"])
			draw_circle(c, 12.0, Color(1, 1, 1, 0.85))
		for k in lvl:
			draw_circle(c + Vector2(-10.0 + 10.0 * float(k), 24.0), 3.0, Color(1.0, 0.9, 0.4))
	# лучи
	for b in beams:
		draw_line(b["a"], b["b"], Color(1, 1, 1, 0.8), 3.0)
		draw_line(b["a"], b["b"], b["col"], 1.5)
	# мобы
	for m in mobs:
		var mp := _mob_pos(m)
		var mr: float = float(m.get("r", 14.0))
		var mc := Color(0.9, 0.25, 0.35) if bool(m.get("boss", false)) else Color(0.9, 0.3, 0.4)
		if mob_td_tex:
			var msz: float = mr * 3.2
			draw_texture_rect(mob_td_tex, Rect2(mp.x - msz * 0.5, mp.y - msz * 0.5, msz, msz), false)
		else:
			draw_circle(mp, mr, mc)
			if bool(m.get("boss", false)):
				draw_circle(mp, mr * 0.55, Color(1.0, 0.8, 0.25))
		var w: float = mr * 2.0 * (float(m["hp"]) / float(m["max"]))
		draw_rect(Rect2(mp.x - mr, mp.y - mr - 8.0, w, 4.0), Color(1, 0.4, 0.4))
	# ядро
	var core := Vector2(360, 880)
	# Ворота Империи (наш стиль) вокруг ядра
	draw_rect(Rect2(298, 806, 28, 110), Color(0.85, 0.70, 0.30))
	draw_rect(Rect2(394, 806, 28, 110), Color(0.85, 0.70, 0.30))
	draw_arc(Vector2(360, 812), 48.0, PI, TAU, 26, Color(1.0, 0.85, 0.35), 10.0)
	draw_rect(Rect2(306, 806, 12, 110), Color(0.55, 0.12, 0.12))
	draw_rect(Rect2(402, 806, 12, 110), Color(0.55, 0.12, 0.12))
	if core_tex:
		draw_texture_rect(core_tex, Rect2(core.x - 46.0, core.y - 46.0, 92.0, 92.0), false)
	else:
		draw_circle(core, 40.0, Color(0.2, 0.85, 0.5))
		draw_circle(core, 26.0, Color(0.75, 1.0, 0.85))
	draw_string(ThemeDB.fallback_font, Vector2(280, 830), tr("ЯДРО %d/%d") % [core_hp, CORE_HP], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1))
	# HUD
	draw_string(ThemeDB.fallback_font, Vector2(20, 30), tr("TD ПРОТОТИП  ВОЛНА %d  МОНЕТЫ %d") % [wave, coins], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1))
	# кнопки типов
	for i in 3:
		var tt: Dictionary = TOWER_TYPES[i]
		var r := Rect2(20.0 + float(i) * 232.0, 1030.0, 220.0, 64.0)
		draw_rect(r, Color(0.16, 0.20, 0.28) if i != sel_type else Color(0.25, 0.45, 0.65))
		draw_rect(r, tt["col"], false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 8.0, r.position.y + 26.0), tr(str(tt["name"])), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1))
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 8.0, r.position.y + 50.0), tr("%d мон.") % int(tt["cost"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tt["col"])
	draw_string(ThemeDB.fallback_font, Vector2(40, 1016), tr("Выбери башню и кликни по полю · клик по башне - апгрейд"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.7, 0.9, 0.8))
	if over:
		draw_rect(Rect2(0, 400, W, 180), Color(0, 0, 0, 0.75))
		draw_string(ThemeDB.fallback_font, Vector2(0, 470), tr("ЯДРО ПАЛО"), HORIZONTAL_ALIGNMENT_CENTER, W, 44, Color(1, 0.35, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(0, 520), tr("Клик - рестарт"), HORIZONTAL_ALIGNMENT_CENTER, W, 22, Color(1, 1, 1))

func _build_pause() -> void:
	_pl = CanvasLayer.new()
	_pl.layer = 10
	_pl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pl)
	_pm = Control.new()
	_pm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pm.process_mode = Node.PROCESS_MODE_ALWAYS
	_pm.visible = false
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
	pb.position = Vector2(W - 84.0, 24.0)
	pb.size = Vector2(56, 44)
	pb.process_mode = Node.PROCESS_MODE_ALWAYS
	pb.pressed.connect(_toggle_pause)
	add_child(pb)

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	_pm.visible = paused

func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
