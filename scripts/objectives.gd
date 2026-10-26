extends RefCounted
class_name Objectives

## Определения целей и вычисление прогресса.
##
## Типы целей (stat): total_hits / total_catches / total_levels / total_ads_watched.

const LIST := [
	{"id": "hit_100",   "stat": "total_hits",   "target": 100, "reward": 50,  "label": "100 попаданий"},
	{"id": "hit_500",   "stat": "total_hits",   "target": 500, "reward": 150, "label": "500 попаданий"},
	{"id": "catch_50",  "stat": "total_catches","target": 50,  "reward": 40,  "label": "50 возвратов ножа"},
	{"id": "lv_10",     "stat": "total_levels", "target": 10,  "reward": 80,  "label": "10 пройденных уровней"},
	{"id": "lv_30",     "stat": "total_levels", "target": 30,  "reward": 200, "label": "30 пройденных уровней"},
	{"id": "ad_3",      "stat": "total_ads_watched","target": 3,  "reward": 60, "label": "3 просмотренных рекламы"},
	{"id": "ad_10",     "stat": "total_ads_watched","target": 10, "reward": 250, "label": "10 просмотренных рекламы"},
]

## Текущий прогресс по цели.
static func progress(obj: Dictionary) -> int:
	var stat: String = obj.stat
	return GameState.get(stat)

## Выполнена ли цель (прогресс >= target).
static func is_done(obj: Dictionary) -> bool:
	return progress(obj) >= obj.target

## Забрана ли награда.
static func is_claimed(obj: Dictionary) -> bool:
	return GameState.is_objective_claimed(obj.id)


## Полный список целей: базовые + сгенерированные до 509.
static func all() -> Array:
	var out: Array = []
	for o: Dictionary in LIST:
		out.append(o)
	var kinds := [
		["total_hits", 250, "попаданий"],
		["total_catches", 50, "ловель"],
		["total_levels", 10, "уровней"],
		["total_ads_watched", 5, "роликов"],
	]
	var i: int = out.size()
	var tier: int = 1
	while out.size() < 509:
		var k: Array = kinds[(i) % kinds.size()]
		var target: int = int(k[1]) * (tier + 1)
		var reward: int = 20 + tier * 10
		out.append({
			"id": "gen_%d" % i,
			"stat": k[0],
			"target": target,
			"reward": reward,
			"label": "%d %s" % [target, k[2]],
		})
		i += 1
		if i % kinds.size() == 0:
			tier += 1
	return out
