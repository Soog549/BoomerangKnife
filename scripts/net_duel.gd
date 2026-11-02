extends Node2D

## Сетевая дуэль 1v1. Хост авторитетен по урону.

const W := 720.0
const H := 1280.0

var my_id := 1
var players: Dictionary = {}   # id -> {x, y, hp, name}
var knives: Array = []
var over := false
var winner := -1

var _touch := false
var _tpos := Vector2.ZERO
var _throw_cd := 0.0


func _ready() -> void:
	my_id = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	players[my_id] = {"x": W * 0.5, "y": H - 260.0, "hp": 100.0, "name": "Я"}
	if multiplayer.is_server():
		for pid in NetManager.players.keys():
			if int(pid) != 1:
				players[int(pid)] = {"x": W * 0.5, "y": 220.0, "hp": 100.0, "name": str(NetManager.players[pid].get("name", "Игрок"))}
	_queue_redraw()


func _process(dt: float) -> void:
	_throw_cd = maxf(0.0, _throw_cd - dt)
	for k in knives:
		k["t"] += dt
		k["x"] += k["vx"] * dt
		k["y"] += k["vy"] * dt
	knives = knives.filter(func(k): return k["t"] < 1.2)
	if multiplayer.multiplayer_peer != null:
		rpc("sync_pos", my_id, players[my_id]["x"], players[my_id]["y"])
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_touch = true
			_tpos = e.position
		else:
			_touch = false
			if _throw_cd <= 0.0:
				_try_throw(e.position)
	elif e is InputEventScreenDrag:
		_tpos = e.position


func _try_throw(target: Vector2) -> void:
	_throw_cd = 0.45
	var me: Dictionary = players[my_id]
	var d := target - Vector2(me["x"], me["y"])
	if d.length() < 1.0:
		return
	var dir := d.normalized()
	knives.append({"x": me["x"], "y": me["y"], "vx": dir.x * 900.0, "vy": dir.y * 900.0, "t": 0.0, "own": my_id})
	rpc("net_throw", my_id, me["x"], me["y"], dir.x, dir.y)
	_check_hit(my_id, me["x"], me["y"], dir)


func _check_hit(owner_id: int, x: float, y: float, dir: Vector2) -> void:
	for pid in players.keys():
		if int(pid) == owner_id:
			continue
		var p: Dictionary = players[pid]
		var to := Vector2(p["x"] - x, p["y"] - y)
		if to.length() < 260.0 and to.normalized().dot(dir) > 0.85:
			_damage(int(pid), 12.0)


func _damage(pid: int, amount: float) -> void:
	if not multiplayer.is_server():
		rpc_id(1, "request_damage", pid, amount)
		return
	_apply_damage(pid, amount)
	rpc("apply_damage_remote", pid, amount)


@rpc("any_peer", "call_remote", "reliable")
func request_damage(pid: int, amount: float) -> void:
	if multiplayer.is_server():
		_apply_damage(pid, amount)
		rpc("apply_damage_remote", pid, amount)


@rpc("authority", "call_remote", "reliable")
func apply_damage_remote(pid: int, amount: float) -> void:
	_apply_damage(pid, amount)


func _apply_damage(pid: int, amount: float) -> void:
	if not players.has(pid):
		return
	players[pid]["hp"] = maxf(0.0, float(players[pid]["hp"]) - amount)
	if float(players[pid]["hp"]) <= 0.0 and not over:
		over = true
		winner = my_id if pid != my_id else 0


@rpc("any_peer", "call_remote", "unreliable_ordered")
func sync_pos(pid: int, x: float, y: float) -> void:
	if not players.has(pid):
		players[pid] = {"x": x, "y": y, "hp": 100.0, "name": "Игрок"}
	players[pid]["x"] = lerpf(float(players[pid]["x"]), x, 0.5)
	players[pid]["y"] = lerpf(float(players[pid]["y"]), y, 0.5)


@rpc("any_peer", "call_local", "reliable")
func net_throw(pid: int, x: float, y: float, dx: float, dy: float) -> void:
	knives.append({"x": x, "y": y, "vx": dx * 900.0, "vy": dy * 900.0, "t": 0.0, "own": pid})


func _queue_redraw() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.06, 0.07, 0.12))
	for pid in players.keys():
		var p: Dictionary = players[pid]
		var col := GameState.accent() if int(pid) == my_id else Color(1.0, 0.45, 0.4)
		draw_circle(Vector2(p["x"], p["y"]), 34.0, col)
		draw_rect(Rect2(p["x"] - 40, p["y"] - 60, 80, 8), Color(0.15, 0.15, 0.2))
		draw_rect(Rect2(p["x"] - 40, p["y"] - 60, 80.0 * float(p["hp"]) / 100.0, 8), Color(0.85, 0.3, 0.3))
	for k in knives:
		draw_circle(Vector2(k["x"], k["y"]), 9.0, Color(1.0, 0.9, 0.5))
	if over:
		draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 120, H * 0.45), "ДУЭЛЬ ОКОНЧЕНА", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 0.9, 0.6))
