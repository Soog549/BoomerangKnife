extends RefCounted
class_name Quests

## Ежедневные квесты: каждый день выбирается одно задание из списка.
##
## Прогресс считается по «сегодняшним» счётчикам в GameState:
##   hits_today / catches_today / golden_today / runs_today / earned_today
## Счётчики сбрасываются в полночь (по системной дате).

const LIST := [
	{"id": "hits_25",  "label": "Сделай 25 попаданий",       "target": 25,  "reward": 40, "stat": "hits_today", "booster": "heart"},
	{"id": "catches_15", "label": "Поймай нож 15 раз",       "target": 15,  "reward": 50, "stat": "catches_today", "booster": "shield"},
	{"id": "gold_3",   "label": "Забей 3 золотых сектора",   "target": 3,   "reward": 60, "stat": "golden_today", "booster": "magnet"},
	{"id": "runs_3",   "label": "Сыграй 3 забега",           "target": 3,   "reward": 60, "stat": "runs_today", "booster": "talisman"},
	{"id": "earn_150", "label": "Заработай 150 монет",       "target": 150, "reward": 80, "stat": "earned_today", "booster": "heart"},
	{"id": "hits_50",   "label": "Сделай 50 попаданий",       "target": 50,  "reward": 100, "stat": "hits_today", "booster": "talisman"},
	{"id": "golden_5",  "label": "Забей 5 золотых секторов",  "target": 5,   "reward": 80, "stat": "golden_today", "booster": "shield"},
	{"id": "catches_25", "label": "Поймай нож 25 раз",       "target": 25,  "reward": 120, "stat": "catches_today", "booster": "heart"},
]

## Какое задание выпало сегодня (детерминированно по дате).
static func pick_for_today() -> Dictionary:
	var date := Time.get_date_string_from_system()
	var idx := absi(hash(date)) % LIST.size()
	return LIST[idx]
