extends Control
class_name FortuneWheel
## КОЛЕСО ФОРТУНЫ: 4 сектора, 1 прокрут в день. Награда — через GameState.claim_fortune().

signal finished(reward: Dictionary)

const SECTORS := [
	{"label": "60 монет", "col": Color(0.95, 0.78, 0.25)},
	{"label": "+50 опыта", "col": Color(0.35, 0.65, 0.95)},
	{"label": "30 монет", "col": Color(0.55, 0.85, 0.45)},
	{"label": "Буст", "col": Color(0.85, 0.45, 0.75)},
]

var angle := 0.0
var spinning := false
var _tween: Tween = null


func _ready() -> void:
	custom_minimum_size = Vector2(300, 300)
	size = Vector2(300, 300)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spin()


func spin() -> void:
	if spinning:
		return
	if not GameState.fortune_available():
		finished.emit({})
		return
	spinning = true
	AudioManager.play("click")
	var turns := 3.0 + randf() * 2.0
	_tween = create_tween()
	_tween.tween_method(_set_angle, angle, angle + TAU * turns, 1.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_callback(func() -> void:
		spinning = false
		var reward := GameState.claim_fortune()
		AudioManager.play("level")
		Telemetry.event("fortune_spin", {"reward": str(reward.get("kind", ""))})
		finished.emit(reward))


func _set_angle(a: float) -> void:
	angle = a
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.45
	for i in SECTORS.size():
		var a0 := angle + TAU * i / SECTORS.size()
		var a1 := angle + TAU * (i + 1) / SECTORS.size()
		var pts := PackedVector2Array([c])
		var steps := 18
		for k in range(steps + 1):
			var a := lerpf(a0, a1, float(k) / steps)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, SECTORS[i]["col"])
		var mid := (a0 + a1) * 0.5
		var tp := c + Vector2(cos(mid), sin(mid)) * r * 0.62
		draw_string(ThemeDB.fallback_font, tp - Vector2(34, 8), str(SECTORS[i]["label"]), HORIZONTAL_ALIGNMENT_CENTER, 68, 15, Color(0.05, 0.06, 0.1))
	draw_arc(c, r, 0.0, TAU, 48, Color(0.95, 0.85, 0.5, 0.9), 3.0)
	draw_circle(c, r * 0.12, Color(0.95, 0.85, 0.5))
	# указатель
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -r - 16), c + Vector2(-12, -r + 4), c + Vector2(12, -r + 4)]), Color(1, 0.3, 0.3))
