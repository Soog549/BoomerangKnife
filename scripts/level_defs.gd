extends RefCounted
class_name LevelDefs

## Генератор конфигураций уровней. Каждый уровень может содержать несколько
## целей (добавляется по мере прогресса), золотые секторы и движущиеся цели.

## Возвращает массив словарей-конфигураций целей для заданного уровня.
## Каждая конфигурация:
##   {segments, speed, x, y, golden (bool), moving (bool)}
static func configs_for_level(level: int) -> Array:
	var configs: Array = []

	var target_count := 1
	if level >= 5:
		target_count = 2
	if level >= 10:
		target_count = 3

	var speed_mult := 0.8 + (level - 1) * 0.06
	var positions := positions_for_count(target_count)

	for i in target_count:
		var golden := false
		# Золотой сектор появляется с уровня 3, шанс растёт
		if level >= 3 and randf() < 0.25 + (level - 3) * 0.02:
			golden = true

		# Тип цели: сначала редкие, затем более частые по мере уровня.
		var type := _type_for(level)

		# Движущаяся цель не может быть золотой одновременно (чтобы не перегружать игрока)
		if type == 2:
			golden = false
		# Мини-босс: золотого сектора нет (и без того много секторов).
		if type == 4:
			golden = false

		var p: Vector2 = positions[i]
		var config := {
			"segments": _segments_for(level, i),
			"speed": speed_mult,
			"x": p.x,
			"y": p.y,
			"golden": golden,
			"moving": type == 2,
			"type": type,
		}
		configs.append(config)
	return configs

## 0 NORMAL, 1 ARMORED, 2 MOVING, 3 REGEN, 4 BOSS.
static func _type_for(level: int) -> int:
	# Мини-босс: с уровня 14, шанс растёт с уровнем.
	if level >= 14 and randf() < 0.05 + (level - 14) * 0.02:
		return 4
	if level >= 12 and randf() < 0.12 + (level - 12) * 0.025:
		return 3
	if level >= 6 and randf() < 0.15 + (level - 6) * 0.02:
		return 1
	if level >= 7 and randf() < 0.1 + (level - 7) * 0.02:
		return 2
	return 0

## Непересекающаяся расстановка (RADIUS=110 -> зазоры >= 260px).
## Строки-«зацепки» для предсказуемого упреждения.
static func positions_for_count(count: int) -> Array:
	match count:
		1:
			return [Vector2(360, 300)]
		2:
			return [Vector2(170, 300), Vector2(550, 300)]
		3:
			return [Vector2(100, 300), Vector2(360, 300), Vector2(620, 300)]
		4:
			return [Vector2(100, 300), Vector2(360, 300), Vector2(620, 300), Vector2(360, 560)]
		_:
			# fallback: в один ряд вверх
			var out: Array = []
			for i in count:
				out.append(Vector2(360.0, 300.0 - i * 40.0))
			return out

static func _segments_for(level: int, index: int) -> int:
	var base := 3 + (level - 1) / 2
	if index > 0:
		base -= 1
	return clampi(base, 3, 10)
