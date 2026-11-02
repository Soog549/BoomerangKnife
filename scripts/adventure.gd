extends Node2D

## Adventure 2.5D: камера-слежение, NPC с диалогами, квест, мобы.

const WORLD := Vector2(2400, 2400)

var player := Vector2(1200, 1200)
var p_speed := 260.0
var target := Vector2(1200, 1200)
var has_target := false

var npcs: Array = [
	{"name": "Кузнец", "pos": Vector2(1080, 1120), "line": "Нож вернётся, если помнишь, кто хозяин.", "quest": true},
	{"name": "Страж", "pos": Vector2(1360, 1180), "line": "Дальше — Разлом. Не ходи туда без памяти.", "quest": false},
	{"name": "Торговка", "pos": Vector2(1180, 1320), "line": "Память покупаю. Дороже, чем империя.", "quest": false},
]
var mobs: Array = []
var quest_state := 0   # 0 нет, 1 взято, 2 выполнено
var quest_killed := 0
var bubble := ""
var bubble_t := 0.0
var cam: Camera2D
var _comp_t := 0.0
var remote: Dictionary = {}
var comp_pos := Vector2(1240, 1240)


func _ready() -> void:
	cam = Camera2D.new()
	cam.position = player
	add_child(cam)
	cam.make_current()
	for i in 3:
		_spawn_mob(Vector2(1500 + i * 140, 900 + i * 90))
	queue_redraw()


func _spawn_mob(p: Vector2) -> void:
	mobs.append({"pos": p, "hp": 3, "alive": true, "t": randf() * 6.0})


func _process(dt: float) -> void:
	if has_target:
		var d := target - player
		if d.length() > 6.0:
			player += d.normalized() * p_speed * dt
		else:
			has_target = false
	cam.position = cam.position.lerp(player, 1.0 - pow(0.001, dt))
	bubble_t = maxf(0.0, bubble_t - dt)
	_comp_t += dt
	if multiplayer.multiplayer_peer != null:
		rpc("sync_pos", player.x, player.y)
	if GameState.companion_id > 0:
		var follow := player + Vector2(-56, 34)
		comp_pos = comp_pos.lerp(follow, 1.0 - pow(0.002, dt))
		if _comp_t >= 1.2:
			_comp_t = 0.0
			var nearest: Dictionary = {}
			var nd := 1e9
			for m in mobs:
				if m["alive"] and comp_pos.distance_to(m["pos"]) < 220.0:
					var dd: float = comp_pos.distance_to(m["pos"])
					if dd < nd:
						nd = dd
						nearest = m
			if not nearest.is_empty():
				nearest["alive"] = false
				if quest_state == 1:
					quest_killed += 1
					if quest_killed >= 3:
						quest_state = 2
						_say("Кузнец", "Вернись к кузнецу — он ждёт.")
	for m in mobs:
		if m["alive"]:
			m["t"] += dt
			m["pos"] += Vector2(cos(m["t"]), sin(m["t"] * 1.3)) * 22.0 * dt
			if player.distance_to(m["pos"]) < 70.0:
				m["alive"] = false
				if quest_state == 1:
					quest_killed += 1
					if quest_killed >= 3:
						quest_state = 2
						_say("Кузнец", "Вернись к кузнецу — он ждёт.")
	queue_redraw()


func _say(who: String, text: String) -> void:
	bubble = "%s: %s" % [who, text]
	bubble_t = 4.0


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch and e.pressed:
		var wp: Vector2 = get_global_mouse_position()
		for n in npcs:
			if wp.distance_to(n["pos"]) < 60.0:
				_say(str(n["name"]), str(n["line"]))
				if bool(n["quest"]) and quest_state == 0:
					quest_state = 1
					_say(str(n["name"]), "Принеси три шкуры из Разлома — и я дам тебе силу.")
				elif quest_state == 2 and bool(n["quest"]):
					_say(str(n["name"]), "Ты справился. Сила — твоя.")
					GameState.evo_add(50)
					GameState.save_settings()
					quest_state = 3
					if GameState.companion_id < 2:
						GameState.companion_id = 2
						GameState.save_settings()
						_say("АВРОРА", "Теперь я пойду с тобой. Не спорь.")
				return
		target = wp
		has_target = true
	elif e is InputEventScreenDrag:
		target = get_global_mouse_position()
		has_target = true


func _draw() -> void:
	draw_rect(Rect2(-400, -400, WORLD.x + 800, WORLD.y + 800), Color(0.06, 0.08, 0.12))
	# плитка земли
	for x in range(0, int(WORLD.x), 160):
		for y in range(0, int(WORLD.y), 160):
			var parity: int = int(x / 160) + int(y / 160)
			var c := Color(0.10, 0.13, 0.18) if parity % 2 == 0 else Color(0.09, 0.12, 0.16)
			draw_rect(Rect2(x, y, 158, 158), c)
	# дорога
	draw_rect(Rect2(0, 1150, WORLD.x, 90), Color(0.16, 0.14, 0.12))
	# NPC
	for n in npcs:
		var p: Vector2 = n["pos"]
		draw_circle(p, 26.0, Color(0.95, 0.8, 0.4) if n["quest"] else Color(0.55, 0.7, 0.95))
		draw_string(ThemeDB.fallback_font, p + Vector2(-40, -40), str(n["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1))
		if bool(n["quest"]) and quest_state == 0:
			draw_circle(p + Vector2(0, -58), 8.0, Color(1.0, 0.85, 0.3))
	# мобы
	for m in mobs:
		if m["alive"]:
			draw_circle(m["pos"], 22.0, Color(0.9, 0.3, 0.35))
	if GameState.companion_id > 0:
		var ccol := Color(0.25, 0.9, 0.8)
		if GameState.companion_id == 2:
			ccol = Color(1.0, 0.75, 0.35)
		elif GameState.companion_id == 3:
			ccol = Color(0.65, 0.45, 1.0)
		draw_circle(comp_pos, 20.0, ccol)
		draw_circle(comp_pos + Vector2(-6, -5), 4.0, Color(1, 1, 1, 0.9))
	_draw_remote()
	# игрок
	draw_circle(player, 28.0, GameState.accent())
	draw_circle(player + Vector2(0, -6), 10.0, Color(1, 1, 1, 0.85))
	# квест-трекер (экранный)
	var vp: Vector2 = get_viewport_rect().size
	var top_left: Vector2 = cam.position - vp * 0.5
	draw_string(ThemeDB.fallback_font, top_left + Vector2(20, 40), "КВЕСТ: %s" % _quest_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.86, 0.45))
	if bubble_t > 0.0:
		draw_rect(Rect2(top_left + Vector2(20, vp.y - 160), Vector2(vp.x - 40, 70)), Color(0, 0, 0, 0.75))
		draw_string(ThemeDB.fallback_font, top_left + Vector2(34, vp.y - 118), bubble, HORIZONTAL_ALIGNMENT_LEFT, vp.x - 70, 15, Color(1, 1, 1))


func _quest_text() -> String:
	match quest_state:
		1:
			return "Убей 3 мобов (%d/3)" % quest_killed
		2:
			return "Вернись к кузнецу"
		3:
			return "Выполнено"
	return "Поговори с кузнецом"


@rpc("any_peer", "call_remote", "unreliable_ordered")
func sync_pos(rx: float, ry: float) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not remote.has(id):
		remote[id] = Vector2(rx, ry)
	else:
		remote[id] = (remote[id] as Vector2).lerp(Vector2(rx, ry), 0.5)


func _draw_remote() -> void:
	for id in remote.keys():
		var p: Vector2 = remote[id]
		draw_circle(p, 26.0, Color(1.0, 0.55, 0.45))
		draw_string(ThemeDB.fallback_font, p + Vector2(-24, -38), "Игрок", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.9, 0.9))
