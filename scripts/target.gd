extends Area2D
class_name Target

signal all_segments_filled
signal golden_hit  # попадание по золотому сектору

const RADIUS := 110.0

const GOLD_COLOR := Color(1.0, 0.85, 0.2, 1)

var segments := 5
var filled_slots := 0
var rotation_speed := 1.5
var alive := true

# Бонусный сектор: если забить его, получишь монеты.
var golden_slot := -1

# Тип мишени. Геймплейные отличия:
#   NORMAL  — обычная (1 удар на сектор)
#   ARMORED — каждый сектор требует 2 удара (броня), слегка медленнее вращается
#   REGEN   — заполненные секторы восстанавливаются, если долго не попадать
#   MOVING  — плавно ездит влево-вправо (был флаг moving)
#   BOSS    — мини-босс: удары по броне отскакивают (нож возвращается),
#             пробить можно только светящиеся слабые места (weak_slots)
enum Type { NORMAL, ARMORED, REGEN, MOVING, BOSS }

var target_type := Type.NORMAL

# Слабые места мини-босса: только по ним наносится урон.
var weak_slots: Array[int] = []
# Пульсы слабых мест (убиваем при забивании, чтобы tween не «стрелял» по удалённому).
var _weak_pulse_tweens: Array[Tween] = []
# Указатели слабого места (сияние + кристалл), перерисовываются в _rearm_weak.
var _weak_glow: Polygon2D = null
var _weak_shard: Polygon2D = null

# Сколько ударов нужно на каждый сектор (заполняется при setup).
var _slot_hp: Array[int] = []
# Базовый цвет каждого сектора (для восстановления после анфилла/филла).
var _slot_base_colors: Array[Color] = []
# Вспышка-отклик брони (сектор ещё «держит»).
var _flash_pending := false

# Регенерация (только REGEN): после паузы дольше regen_interval заполненный
# сектор снова «зарастает».
var regen_interval := 3.5
var _regen_t := 0.0

# Движущаяся цель: плавно ездит влево-вправо.
var moving := false
var base_x := 0.0
var move_amplitude := 80.0
var move_speed := 1.5
var move_phase := 0.0
var _move_t := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_draw_target()

## new_type: сколько ударов на сектор бронированной цели.
func setup(new_segments: int, speed: float, enable_golden := false, is_moving := false, new_type := Type.NORMAL) -> void:
	segments = max(new_segments, 1)
	filled_slots = 0
	rotation_speed = speed
	alive = true
	golden_slot = -1
	if enable_golden and segments >= 4:
		golden_slot = randi() % segments
	target_type = new_type
	weak_slots.clear()
	_slot_hp.clear()
	for i in segments:
		_slot_hp.append(2 if target_type == Type.ARMORED else 1)
	if target_type == Type.BOSS:
		# Мини-босс: одно обнажённое слабое место (янтарный сектор).
		# После пробития оно уходит на следующий незаполненный сектор.
		weak_slots = [0]
	moving = is_moving or target_type == Type.MOVING
	base_x = position.x
	_move_t = randf() * TAU
	_regen_t = 0.0
	if target_type == Type.ARMORED:
		rotation_speed *= 0.6
	elif target_type == Type.BOSS:
		rotation_speed *= 0.5
	_draw_target()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	if target_type == Type.REGEN and filled_slots > 0:
		_regen_t += delta
		if _regen_t >= regen_interval:
			_regen_t = 0.0
			_unfill_last()
	rotation += rotation_speed * delta
	if moving:
		_move_t += delta * move_speed
		position.x = base_x + sin(_move_t) * move_amplitude

## Предсказанная позиция через `lookahead` секунд (для упреждения при броске).
func predict_position(lookahead: float) -> Vector2:
	var next_x := position.x
	if moving:
		next_x = base_x + sin(_move_t + lookahead * move_speed) * move_amplitude
	return Vector2(next_x, position.y)

## Возвращает true, если нож втыкается (принят удар); false — отскок (босс).
func on_knife_hit(knife: Area2D) -> bool:
	if not alive:
		return false
	_regen_t = 0.0
	# Мини-босс: пробить можно ТОЛЬКО геометрически по слабому месту
	# (янтарный сектор). В броню — отскок + слабое место переезжает.
	if target_type == Type.BOSS:
		if filled_slots >= segments:
			return true
		if not weak_slots.has(_knife_sector(knife)):
			_jump_weak()
			_deflect(knife)
			return false
		var slot := filled_slots
		_fill_slot(slot)
		filled_slots += 1
		if filled_slots < segments:
			_rearm_weak()
		ScoreManager.register_hit()
		GameState.record_hit()
		AudioManager.play("hit")
		FX.burst(knife.global_position, GameState.current_skin().blade, 14)
		if filled_slots >= segments:
			alive = false
			remove_from_group("target")
			all_segments_filled.emit()
			_fade_out()
		return true
	var gain := 2 if GameState.double_hits() else 1
	for i in gain:
		if filled_slots >= segments:
			break
		var slot := filled_slots
		_slot_hp[slot] -= 1
		if _slot_hp[slot] > 0:
			# Броня держит: сектор не заполнен, быстро мигает белым.
			_flash_slot(slot)
			AudioManager.play("clank")
			FX.burst(knife.global_position, Color(0.85, 0.87, 0.9, 1), 8)
			continue
		# Сектор пробит — заполняем (как раньше).
		if slot == golden_slot:
			GameState.record_golden()
			var magnet_on: bool = ScoreManager.booster_magnet or GameState.equip_magnet_enabled()
			magnet_on = magnet_on or GameState.glyph_active("glyph_magnet_e")
			var golden_gain := Economy.GOLDEN_COIN * (2.0 if magnet_on else 1.0)
			golden_gain = int(golden_gain * GameState.gold_coin_mult())
			GameState.add_coins(golden_gain)
			golden_hit.emit()
			FX.burst(knife.global_position, GOLD_COLOR, 24)
			AudioManager.play("level")
		filled_slots += 1
		_fill_slot(slot)
	ScoreManager.register_hit()
	GameState.record_hit()
	AudioManager.play("hit")
	FX.burst(knife.global_position, GameState.current_skin().blade, 14)
	if filled_slots >= segments:
		alive = false
		remove_from_group("target")
		all_segments_filled.emit()
		_fade_out()
	return true

## Индекс сектора, куда геометрически прилетел нож (в локальных координатах цели).
func _knife_sector(knife: Area2D) -> int:
	var local := global_transform.affine_inverse() * knife.global_position
	var a := fposmod(local.angle(), TAU)
	return int(a / (TAU / segments)) % segments

## Отскок: мини-босс не принимает удар по броне, нож возвращается.
func _deflect(knife: Area2D) -> void:
	AudioManager.play("clank")
	FX.burst(knife.global_position, Color(1.0, 0.55, 0.2, 1), 14)
	FX.burst(knife.global_position, Color(0.6, 0.65, 0.75, 1), 6)

## Заполнение сектора: забитый сектор босса гаснет, слабое место уходит дальше.
func _fill_slot(index: int) -> void:
	var sector := get_node_or_null("Visuals/Seg%d" % (index + 1))
	if sector:
		sector.color = Color(0.9, 0.75, 0.3, 1) if target_type != Type.BOSS else Color(0.55, 0.45, 0.22, 1)

## Указатель слабого места: после пробития — на следующий незаполненный сектор.
func _rearm_weak() -> void:
	_paint_weak(filled_slots)

## Удар по броне: слабое место «убегает» в случайный другой незаполненный сектор.
func _jump_weak() -> void:
	var opts: Array[int] = []
	for i in range(filled_slots, segments):
		if i != weak_slots[0]:
			opts.append(i)
	if not opts.is_empty():
		_paint_weak(opts[randi() % opts.size()])

## Перекрашивает сектора под новое слабое место и двигает сияние/кристалл.
func _paint_weak(idx: int) -> void:
	weak_slots = [idx]
	for i in segments:
		var sec := get_node_or_null("Visuals/Seg%d" % (i + 1))
		if sec == null:
			continue
		if i == idx:
			sec.color = Color(1.0, 0.72, 0.25, 1)
		elif i < filled_slots:
			sec.color = Color(0.55, 0.45, 0.22, 1)
		elif i < _slot_base_colors.size():
			sec.color = _slot_base_colors[i]
	if _weak_glow != null and is_instance_valid(_weak_glow):
		_weak_glow.polygon = _sector(segments, idx)
	if _weak_shard != null and is_instance_valid(_weak_shard):
		_weak_shard.polygon = _tri_poly(_sector_mid_angle(segments, idx), RADIUS * 0.5)

## Регенерирующая цель: «заращивает» последний заполненный сектор.
func _unfill_last() -> void:
	if filled_slots <= 0:
		return
	var slot := filled_slots - 1
	filled_slots -= 1
	_slot_hp[slot] = 2 if target_type == Type.ARMORED else 1
	AudioManager.play("regen")
	FX.burst(global_position + Vector2(0, -RADIUS * 0.5), Color(0.35, 0.9, 1.0, 0.8), 8)
	_unhighlight_slot(slot)

var _fading := false

## Закрытая мишень не должна оставаться статичной «мусором» на поле:
## плавно исчезает и удаляется вместе со втыканными в неё ножами.
func _fade_out() -> void:
	if _fading:
		return
	_fading = true
	for tw in _weak_pulse_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_weak_pulse_tweens.clear()
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)

func _highlight_slot(index: int) -> void:
	var sector := get_node_or_null("Visuals/Seg%d" % (index + 1))
	if sector:
		sector.color = Color(0.9, 0.75, 0.3, 1)

func _unhighlight_slot(index: int) -> void:
	var sector := get_node_or_null("Visuals/Seg%d" % (index + 1))
	if sector and index < _slot_base_colors.size():
		sector.color = _slot_base_colors[index]

## Вспышка при ударе, который не пробил броню.
func _flash_slot(index: int) -> void:
	var sector := get_node_or_null("Visuals/Seg%d" % (index + 1))
	if not sector:
		return
	sector.color = Color(0.95, 0.96, 1.0, 1)
	var t := create_tween()
	t.tween_interval(0.08)
	t.tween_callback(func() -> void:
		if is_instance_valid(sector) and index < _slot_base_colors.size():
			sector.color = _slot_base_colors[index])

func _draw_target() -> void:
	for child in get_children():
		if child.name == "Visuals":
			child.queue_free()
	var visuals := Node2D.new()
	visuals.name = "Visuals"

	# Готовая текстура цели = подложка; поверх — процедурные сектора (они дают
	# игровой фидбек: заполнение и золотой сектор при попадании).
	var tex := Assets.load_tex("target", "target_round")
	if tex != null:
		var base := Sprite2D.new()
		base.name = "Base"
		base.texture = tex
		base.scale = Vector2.ONE * (RADIUS * 2.0 / tex.get_width())
		visuals.add_child(base)
		# Концентрические кольца — чтобы «яблочко» читалось на любом стиле
		for rf in [0.72, 0.46, 0.2]:
			var ringl := Line2D.new()
			ringl.points = _ring_pts(RADIUS * rf)
			ringl.width = 3.0
			ringl.default_color = Color(1.0, 0.92, 0.6, 0.55)
			ringl.closed = true
			visuals.add_child(ringl)
	else:
		var ring := _circle(RADIUS, Color(0.55, 0.4, 0.15, 1))
		ring.name = "Ring"
		visuals.add_child(ring)
		var center := _circle(14, Color(0.85, 0.65, 0.3, 1))
		center.name = "Center"
		visuals.add_child(center)

	var visual_base := Color(0.3, 0.28, 0.38, 0.85)
	match target_type:
		Type.ARMORED:
			visual_base = Color(0.55, 0.57, 0.63, 0.9)
		Type.REGEN:
			visual_base = Color(0.25, 0.75, 0.95, 0.35)
		Type.MOVING:
			visual_base = Color(0.35, 0.4, 0.55, 0.85)
		Type.BOSS:
			visual_base = Color(0.24, 0.2, 0.3, 0.95)
	_slot_base_colors.clear()
	for i in segments:
		var sector := Polygon2D.new()
		sector.name = "Seg%d" % (i + 1)
		if i == golden_slot:
			sector.color = GOLD_COLOR
		elif target_type == Type.BOSS and weak_slots.has(i):
			sector.color = Color(1.0, 0.72, 0.25, 0.9)
		elif tex != null:
			sector.color = Color(visual_base.r, visual_base.g, visual_base.b, 0.35)
		else:
			sector.color = visual_base
		sector.polygon = _sector(segments, i)
		visuals.add_child(sector)
		# База для восстановления: у босса НЕ копируем янтарное слабое место
		# (оно мигрирует), а храним цвет брони.
		if target_type == Type.BOSS:
			_slot_base_colors.append(Color(visual_base.r, visual_base.g, visual_base.b, 0.35 if tex != null else 1.0))
		else:
			_slot_base_colors.append(sector.color)

	# Рамка-индикатор и орнаменты типа: у каждого вида свой силуэт.
	match target_type:
		Type.NORMAL:
			var warm := Polygon2D.new()
			warm.name = "WarmRing"
			warm.color = Color(0.6, 0.45, 0.2, 0.35)
			warm.polygons = [_ring_pts(RADIUS * 0.99), _ring_pts(RADIUS * 0.93)]
			visuals.add_child(warm)
		Type.ARMORED:
			var rim := Polygon2D.new()
			rim.name = "ArmorRim"
			rim.color = Color(0.75, 0.78, 0.85, 0.55)
			rim.polygons = [_ring_pts(RADIUS * 0.97), _ring_pts(RADIUS * 0.88)]
			visuals.add_child(rim)
			for k in 6:
				var rivet := _circle(7, Color(0.9, 0.92, 0.96, 0.9))
				rivet.name = "Rivet%d" % k
				rivet.position = Vector2(cos(TAU * k / 6.0), sin(TAU * k / 6.0)) * (RADIUS * 0.74)
				visuals.add_child(rivet)
		Type.REGEN:
			var veil := _circle(RADIUS * 0.9, Color(0.4, 0.92, 1.0, 0.12))
			veil.name = "RegenVeil"
			visuals.add_child(veil)
			for k in 8:
				var grain := _circle(RADIUS * 0.05, Color(0.45, 0.95, 1.0, 0.35))
				grain.name = "Grain%d" % k
				grain.position = Vector2(cos(TAU * k / 8.0 + 0.4), sin(TAU * k / 8.0 + 0.4)) * (RADIUS * 0.84)
				visuals.add_child(grain)
		Type.MOVING:
			for s in [-1.0, 1.0]:
				var fin := Polygon2D.new()
				fin.name = "Fin%d" % (0 if s < 0 else 1)
				fin.color = Color(0.5, 0.75, 1.0, 0.85)
				fin.polygon = _tri_poly(0.0 if s > 0 else PI, RADIUS * 1.12)
				visuals.add_child(fin)
		Type.BOSS:
			var dark := Polygon2D.new()
			dark.name = "BossRim"
			dark.color = Color(0.15, 0.13, 0.2, 0.6)
			dark.polygons = [_ring_pts(RADIUS * 0.98), _ring_pts(RADIUS * 0.9)]
			visuals.add_child(dark)
			# Рога по бокам макушки — узнаваемый силуэт мини-босса.
			for s in [-1.0, 1.0]:
				var horn := Polygon2D.new()
				horn.name = "Horn%d" % (0 if s < 0 else 1)
				horn.color = Color(0.68, 0.62, 0.75, 0.95)
				horn.polygon = _tri_poly(-PI / 2.0 + s * 1.1, RADIUS * 1.18)
				visuals.add_child(horn)

	add_child(visuals)

	# Явное слабое место мини-босса: яркий янтарный сектор + пульсирующее
	# сияние поверх + кристалл-указатель. Polygon2D не имеет blend_mode —
	# мигание делаем через modulate:a.
	if target_type == Type.BOSS and not weak_slots.is_empty():
		var wi: int = weak_slots[0]
		var glow := Polygon2D.new()
		glow.name = "WeakGlow"
		glow.color = Color(1.0, 0.8, 0.3, 0.5)
		glow.polygon = _sector(segments, wi)
		visuals.add_child(glow)
		_weak_glow = glow
		var shard := Polygon2D.new()
		shard.name = "WeakShard"
		shard.color = Color(1.0, 1.0, 0.85, 1)
		shard.polygon = _tri_poly(_sector_mid_angle(segments, wi), RADIUS * 0.5)
		visuals.add_child(shard)
		_weak_shard = shard
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(glow, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(glow, "modulate:a", 0.55, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_weak_pulse_tweens.append(tw)

func _circle(radius: float, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = _ring_pts(radius)
	return poly

func _ring_pts(radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts

func _sector(count: int, index: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var start := TAU * index / count
	var end := TAU * (index + 1) / count
	var steps := 10
	for i in steps + 1:
		var a := lerpf(start, end, float(i) / steps)
		pts.append(Vector2(cos(a), sin(a)) * RADIUS * 0.94)
	pts.append(Vector2.ZERO)
	return pts

## Угол середины сектора (для маркеров по центру).
func _sector_mid_angle(count: int, index: int) -> float:
	return TAU * (index + 0.5) / count

## Треугольный «флажок» от центра к краю под углом (плавники, рога).
func _tri_poly(angle: float, r: float) -> PackedVector2Array:
	var p0 := Vector2(cos(angle), sin(angle)) * r * 0.4
	var p1 := Vector2(cos(angle - 0.55), sin(angle - 0.55)) * r
	var p2 := Vector2(cos(angle + 0.55), sin(angle + 0.55)) * r
	return PackedVector2Array([p0, p1, p2])
