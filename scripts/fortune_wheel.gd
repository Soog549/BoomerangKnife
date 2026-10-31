extends Control
class_name FortuneWheel
## Колесо удачи: 12 секторов. Награда выбирается ДО вращения, колесо
## останавливается ровно на выигравшем секторе (честно и наглядно).

signal finished(reward: Dictionary)

const SECTORS := [
	{"label": "+20", "col": Color(0.28, 0.42, 0.72)},
	{"label": "+30", "col": Color(0.22, 0.34, 0.60)},
	{"label": "+40", "col": Color(0.28, 0.42, 0.72)},
	{"label": "+60", "col": Color(0.22, 0.34, 0.60)},
	{"label": "+100", "col": Color(0.55, 0.40, 0.16)},
	{"label": "30 XP", "col": Color(0.20, 0.46, 0.36)},
	{"label": "50 XP", "col": Color(0.16, 0.38, 0.30)},
	{"label": "80 XP", "col": Color(0.20, 0.46, 0.36)},
	{"label": "+5", "col": Color(0.30, 0.34, 0.62)},
	{"label": "+10", "col": Color(0.44, 0.30, 0.62)},
	{"label": "+20", "col": Color(0.30, 0.34, 0.62)},
	{"label": "БУСТЕР", "col": Color(0.62, 0.26, 0.34)},
]

var angle := 0.0
var spinning := false
var _tween: Tween = null
var _hover := false


func _ready() -> void:
	custom_minimum_size = Vector2(320, 320)
	size = Vector2(320, 320)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw())
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
	var reward: Dictionary = GameState.claim_fortune()
	var idx: int = int(reward.get("index", 0))
	var n: int = SECTORS.size()
	var step: float = TAU / float(n)
	# сектор idx должен оказаться под указателем (сверху, -PI/2)
	var target := -PI / 2.0 - step * (float(idx) + 0.5)
	var base := fposmod(angle, TAU)
	var delta := fposmod(target - base, TAU) + TAU * (4.0 + randf() * 1.6)
	_tween = create_tween()
	_tween.tween_method(_set_angle, angle, angle + delta, 2.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_tween.tween_callback(func() -> void:
		spinning = false
		AudioManager.play("level")
		Telemetry.event("fortune_spin", {"reward": str(reward.get("kind", ""))})
		finished.emit(reward))


func _set_angle(a: float) -> void:
	angle = a
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.44
	var n: int = SECTORS.size()
	var step: float = TAU / float(n)

	# внешнее свечение
	draw_circle(c, r + 10.0, Color(1.0, 0.82, 0.35, 0.10))
	draw_circle(c, r + 4.0, Color(1.0, 0.86, 0.45, 0.18))

	for i in n:
		var a0: float = angle + step * float(i)
		var a1: float = a0 + step
		var col: Color = SECTORS[i]["col"]
		var pts := PackedVector2Array([c])
		var seg := maxi(3, int(step / 0.08))
		for k in seg + 1:
			var a: float = a0 + (a1 - a0) * float(k) / float(seg)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, col)
		# блик по кромке
		draw_arc(c, r - 1.0, a0, a1, 8, Color(1, 1, 1, 0.10), 2.0)
		# разделители
		draw_line(c, c + Vector2(cos(a0), sin(a0)) * r, Color(1.0, 0.88, 0.55, 0.55), 2.0)

	# подписи
	var font := ThemeDB.fallback_font
	for i in n:
		var mid: float = angle + step * (float(i) + 0.5)
		var pos: Vector2 = c + Vector2(cos(mid), sin(mid)) * (r * 0.66)
		draw_set_transform(pos, mid + PI / 2.0, Vector2.ONE)
		var txt: String = str(SECTORS[i]["label"])
		var w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(font, Vector2(-w * 0.5, 5.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.95))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# золотой обод
	draw_arc(c, r, 0.0, TAU, 96, Color(0.95, 0.78, 0.30, 0.95), 6.0)
	draw_arc(c, r - 7.0, 0.0, TAU, 96, Color(0.55, 0.38, 0.12, 0.85), 2.0)
	draw_arc(c, r + 3.0, 0.0, TAU, 96, Color(1.0, 0.90, 0.55, 0.35), 2.0)

	# ступица
	draw_circle(c, 44.0, Color(0.10, 0.10, 0.16, 0.95))
	draw_arc(c, 44.0, 0.0, TAU, 48, Color(0.95, 0.78, 0.30, 0.95), 3.0)
	draw_string(font, c + Vector2(-30, 6), "КРУТИТЬ", HORIZONTAL_ALIGNMENT_CENTER, 60, 13,
		Color(1.0, 0.90, 0.60, 0.95 if _hover else 0.75))

	# указатель
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-12, -r - 14),
		c + Vector2(12, -r - 14),
		c + Vector2(0, -r + 10),
	]), Color(1.0, 0.86, 0.35, 1.0))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-7, -r - 10),
		c + Vector2(7, -r - 10),
		c + Vector2(0, -r + 4),
	]), Color(0.6, 0.42, 0.12, 1.0))
