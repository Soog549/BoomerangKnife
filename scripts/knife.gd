extends Area2D
class_name Knife

enum State { HELD, FLYING, RETURNING, STUCK }

signal got_caught
signal broke_on_knife(at: Vector2)
signal got_stuck

const THROW_SPEED := 1250.0
const RETURN_SPEED := 850.0
const SPIN_SPEED := 20.0

# За пределами этого «поля» нож считается промазавшим за кадр и возвращается
# (арена 720x1280; запас на бросок вниз/влево/вправо).
const ARENA_MIN := Vector2(-260.0, -300.0)
const ARENA_MAX := Vector2(980.0, 1540.0)

# Минимальная дистанция до точки прицела: тап в сам нож (нулевой вектор) —
# летим вверх по умолчанию, а не зависаем на месте.
const MIN_AIM_DIST := 40.0

var state: State = State.HELD
var return_point := Vector2.ZERO
var velocity := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var blade: Polygon2D = $Blade
@onready var handle: Polygon2D = $Handle

const KNIFE_TEX_PATHS := [
	"res://assets/images/knives/knife_gold.png",
	"res://assets/images/knives/knife_neon.png",
	"res://assets/images/knives/knife_ice.png",
	"res://assets/images/knives/knife_ruby.png",
	"res://assets/images/knives/knife_shadow.png",
	"res://assets/images/knives/knife_elektro.png",
	"res://assets/images/knives/knife_toxic.png",
	"res://assets/images/knives/knife_cosmos.png",
	"res://assets/images/knives/knife_zona.png",
	"res://assets/images/knives/knife_desert.png",
	"res://assets/images/knives/knife_retro.png",
	"res://assets/images/knives/knife_empire.png",
]

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	area_entered.connect(_on_area_entered)
	_apply_skin()

func _apply_skin() -> void:
	var skin: Dictionary = GameState.current_skin()
	# Если для скина есть готовая текстура — показываем её
	var tex_path: String = KNIFE_TEX_PATHS[GameState.selected_skin]
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path) as Texture2D
		sprite.scale = Vector2(0.36, 0.36)  # подгони под габарит процедурного ножа
		sprite.visible = true
		blade.visible = false
		handle.visible = false
		return
	# Fallback: процедурная графика с цветом скина
	sprite.visible = false
	sprite.scale = Vector2.ONE
	blade.visible = true
	handle.visible = true
	blade.color = skin.blade
	handle.color = skin.handle

func throw_toward(target_pos: Vector2, speed_mult := 1.0) -> void:
	_detach_if_stuck()
	_fly_toward(target_pos, speed_mult)

func rethrow_now(target_pos: Vector2, speed_mult := 1.0) -> void:
	_detach_if_stuck()
	_fly_toward(target_pos, speed_mult)

func is_held() -> bool:
	return state == State.HELD

func is_flying() -> bool:
	return state == State.FLYING

func is_stuck() -> bool:
	return state == State.STUCK

## Единый путь запуска полёта: защита от вырожденного направления.
func _fly_toward(target_pos: Vector2, speed_mult: float) -> void:
	velocity = _flight_dir(target_pos) * THROW_SPEED * speed_mult
	state = State.FLYING

func _flight_dir(target_pos: Vector2) -> Vector2:
	var dir := target_pos - global_position
	if dir.length() >= MIN_AIM_DIST:
		return dir.normalized()
	dir = return_point - global_position
	if dir.length() >= MIN_AIM_DIST:
		return dir.normalized()
	return Vector2.UP

## Повторный бросок застрявшего ножа: выходим из-под цели, чтобы не
## улететь вместе с ней, если её успеют добить.
func _detach_if_stuck() -> void:
	if state != State.STUCK:
		return
	var root := get_tree().current_scene
	if get_parent() != root and is_instance_valid(get_parent()):
		remove_from_group("stuck_knife")
		if root != null and is_instance_valid(root):
			root.add_child(self)

func _physics_process(delta: float) -> void:
	match state:
		State.FLYING:
			global_position += velocity * delta
			rotation += SPIN_SPEED * delta
			if global_position.x < ARENA_MIN.x or global_position.x > ARENA_MAX.x \
					or global_position.y < ARENA_MIN.y or global_position.y > ARENA_MAX.y:
				_start_return()
		State.RETURNING:
			global_position = global_position.move_toward(return_point, RETURN_SPEED * delta)
			rotation -= SPIN_SPEED * delta
			if global_position.distance_to(return_point) < 24.0:
				_caught()
		_:
			pass

func _start_return() -> void:
	state = State.RETURNING
	velocity = Vector2.ZERO
	AudioManager.play("return")

func _on_area_entered(area: Area2D) -> void:
	if state != State.FLYING:
		return
	if area.is_in_group("stuck_knife"):
		broke_on_knife.emit(global_position)
		queue_free()
		return
	if area.has_method("on_knife_hit"):
		if area.get("alive") is bool and not area.alive:
			print("[DBG] knife came back from dead target")
			_start_return()
			return
		_stick_to(area)

func _stick_to(target: Area2D) -> void:
	# Мини-босс: удар по броне не принимается — on_knife_hit возвращает false,
	# нож не втыкается, а уходит обратно к руке.
	var accepted: Variant = target.on_knife_hit(self)
	if accepted is bool and not accepted:
		_start_return()
		return
	state = State.STUCK
	var offset := global_position - target.global_position
	rotation = offset.angle() - PI / 2.0
	call_deferred("_defer_reparent", target)
	add_to_group("stuck_knife")
	got_stuck.emit()

## Перецепляем к цели в безопасный момент (не внутри physics-колбэка).
func _defer_reparent(t: Node) -> void:
	if t != null and is_instance_valid(t):
		reparent(t, true)

func _caught() -> void:
	state = State.HELD
	global_position = return_point
	rotation = 0.0
	velocity = Vector2.ZERO
	got_caught.emit()
