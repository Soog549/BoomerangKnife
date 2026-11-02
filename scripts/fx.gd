extends Node

var tween: Tween

## Глобальные эффекты: частицы и тряска экрана. Autoload-синглтон FX.

func shake(duration: float = 0.45, strength: float = 5.0) -> void:
	if not GameState.shake_enabled:
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.has_node("Camera2D"):
		return
	tween_kill()
	var cam: Camera2D = scene.get_node("Camera2D")
	var base := cam.position
	tween = cam.create_tween()
	var dur: float = maxf(0.3, duration * 1.9)
	var steps: int = 14
	var phase: float = randf() * TAU
	for k in steps:
		var tt: float = float(k) / float(steps)
		var damp: float = pow(1.0 - tt, 1.8)
		var off := Vector2(cos(phase + tt * 5.2), sin(phase + tt * 4.4)) * strength * damp * 0.42
		tween.tween_property(cam, "position", base + off, dur / float(steps))\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cam, "position", base, dur / float(steps))\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func tween_kill() -> void:
	if tween != null and tween.is_valid():
		tween.kill()

func burst(pos: Vector2, color: Color, count := 20) -> void:
	if not GameState.particles_enabled:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.amount = count
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2(0, 600)
	particles.initial_velocity_min = 80
	particles.initial_velocity_max = 220
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = color
	scene.add_child(particles)
	particles.finished.connect(particles.queue_free)

func confetti(pos: Vector2, count := 40) -> void:
	burst(pos, Color(1, 1, 1), count)


func impact(kind: String = "hit") -> void:
	match kind:
		"boss_spawn":
			shake(0.7, 4.5)
			flash(0.18, Color(1.0, 0.85, 0.5, 0.55))
		"boss_death":
			shake(0.9, 6.0)
			flash(0.22, Color(1.0, 0.95, 0.8, 0.65))
		"crit":
			shake(0.32, 2.2)
			flash(0.08, Color(1, 1, 1, 0.28))
		_:
			shake(0.32, 2.4)


func flash(duration: float = 0.12, col: Color = Color(1, 1, 1, 0.35)) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	var r := ColorRect.new()
	r.color = col
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	var scene := get_tree().current_scene
	if scene == null:
		layer.queue_free()
		return
	scene.add_child(layer)
	var tw := layer.create_tween()
	tw.tween_property(r, "color:a", 0.0, maxf(0.05, duration))\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(layer.queue_free)
