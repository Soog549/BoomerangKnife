extends Node

## Глобальные эффекты: частицы и тряска экрана. Autoload-синглтон FX.

func shake(duration: float, strength: float) -> void:
	if not GameState.shake_enabled:
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.has_node("Camera2D"):
		return
	tween_kill()
	var cam: Camera2D = scene.get_node("Camera2D")
	var base := cam.position
	tween = cam.create_tween()
	var steps := int(duration / 0.03)
	for i in steps:
		tween.tween_property(cam, "position",
			base + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)),
			0.03)
	tween.tween_property(cam, "position", base, 0.05)

var tween: Tween

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
