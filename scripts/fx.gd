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
	var dur: float = maxf(0.25, duration * 1.4)
	var steps: int = 14
	var phase: float = randf() * TAU
	for k in steps:
		var tt: float = float(k) / float(steps)
		var damp: float = pow(1.0 - tt, 1.8)
		var off := Vector2(cos(phase + tt * 5.2), sin(phase + tt * 4.4)) * strength * damp * 0.6
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
