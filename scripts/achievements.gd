extends RefCounted
class_name Achievements

## Определения ачивок. Каждая проверяется по условию и выдаёт монеты-награду.
##
## Условия:
##   {"type": "stat",  "stat": "<имя поля в GameState>", "target": N}
##   {"type": "mode",  "mode": "<id мода>"}                    # открыт мод
##   {"type": "skin",  "skin": <индекс>}                       # открыт скин
##   {"type": "objective", "obj": "<id цели>"}                 # выполнена цель
##   {"type": "endless", "wave": N}                            # добрался до волны
##   {"type": "daily", "streak": N}                            # серия дней

const LIST := [
	{"id": "first_blood",    "label": "Первая кровь",  "desc": "Попади в цель 10 раз",  "reward": 10,  "cond": {"type": "stat", "stat": "total_hits", "target": 10}},
	{"id": "sharpshooter",   "label": "Меткий",        "desc": "Попади в цель 100 раз", "reward": 40,  "cond": {"type": "stat", "stat": "total_hits", "target": 100}},
	{"id": "ace",            "label": "Ас",            "desc": "Попади в цель 500 раз", "reward": 200, "cond": {"type": "stat", "stat": "total_hits", "target": 500}},
	{"id": "boomerang_star", "label": "Звезда бумеранга","desc": "Поймай нож 50 раз",   "reward": 60,  "cond": {"type": "stat", "stat": "total_catches", "target": 50}},
	{"id": "completer_10",   "label": "Стабильный",    "desc": "Пройди 10 уровней",    "reward": 50,  "cond": {"type": "stat", "stat": "total_levels", "target": 10}},
	{"id": "completer_50",   "label": "Ветеран",       "desc": "Пройди 50 уровней",    "reward": 250, "cond": {"type": "stat", "stat": "total_levels", "target": 50}},
	{"id": "collector_1",    "label": "Коллекционер",  "desc": "Открой свой первый скин", "reward": 30, "cond": {"type": "owned_skins", "target": 2}},
	{"id": "collector_all",  "label": "Завершитель",   "desc": "Открой все скины",     "reward": 300, "cond": {"type": "owned_skins", "target": 5}},
	{"id": "modder_1",       "label": "Экипировщик",   "desc": "Открой свой первый мод", "reward": 30, "cond": {"type": "owned_modes", "target": 1}},
	{"id": "modder_3",       "label": "Микроменеджер", "desc": "Открой 3 мода",         "reward": 120, "cond": {"type": "owned_modes", "target": 3}},
	{"id": "endless_5",      "label": "Выживший",      "desc": "Дойди до 5-й волны в бесконечном режиме", "reward": 80, "cond": {"type": "endless", "wave": 5}},
	{"id": "endless_15",     "label": "Бессмертный",   "desc": "Дойди до 15-й волны в бесконечном режиме", "reward": 250, "cond": {"type": "endless", "wave": 15}},
	{"id": "daily_3",        "label": "На связи",      "desc": "Серия ежедневных наград 3 дня", "reward": 60, "cond": {"type": "daily", "streak": 3}},
	{"id": "ad_5",           "label": "Щедрый зритель","desc": "Посмотри 5 реклам",    "reward": 100, "cond": {"type": "stat", "stat": "total_ads_watched", "target": 5}},
	{"id": "equip_any",     "label": "Снаряжён",     "desc": "Надень предмет снаряжения", "reward": 20, "crystals": 5, "cond": {"type": "equipped", "target": 1}},
	{"id": "equip_all",     "label": "Рыцарь",       "desc": "Надень снаряжение во все 5 слотов", "reward": 80, "crystals": 15, "cond": {"type": "equipped", "target": 5}},
	{"id": "crystal_10",    "label": "Кристальный",  "desc": "Накопи 10 кристаллов",  "reward": 0, "crystals": 5, "cond": {"type": "crystals", "target": 10}},
	{"id": "glyph_1",       "label": "Шлифовщик",     "desc": "Улучши глиф до 3-го уровня", "reward": 80, "cond": {"type": "glyph_level", "target": 3}},
	{"id": "tournament_1",  "label": "Турнирный волк","desc": "Выиграй 2 дуэли",        "reward": 60, "cond": {"type": "stat", "stat": "total_duel_wins", "target": 2}},
	{"id": "player_10",     "label": "Ветеран боя",   "desc": "Достигни 10-го уровня игрока", "reward": 100, "cond": {"type": "player_level", "target": 10}},
	{"id": "shards_50",     "label": "Мастер осколков","desc": "Накопи 50 осколков",    "reward": 40, "cond": {"type": "shards", "target": 50}},
	{"id": "endless_25",    "label": "Бесконечный",   "desc": "Дойди до 25-й волны",    "reward": 300, "cond": {"type": "endless", "wave": 25}},
]

static func is_unlocked(a: Dictionary) -> bool:
	return GameState.has_achievement(a.id)

static func is_completed(a: Dictionary) -> bool:
	return _check(a.cond)

# ---------- проверка условия ----------
static func _check(cond: Dictionary) -> bool:
	match cond.type:
		"stat":
			return GameState.get(cond.stat) >= cond.target
		"owned_skins":
			var count := 0
			for i in GameState.SKINS.size():
				if GameState.is_skin_owned(i):
					count += 1
			return count >= cond.target
		"owned_modes":
			var count := 0
			for mode_key in GameState.MODES:
				if GameState.is_mode_owned(mode_key):
					count += 1
			return count >= cond.target
		"endless":
			return GameState.endless_best_wave >= cond.wave
		"daily":
			return GameState.daily_streak >= cond.streak
		"equipped":
			return GameState.equipped_ids().size() >= cond.target
		"crystals":
			return GameState.crystals >= cond.target
		"glyph_level":
			var max_lv := 0
			for gid in GameState.owned_glyphs:
				max_lv = maxi(max_lv, GameState.glyph_level(gid))
			return max_lv >= cond.target
		"player_level":
			return GameState.player_level >= cond.target
		"shards":
			return GameState.shards >= cond.target
		_:
			return false

## Обновить все ачивки, выдать монеты-награды за только что разблокированные.
static func check_all() -> void:
	for a in LIST:
		if not is_unlocked(a) and is_completed(a):
			if GameState.unlock_achievement(a.id):
				GameState.add_coins(a.reward)
				if a.has("crystals") and a.crystals > 0:
					GameState.add_crystals(a.crystals)
					AudioManager.play("level")
				else:
					AudioManager.play("level")
