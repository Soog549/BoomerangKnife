extends Node2D

## Стратегия-прототип (RTS-lite): базы, юниты, ресурсы, ИИ.

const W := 720.0
const H := 1280.0

var gold := 120.0
var my_base := {"x": 120.0, "y": H - 180.0, "hp": 300.0, "max": 300.0}
var enemy_base := {"x": W - 120.0, "y": 180.0, "hp": 300.0, "max": 300.0}
var units: Array = []
var over := false
var atk_lvl := 0
var hp_lvl := 0
var win := false
var _ai_t := 0.0
var _gold_t := 0.0
var _sel := ""


func _ready() -> void:
	set_process(true)


func _process(dt: float) -> void:
	if over:
		return
	_gold_t += dt
	_ai_t += dt
	if _gold_t >= 1.0:
		_gold_t = 0.0
		gold += 6.0
	if _ai_t >= 4.0:
		_ai_t = 0.0
		_spawn(2, "warrior")
	for u in units:
		u["t"] += dt
		var target: Dictionary = enemy_base if int(u["side"]) == 1 else my_base
		for o in units:
			if int(o["side"]) != int(u["side"]):
				if Vector2(o["x"] - u["x"], o["y"] - u["y"]).length() < 90.0:
					target = o
					break
		var d := Vector2(target["x"] - u["x"], target["y"] - u["y"])
		if d.length() > 62.0:
			var step := d.normalized() * float(u["spd"]) * dt
			u["x"] += step.x
			u["y"] += step.y
		else:
			u["cd"] = float(u["cd"]) - dt
			if float(u["cd"]) <= 0.0:
				u["cd"] = float(u["rate"])
				target["hp"] = float(target["hp"]) - float(u["dmg"])
	units = units.filter(func(u): return float(u["hp"]) > 0.0)
	if float(enemy_base["hp"]) <= 0.0:
		over = true
		win = true
	elif float(my_base["hp"]) <= 0.0:
		over = true
		win = false
	_sync_hp()
	queue_redraw()


func _sync_hp() -> void:
	for u in units:
		for o in units:
			if o == u:
				continue
			if int(o["side"]) != int(u["side"]) and Vector2(o["x"] - u["x"], o["y"] - u["y"]).length() < 40.0:
				u["hp"] = float(u["hp"]) - 0.4


func _spawn(side: int, kind: String) -> void:
	var base: Dictionary = my_base if side == 1 else enemy_base
	var stats := {"hp": 60.0, "dmg": 8.0, "rate": 0.9, "spd": 90.0}
	if kind == "archer":
		stats = {"hp": 40.0, "dmg": 11.0, "rate": 1.2, "spd": 80.0}
	elif kind == "tank":
		stats = {"hp": 130.0, "dmg": 7.0, "rate": 1.1, "spd": 60.0}
	var hp_mult: float = 1.0 + 0.2 * float(hp_lvl) if side == 1 else 1.0
	var dmg_mult: float = 1.0 + 0.2 * float(atk_lvl) if side == 1 else 1.0
	units.append({
		"side": side, "kind": kind, "x": float(base["x"]), "y": float(base["y"]),
		"hp": float(stats["hp"]) * hp_mult, "max": float(stats["hp"]) * hp_mult,
		"dmg": float(stats["dmg"]) * dmg_mult,
		"rate": stats["rate"], "spd": stats["spd"], "cd": 0.0, "t": 0.0,
	})


func _unhandled_input(e: InputEvent) -> void:
	if over:
		return
	if e is InputEventScreenTouch and e.pressed:
		var p: Vector2 = e.position
		if Vector2(p - Vector2(my_base["x"], my_base["y"])).length() < 70.0:
			_sel = "base"
			return
		if p.y > H - 80.0 and p.y < H - 12.0:
			var slot: int = int((p.x - 20) / 230)
			if slot == 0:
				_upgrade("atk")
			elif slot == 1:
				_upgrade("hp")
			return
		if _sel == "base":
			_build("warrior")


func _build(kind: String) -> void:
	var cost := 40.0
	if kind == "archer":
		cost = 55.0
	elif kind == "tank":
		cost = 80.0
	if gold < cost:
		Toast.show("Не хватает монет")
		return
	gold -= cost
	_spawn(1, kind)
	AudioManager.play("level")


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.07, 0.08, 0.13))
	# поле
	for x in range(0, int(W), 90):
		draw_line(Vector2(x, 0), Vector2(x, H), Color(1, 1, 1, 0.04))
	for y in range(0, int(H), 90):
		draw_line(Vector2(0, y), Vector2(W, y), Color(1, 1, 1, 0.04))
	_draw_base(my_base, Color(0.35, 0.85, 0.75))
	_draw_base(enemy_base, Color(0.9, 0.35, 0.35))
	for u in units:
		var col := Color(0.4, 0.9, 0.8) if int(u["side"]) == 1 else Color(1.0, 0.45, 0.4)
		draw_circle(Vector2(u["x"], u["y"]), 16.0, col)
		draw_rect(Rect2(u["x"] - 18, u["y"] - 28, 36, 5), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(u["x"] - 18, u["y"] - 28, 36.0 * float(u["hp"]) / float(u["max"]), 5), Color(0.9, 0.9, 0.4))
	# HUD
	draw_string(ThemeDB.fallback_font, Vector2(24, 44), "ЗОЛОТО: %d" % int(gold), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.86, 0.45))
	var by := H - 150.0
	var defs := [["ВОИН 40", "warrior"], ["ЛУЧНИК 55", "archer"], ["ТАНК 80", "tank"]]
	for i in defs.size():
		var r := Rect2(20 + i * 230, by, 210, 62)
		draw_rect(r, Color(0.12, 0.15, 0.22, 0.95))
		draw_rect(r, Color(0.45, 0.8, 0.75, 0.7), false, 2.0)
		draw_string(ThemeDB.fallback_font, r.position + Vector2(12, 38), defs[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1))
	if _sel == "base":
		draw_string(ThemeDB.fallback_font, Vector2(24, by - 16), "База выбрана: коснись поля, чтобы построить юнита", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.9, 1))
	# апгрейды
	var uy: float = H - 72.0
	var ups := [["АТАКА +20%% (%d)" % (60 + 40 * atk_lvl), 0], ["HP +20%% (%d)" % (60 + 40 * hp_lvl), 1]]
	for i in ups.size():
		var ur := Rect2(20 + i * 230, uy, 210, 52)
		draw_rect(ur, Color(0.16, 0.12, 0.20, 0.95))
		draw_rect(ur, Color(0.85, 0.7, 0.35, 0.8), false, 2.0)
		draw_string(ThemeDB.fallback_font, ur.position + Vector2(10, 32), str(ups[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.95, 0.8))
	if over:
		draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 140, H * 0.45), "ПОБЕДА" if win else "ПОРАЖЕНИЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 0.9, 0.6))


func _draw_base(b: Dictionary, col: Color) -> void:
	draw_rect(Rect2(b["x"] - 50, b["y"] - 34, 100, 68), col.darkened(0.35))
	draw_rect(Rect2(b["x"] - 50, b["y"] - 34, 100, 68), col, false, 3.0)
	draw_rect(Rect2(b["x"] - 50, b["y"] - 50, 100, 10), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(b["x"] - 50, b["y"] - 50, 100.0 * float(b["hp"]) / float(b["max"]), 10), col)


func _upgrade(kind: String) -> void:
	var cost: int = 60 + (40 * atk_lvl if kind == "atk" else 40 * hp_lvl)
	if gold < float(cost):
		Toast.show("Не хватает монет")
		return
	gold -= float(cost)
	if kind == "atk":
		atk_lvl += 1
	else:
		hp_lvl += 1
	AudioManager.play("level")
