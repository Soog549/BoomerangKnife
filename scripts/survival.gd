extends Node2D

## Survival «ВЫЖИВАНИЕ-МИР»: день/ночь, голод, рассудок, сбор, крафт, лагерь.

const W := 1600.0
const H := 1600.0
const DAY_LEN := 300.0
const NIGHT_LEN := 180.0

var player := Vector2(800, 800)
var target := Vector2(800, 800)
var has_target := false
var cam: Camera2D
var hud: Font

var hp := 100.0
var hunger := 100.0
var sanity := 100.0
var phase := 0.0          # 0..1 внутри суток
var day := 1
var is_night := false
var dead := false

var wood := 0
var stone := 0
var berries := 0
var has_knife := false
var camp := Vector2.ZERO
var has_camp := false

var nodes: Array = []
var shadows: Array = []
var _t := 0.0


func _ready() -> void:
	cam = Camera2D.new()
	cam.position = player
	add_child(cam)
	cam.make_current()
	hud = UIKit.main_font()
	if hud == null:
		hud = ThemeDB.fallback_font
	_gen_world()
	_load_world()
	queue_redraw()


func _gen_world() -> void:
	for i in 26:
		var p := Vector2(randf_range(120, W - 120), randf_range(120, H - 120))
		nodes.append({"type": "tree", "pos": p, "hp": 2})
	for i in 18:
		var p := Vector2(randf_range(120, W - 120), randf_range(120, H - 120))
		nodes.append({"type": "stone", "pos": p, "hp": 2})
	for i in 14:
		var p := Vector2(randf_range(120, W - 120), randf_range(120, H - 120))
		nodes.append({"type": "berry", "pos": p, "hp": 3})


func _process(dt: float) -> void:
	if dead:
		return
	_t += dt
	# время
	var total := DAY_LEN + NIGHT_LEN
	phase += dt / total
	if phase >= 1.0:
		phase -= 1.0
		day += 1
		_save_world()
	is_night = phase >= (DAY_LEN / total)
	# голод
	hunger = maxf(0.0, hunger - dt * (100.0 / 480.0))
	if hunger <= 0.0:
		hp -= dt * 3.0
	if hp <= 0.0:
		_dead()
	# рассудок ночью
	if is_night:
		sanity = maxf(0.0, sanity - dt * 1.6)
		if has_camp and player.distance_to(camp) < 180.0:
			sanity = minf(100.0, sanity + dt * 0.8)
	else:
		sanity = minf(100.0, sanity + dt * 0.5)
	# тени ночью
	if is_night and shadows.size() < 6 and randf() < dt * 0.35:
		var ang := randf() * TAU
		shadows.append({"pos": player + Vector2(cos(ang), sin(ang)) * randf_range(380, 560), "hp": 30.0})
	for s in shadows:
		s["pos"] += (player - s["pos"]).normalized() * 46.0 * dt
		if s["pos"].distance_to(player) < 40.0:
			hp -= dt * 4.0
			sanity = maxf(0.0, sanity - dt * 1.4)
	# движение
	if has_target:
		var d := target - player
		if d.length() > 8.0:
			player += d.normalized() * 210.0 * dt
		else:
			has_target = false
	cam.position = cam.position.lerp(player, 1.0 - pow(0.0015, dt))
	queue_redraw()


func _dead() -> void:
	dead = true
	shadows.clear()
	Toast.show("Смерть. День потерян (был %d)" % day)


func _unhandled_input(e: InputEvent) -> void:
	if dead:
		return
	if e is InputEventScreenTouch and e.pressed:
		var wp: Vector2 = get_global_mouse_position()
		# кнопки внизу экрана
		var vp: Vector2 = get_viewport_rect().size
		var top_left: Vector2 = cam.position - vp * 0.5
		var local: Vector2 = wp - top_left
		if local.y > vp.y - 110.0:
			var slot: int = int(local.x / (vp.x / 4.0))
			_craft(slot)
			return
		# удар / сбор
		var nearest: Dictionary = {}
		var nd := 90.0
		for n in nodes:
			if int(n["hp"]) <= 0:
				continue
			var d: float = wp.distance_to(n["pos"])
			if d < nd:
				nd = d
				nearest = n
		if not nearest.is_empty():
			if str(nearest["type"]) == "tree":
				wood += 1
			elif str(nearest["type"]) == "stone":
				stone += 1
			else:
				berries += 1
			nearest["hp"] = int(nearest["hp"]) - 1
			AudioManager.play("click")
			return
		if has_knife:
			for s in shadows:
				if wp.distance_to(s["pos"]) < 110.0:
					s["hp"] = float(s["hp"]) - 12.0
					FX.impact("crit")
			shadows = shadows.filter(func(x): return float(x["hp"]) > 0.0)
		target = wp
		has_target = true
	elif e is InputEventScreenDrag:
		target = get_global_mouse_position()
		has_target = true


func _craft(slot: int) -> void:
	match slot:
		0:  # костёр
			if has_camp:
				return
			if wood < 10:
				Toast.show("Нужно 10 дерева")
				return
			wood -= 10
			has_camp = true
			camp = player
			Toast.show("Костёр разведён")
		1:  # нож
			if has_knife:
				return
			if wood < 5 or stone < 3:
				Toast.show("Нужно 5 дерева и 3 камня")
				return
			wood -= 5
			stone -= 3
			has_knife = true
			Toast.show("Нож скрафчен")
		2:  # еда
			if berries <= 0:
				Toast.show("Нет ягод")
				return
			berries -= 1
			hunger = minf(100.0, hunger + 25.0)
		3:  # сон до утра
			if not has_camp:
				Toast.show("Нужен костёр")
				return
			if player.distance_to(camp) > 180.0:
				Toast.show("Иди к костру")
				return
			phase = 0.01
			hp = minf(100.0, hp + 25.0)
			sanity = minf(100.0, sanity + 30.0)
			shadows.clear()
			_save_world()
			Toast.show("Ты отдохнул")


func _draw() -> void:
	var night := is_night
	var bg := Color(0.05, 0.06, 0.10) if night else Color(0.12, 0.16, 0.14)
	draw_rect(Rect2(-400, -400, W + 800, H + 800), bg)
	# сетка земли
	for x in range(0, int(W), 200):
		for y in range(0, int(H), 200):
			var par: int = int(x / 200) + int(y / 200)
			var c := Color(1, 1, 1, 0.03) if par % 2 == 0 else Color(0, 0, 0, 0.03)
			draw_rect(Rect2(x, y, 198, 198), c)
	# лагерь
	if has_camp:
		draw_circle(camp, 34.0, Color(1.0, 0.6, 0.2, 0.9))
		draw_circle(camp, 62.0, Color(1.0, 0.7, 0.3, 0.12))
	# ресурсы
	for n in nodes:
		if int(n["hp"]) <= 0:
			continue
		var p: Vector2 = n["pos"]
		match str(n["type"]):
			"tree":
				draw_rect(Rect2(p.x - 8, p.y - 40, 16, 40), Color(0.42, 0.28, 0.18))
				draw_circle(p + Vector2(0, -46), 26.0, Color(0.20, 0.55, 0.30))
			"stone":
				draw_circle(p, 20.0, Color(0.55, 0.58, 0.62))
			"berry":
				draw_circle(p, 14.0, Color(0.85, 0.25, 0.45))
	# тени
	for s in shadows:
		draw_circle(s["pos"], 24.0, Color(0.15, 0.05, 0.25, 0.85))
		draw_circle(s["pos"] + Vector2(-8, -4), 4.0, Color(0.9, 0.3, 0.9))
	# игрок
	draw_circle(player, 22.0, GameState.accent())
	draw_circle(player + Vector2(0, -5), 8.0, Color(1, 1, 1, 0.9))
	# HUD
	var vp: Vector2 = get_viewport_rect().size
	var tl: Vector2 = cam.position - vp * 0.5
	var clock := "ДЕНЬ %d" % day if not night else "НОЧЬ %d" % day
	draw_string(hud, tl + Vector2(18, 34), clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.86, 0.45))
	_bar(tl + Vector2(18, 44), 200, hp / 100.0, Color(0.85, 0.3, 0.3))
	_bar(tl + Vector2(18, 62), 200, hunger / 100.0, Color(0.9, 0.7, 0.3))
	_bar(tl + Vector2(18, 80), 200, sanity / 100.0, Color(0.5, 0.75, 1.0))
	draw_string(hud, tl + Vector2(18, 108), "ДЕРЕВО %d · КАМЕНЬ %d · ЯГОДЫ %d" % [wood, stone, berries],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.9, 1.0))
	draw_string(hud, tl + Vector2(18, 130), tr("Тап по ресурсу — собрать · тап по земле — идти"),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.8, 0.75, 0.9))
	# крафт-панель
	var by: float = vp.y - 108.0
	for i in 4:
		var r := Rect2(tl.x + 10 + i * (vp.x / 4.0), tl.y + by, vp.x / 4.0 - 14, 92)
		var ci := _craft_info(i)
		var ok: bool = bool(ci.get("ok", false))
		draw_rect(r, Color(0.10, 0.12, 0.18, 0.94))
		var bcol := Color(0.4, 0.8, 0.75, 0.8) if ok else Color(0.55, 0.3, 0.3, 0.8)
		draw_rect(r, bcol, false, 2.0)
		draw_string(hud, r.position + Vector2(8, 30), str(ci["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1))
		var ccol := Color(0.85, 0.9, 1.0) if ok else Color(1.0, 0.5, 0.5)
		draw_string(hud, r.position + Vector2(8, 58), str(ci["cost"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ccol)
		if not ok:
			draw_string(hud, r.position + Vector2(8, 78), str(ci.get("need", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.4, 0.4))
	if dead:
		draw_rect(Rect2(tl.x, tl.y, vp.x, vp.y), Color(0, 0, 0, 0.7))
		draw_string(hud, tl + Vector2(vp.x * 0.5 - 150, vp.y * 0.45), "ДЕНЬ ПОТЕРЯН", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 0.6, 0.5))


func _craft_info(i: int) -> Dictionary:
	match i:
		0:
			var ok: bool = (not has_camp) and wood >= 10
			return {"name": "КОСТЁР", "cost": "10 ДЕРЕВА · есть %d" % wood, "ok": ok,
				"need": ("ГОТОВО" if has_camp else "не хватает %d дерева" % maxi(0, 10 - wood))}
		1:
			var ok: bool = (not has_knife) and wood >= 5 and stone >= 3
			return {"name": "НОЖ", "cost": "5Д + 3К · есть %d/%d" % [wood, stone], "ok": ok,
				"need": ("ГОТОВО" if has_knife else "не хватает ресурсов")}
		2:
			var ok: bool = berries >= 1
			return {"name": "ЕДА (+25)", "cost": "1 ЯГОДА · есть %d" % berries, "ok": ok,
				"need": ("" if ok else "не хватает ягод")}
		_:
			var ok: bool = has_camp
			return {"name": "СОН", "cost": "до утра", "ok": ok,
				"need": ("нужен костёр" if not ok else "иди к костру")}


func _bar(pos: Vector2, w: float, v: float, col: Color) -> void:
	draw_rect(Rect2(pos, Vector2(w, 12)), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(pos, Vector2(w * clampf(v, 0.0, 1.0), 12)), col)


func _save_world() -> void:
	GameState.mode_save("survival_world", {
		"day": day, "hp": hp, "hunger": hunger, "sanity": sanity,
		"wood": wood, "stone": stone, "berries": berries,
		"has_knife": has_knife, "has_camp": has_camp,
		"camp_x": camp.x, "camp_y": camp.y,
	})


func _load_world() -> void:
	if not GameState.mode_has("survival_world"):
		return
	var s: Dictionary = GameState.mode_load("survival_world")
	day = int(s.get("day", 1))
	hp = float(s.get("hp", 100.0))
	hunger = float(s.get("hunger", 100.0))
	sanity = float(s.get("sanity", 100.0))
	wood = int(s.get("wood", 0))
	stone = int(s.get("stone", 0))
	berries = int(s.get("berries", 0))
	has_knife = bool(s.get("has_knife", false))
	has_camp = bool(s.get("has_camp", false))
	if has_camp:
		camp = Vector2(float(s.get("camp_x", player.x)), float(s.get("camp_y", player.y)))
	Toast.show("Лагерь восстановлен: день %d" % day)
