extends Node

## Единый счётчик забега.
## Счёт = фактическое количество попаданий (каждое +1 очко, золотые секторы —
## отдельно монетами). Множитель растёт на 0.1 за каждую достигнутую шкалу
## серии подряд: 50 / 100 / 200 / 400 / 800 ... и сбрасывается при промахе.

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal level_changed(new_level: int)
signal multiplier_changed(new_mult: float)

const MILESTONES := [50, 100, 200, 400, 800, 1600]

var score := 0
var lives := 3
var level := 1
var hits := 0
var streak := 0
var multiplier := 1.0
var _next_milestone := 50.0
var booster_magnet := false    # магнит: золотые секторы дают x2 монет
var booster_talisman := false  # талисман: +50% очков за забег

func reset() -> void:
	score = 0
	hits = 0
	streak = 0
	multiplier = 1.0
	_next_milestone = 50.0
	lives = GameState.start_lives()
	level = 1
	booster_magnet = false
	booster_talisman = false
	score_changed.emit(score)
	lives_changed.emit(lives)
	level_changed.emit(level)
	multiplier_changed.emit(multiplier)

func register_hit() -> void:
	hits += 1
	streak += 1
	# Шкала серии подряд -> поднимаем множитель на десятую долю.
	if float(streak) >= _next_milestone:
		multiplier = snappedf(multiplier + 0.1, 0.1)
		var idx := MILESTONES.bsearch(int(_next_milestone))
		_next_milestone = MILESTONES[min(idx + 1, MILESTONES.size() - 1)]
		multiplier_changed.emit(multiplier)
	var talisman_mult := 1.5 if booster_talisman else 1.0
	score += max(1, int(round(multiplier * talisman_mult)))
	score_changed.emit(score)

func register_catch() -> void:
	# Возврат ножа очков не даёт: счёт — только попадания.
	pass

func register_miss() -> void:
	streak = 0
	multiplier = 1.0
	_next_milestone = 50.0
	multiplier_changed.emit(multiplier)
	lives -= 1
	lives_changed.emit(lives)

func set_lives(value: int) -> void:
	lives = max(value, 0)
	lives_changed.emit(lives)

func next_level() -> void:
	level += 1
	level_changed.emit(level)
