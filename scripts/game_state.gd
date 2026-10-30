extends Node

## Хранит выбор игрока, настройки и мета-прогрессию (разблокировки, магазин).
## Сохраняется в user://settings.cfg

signal settings_changed
signal economy_changed  # обновились владение/покупки
signal coins_changed(total: int)
signal stats_changed  # обновились счётчики прогресса
signal daily_changed  # обновились ежедневные награды
signal achievements_changed  # новая ачивка открыта
signal leaderboard_changed

const SAVE_PATH := "user://settings.cfg"
const SAVE_DEBOUNCE_SECONDS := 1.0   # как часто реально пишем на диск при частых событиях

var _save_timer: SceneTreeTimer = null

const DIFFICULTIES := {
	"easy":   {"label": "Лёгкий",  "lives": 5, "target_speed": 0.8, "base_segs": 4, "score_mult": 0.75},
	"normal": {"label": "Средний", "lives": 3, "target_speed": 1.0, "base_segs": 5, "score_mult": 1.0},
	"hard":   {"label": "Сложный", "lives": 2, "target_speed": 1.35, "base_segs": 8, "score_mult": 1.5},
}

# Каждый мод: label (имя), desc (описание), unlock_level (бесплатно при этом уровне).
const MODES := {
	"sturdy":   {"label": "Упорство",     "desc": "+2 жизни",              "unlock_level": 2},
	"swift":    {"label": "Молниеносный", "desc": "Нож летит на 35% быстрее", "unlock_level": 4},
	"scorpion": {"label": "Скорпион",     "desc": "Множитель каждые 2 удара", "unlock_level": 6},
	"greed":    {"label": "Жадность",     "desc": "+50% очков за попадание", "unlock_level": 8},
	"double":   {"label": "Удвоение",     "desc": "Попадание засчитывает 2 сегмента", "unlock_level": 10},
	"regen":    {"label": "Регенерация",  "desc": "+1 жизнь при возврате ножа", "unlock_level": 12},
}

# Каждый скин: label, unlock_level, цвета (для процедурного fallback).
const SKINS := [
	{"label": "Золото", "unlock_level": 1, "blade": Color(0.95, 0.8, 0.3),  "handle": Color(0.45, 0.3, 0.12)},
	{"label": "Неон",   "unlock_level": 3, "blade": Color(0.2, 1.0, 0.6),   "handle": Color(0.1, 0.45, 0.3)},
	{"label": "Лёд",    "unlock_level": 6, "blade": Color(0.5, 0.85, 1.0),  "handle": Color(0.2, 0.4, 0.6)},
	{"label": "Рубин",  "unlock_level": 9, "blade": Color(1.0, 0.3, 0.3),   "handle": Color(0.5, 0.1, 0.1)},
	{"label": "Тень",   "unlock_level": 12, "blade": Color(0.35, 0.35, 0.42), "handle": Color(0.1, 0.1, 0.12)},
	{"label": "Электро", "unlock_level": 15, "blade": Color(0.3, 0.7, 1.0), "handle": Color(0.15, 0.35, 0.6)},
	{"label": "Токси",   "unlock_level": 18, "blade": Color(0.6, 1.0, 0.3), "handle": Color(0.25, 0.5, 0.15)},
	{"label": "Космос",  "unlock_level": 22, "blade": Color(0.65, 0.35, 0.9), "handle": Color(0.3, 0.15, 0.5)},
	{"label": "Зона", "unlock_level": 26, "blade": Color(0.48, 0.55, 0.23), "handle": Color(0.25, 0.22, 0.15)},
	{"label": "Пустыня", "unlock_level": 30, "blade": Color(0.88, 0.65, 0.30), "handle": Color(0.45, 0.30, 0.15)},
	{"label": "Ретро", "unlock_level": 34, "blade": Color(1.00, 0.85, 0.10), "handle": Color(0.10, 0.10, 0.16)},
	{"label": "Империя", "unlock_level": 40, "blade": Color(0.85, 0.70, 0.30), "handle": Color(0.45, 0.10, 0.10)},
]

# ---- состояние ----
var difficulty := "normal"
var selected_skin := 0
var last_mode_scene := ""
var btn_side := "right"
var frontier_mode := false
var campaign_intro_seen := false
var chapter_quest := ""

const CHAPTER_STORY := {
	1: ["Неоновый разлом: город торгует памятью.", "Выбор: вернуть своё — или чужое."],
	2: ["Ледяной бастион: орден хранит память вмёрзшей.", "Скит впервые боится."],
	3: ["Рубиновые шахты: кузня имплантов.", "Сила — за память. Твоя цена?"],
	4: ["Тень Архивов: правда о Цикле.", "Ты — не первый Оператор."],
	5: ["Электро-степь: кочевники-киборги.", "Союз — за долю памяти."],
	6: ["Токсичные топи: цена симбиоза.", "Машина шепчет голосом предка."],
	7: ["Космический оазис: финал.", "Разорвать Цикл — или стать им."],
}

const CLASS_BONUS := {
	0: {"hp": 1.15},            # Воин — живучесть
	1: {"move": 1.10},          # Разбойник — скорость
	2: {"throw": 1.12},         # Маг — сила броска
	3: {"throw": 1.08, "move": 1.04},  # Лучник
	4: {"hp": 1.20, "move": 0.95},     # Рыцарь
	5: {"dmg": 1.10, "hp": 0.95},      # Берсерк
	6: {"move": 1.14, "hp": 0.92},     # Ассасин
	7: {"hp": 1.18, "dmg": 1.05},      # Паладин
	8: {"hp": 1.10, "throw": 1.05},    # Друид
	9: {"dmg": 1.15, "hp": 0.95},      # Монах (КИ)
	10: {"move": 1.08, "dmg": 1.06},   # Пират
	11: {"dmg": 1.12},                 # Самурай
	12: {"move": 1.16, "hp": 0.90},    # Ниндзя
	13: {"hp": 1.22, "move": 0.94},    # Викинг
	14: {"throw": 1.14},               # Стрелок
	15: {"hp": 1.08, "throw": 1.08},   # Алхимик
	16: {"dmg": 1.14, "hp": 0.93},     # Некромант
	17: {"hp": 1.12, "dmg": 1.05},     # Инженер
	18: {"throw": 1.10, "move": 1.05}, # Охотник
	19: {"hp": 1.10, "dmg": 1.10, "move": 0.96}, # Шаман (аура)
	20: {"dmg": 1.12, "hp": 1.10},     # Чемпион
	21: {"throw": 1.12, "move": 1.06}, # Принцесса
	22: {"dmg": 1.20, "hp": 1.05},     # Кулачный
}

const CHAPTERS := [
	{"n": "ПРОБУЖДЕНИЕ", "unlock": 1},
	{"n": "НЕОНОВЫЙ РАЗЛОМ", "unlock": 3},
	{"n": "ЛЕДЯНОЙ БАСТИОН", "unlock": 5},
	{"n": "РУБИНОВЫЕ ШАХТЫ", "unlock": 8},
	{"n": "ТЕНЬ АРХИВОВ", "unlock": 12},
	{"n": "ЭЛЕКТРО-СТЕПЬ", "unlock": 16},
	{"n": "ТОКСИЧНЫЕ ТОПИ", "unlock": 20},
	{"n": "КОСМИЧЕСКИЙ ОАЗИС", "unlock": 25},
]
var selected_modes: Array[String] = []
var gold_knife_active := false  # флаг забега: золотой нож даёт 2 сегмента за удар
var boosters: Dictionary = {"heart": 0, "shield": 0, "magnet": 0, "talisman": 0}  # инвентарь
var armed_booster := ""   # бустер, который сработает в следующем забеге
var owned_equipment: Array[String] = []      # купленные предметы снаряжения
var equipped: Dictionary = {}                 # слот -> id предмета (helmet/armor/boots/weapon/ring)
var player_xp := 0
var player_level := 1
var owned_glyphs: Array[String] = []           # купленные вечные глифы
var temp_glyphs: Dictionary = {}               # временные глифы: id -> осталось забегов
var equipped_glyphs: Array[String] = []        # активные глифы (слоты); лимит GLYPH_SLOTS
var shards := 0                                   # осколки кристаллов (валюта шлифовки)
var shards_today := 0                             # осколков за дуэли сегодня (дневной кап) | duel shards today (daily cap)
var shards_day := ""                              # дата счётчика shards_today | date for shards_today
var tournament_score := 0                          # очки за текущий турнир
var tournament_claimed_week := -1                  # номер недели, за которую забрана награда
var glyph_levels: Dictionary = {}                 # глиф -> уровень улучшения (1..5)
var vip_days_left := 0                         # остаток VIP-подписки (дней)
var last_vip_claim := ""                         # дата последнего забора VIP-бонуса
var volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var tutorial_done := false
var locale := "ru"
var control_mode := "auto"   # auto | touch | keyboard
var auto_detect := true
var is_touch := false
var last_screen := Vector2i.ZERO
var joy_scale := 1.0
var auto_aim := true
var avatar := 0
var shake_enabled := true
var particles_enabled := true
var landscape_mode := false

func apply_orientation() -> void:
	if OS.get_name() != "Android":
		return
	if landscape_mode:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	else:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
var high_score := 0

# ---- мета-прогрессия ----
var max_level_reached := 1        # достигнутый (наибольший) уровень за все сессии
var owned_skins: Array[int] = [0] # индексы купленных за рекламу скинов
var owned_avatars: Array = [0]
var relics_total := 0
var arena_tutorial_done := false
var music_track := -1
var style_pack := "base"
var seen_lore: Dictionary = {}
var is_supporter := false
var fortune_day := ""
var login_streak := 0
var last_login_unix := 0
var arena_drops := true
var survival_mode := false
var extra_knives := 0
var arena_ach: Array = []
var owned_modes: Array[String] = []  # моды, купленные за рекламу

# ---- валюта и статистика ----
var coins := 0
var crystals := 0       # премиум-валюта (кристаллы)
var consumables: Dictionary = {"gold_knife": 0}   # расходники (золотой нож на N бросков)
var total_hits := 0
var total_catches := 0
var total_levels := 0
var total_ads_watched := 0
var total_duel_wins := 0
var ad_coins_watched_today := 0      # rewarded-реклам за монеты просмотрено сегодня
var ad_coins_watched_date := ""      # дата счётчика ad_coins_watched_today
var crystal_ads_today := 0           # rewarded-реклам за кристаллы сегодня
var crystal_ads_date := ""           # дата счётчика crystal_ads_today

# ---- ежедневные квесты ----
var quest_date := ""                 # дата актуального квеста
var quest_id := ""                   # id задания на сегодня
var quest_claimed := false           # забрано ли задание
var hits_today := 0                  # счётчики «сегодня» для прогресса квестов
var catches_today := 0
var golden_today := 0
var runs_today := 0
var earned_today := 0

var claimed_objectives: Array[String] = []
var unlocked_achievements: Array[String] = []
var endless_best_wave := 0
var endless_play_count := 0
var best_score_total := 0  # лучший суммарный счёт за все режимы
var leaderboard: Array = []   # [{name, score, mode}], топ-10 по убыванию

# ---- конфигурация дуэли (генерируется один раз на матч) ----
var duel_config: Dictionary = {}
var forced_skin := -1  # временный скин для дуэли (оба игрока стреляют одинаково)
var player_name := tr("Игрок")  # имя для лидерборда (можно редактировать в будущем)
var last_daily_claim: String = ""        # дата последнего получения (ГГГГ-ММ-ДД)
var daily_streak := 0                     # серия подряд дней
var daily_reward_index := 0               # какой день в календаре следующий (0..6)

# ---- паки кристаллов за рекламу ----
var crystal_pack_prog: Dictionary = {}            # пак -> просмотрено реклам
var crystal_pack_claimed_ids: Array[String] = []  # полученные паки

func _ready() -> void:
	load_settings()
	var fresh := not FileAccess.file_exists(SAVE_PATH)
	_auto_detect()
	_apply_screen_mode()
	if fresh:
		coins = 150
		save_settings()

func _apply_screen_mode() -> void:
	var w := get_window()
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_size = Vector2i(720, 1280)
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	else:
		w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

# ---------- доступ к данным ----------
func current_skin() -> Dictionary:
	if forced_skin >= 0 and forced_skin < SKINS.size():
		return SKINS[forced_skin]
	if selected_skin < 0 or selected_skin >= SKINS.size():
		selected_skin = 0
	return SKINS[selected_skin]

func difficulty_data() -> Dictionary:
	return DIFFICULTIES[difficulty]

func start_lives() -> int:
	var lives: int = difficulty_data().lives
	if has_mode("sturdy"):
		lives += 2
	lives += Economy.totals(equipped_ids()).lives
	if glyph_active("glyph_vital_e"):
		lives += 1
	return lives

func knife_speed_mult() -> float:
	var speed := 1.0
	if has_mode("swift"):
		speed = 1.35
	speed *= Economy.totals(equipped_ids()).speed
	if glyph_active("glyph_speed_t"):
		speed *= 1.2
	return speed

func target_speed_mult() -> float:
	return difficulty_data().target_speed

func score_mult() -> float:
	var mult: float = difficulty_data().score_mult
	if has_mode("greed"):
		mult *= 1.5
	mult *= Economy.totals(equipped_ids()).score
	if glyph_active("glyph_crit_t"):
		mult *= 1.5
	mult *= Economy.player_score_bonus(player_level)
	return mult

## Пассивный щит от снаряжения (блок первого промаха каждый забег).
func equip_shield_enabled() -> bool:
	return Economy.totals(equipped_ids()).shield

## Пассивный магнит от снаряжения (золотые монеты x2).
func equip_magnet_enabled() -> bool:
	return Economy.totals(equipped_ids()).magnet or glyph_active("glyph_magnet_e")

## Доп. множитель монет за золотые секторы (глиф удачи: +50%).
func gold_coin_mult() -> float:
	var m := 1.0
	if glyph_active("glyph_luck_e"):
		m *= 1.5
	return m

func multiplier_gap() -> int:
	if has_mode("scorpion"):
		return 2
	return 3

func double_hits() -> bool:
	return has_mode("double") or gold_knife_active

func regen_enabled() -> bool:
	return has_mode("regen")

# ---------- владение и разблокировка ----------
func is_skin_owned(index: int) -> bool:
	return SKINS[index].unlock_level <= max_level_reached or index in owned_skins

func is_mode_owned(mode: String) -> bool:
	var data: Dictionary = MODES[mode]
	return data.unlock_level <= max_level_reached or mode in owned_modes

func has_mode(mode: String) -> bool:
	return mode in selected_modes

func skin_unlock_level(index: int) -> int:
	return SKINS[index].unlock_level

func mode_unlock_level(mode: String) -> int:
	return MODES[mode].unlock_level

# ---------- валюта ----------
func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	_reset_quest_day_if_needed()
	earned_today += amount
	coins += amount
	coins_changed.emit(coins)
	_schedule_save()

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	_schedule_save()
	return true

# ---------- премиум-валюта (кристаллы) ----------
func add_crystals(amount: int) -> void:
	if amount <= 0:
		return
	crystals += amount
	coins_changed.emit(coins)
	_schedule_save()
	Achievements.check_all()

func spend_crystals(amount: int) -> bool:
	if crystals < amount:
		return false
	crystals -= amount
	coins_changed.emit(coins)
	_schedule_save()
	return true

# ---------- расходники ----------
## Сколько штук указанного расходника есть.
func consumable_count(c_id: String) -> int:
	return int(consumables.get(c_id, 0))

## Добавить расходник.
func add_consumable(c_id: String, amount: int) -> void:
	consumables[c_id] = consumable_count(c_id) + amount
	_schedule_save()
	economy_changed.emit()

## Израсходовать один расходник.
func consume_consumable(c_id: String) -> bool:
	if consumable_count(c_id) <= 0:
		return false
	consumables[c_id] = consumable_count(c_id) - 1
	save_settings()
	economy_changed.emit()
	return true

# ---------- статистика (для целей) ----------
func record_hit() -> void:
	_reset_quest_day_if_needed()
	total_hits += 1
	hits_today += 1
	add_player_xp(1)
	stats_changed.emit()
	_schedule_save()
	Achievements.check_all()

func record_catch() -> void:
	_reset_quest_day_if_needed()
	total_catches += 1
	catches_today += 1
	add_player_xp(2)
	stats_changed.emit()
	_schedule_save()
	Achievements.check_all()

func record_level() -> void:
	total_levels += 1
	add_player_xp(5)
	stats_changed.emit()
	Achievements.check_all()

## Золотой сектор сегодня (для ежедневного квеста).
func record_golden() -> void:
	_reset_quest_day_if_needed()
	golden_today += 1
	stats_changed.emit()
	_schedule_save()
	Achievements.check_all()

## Победа в дуэли (для ачивки и статистики).
func record_duel_win() -> void:
	total_duel_wins += 1
	stats_changed.emit()
	_schedule_save()
	Achievements.check_all()
	Toast.show_reward(tr("Победа в дуэли! +2 осколка"))

## Классический забег завершён (для квеста «сыграй N забегов»).
func record_run() -> void:
	_reset_quest_day_if_needed()
	runs_today += 1
	_schedule_save()

func record_ad_watched() -> void:
	total_ads_watched += 1
	stats_changed.emit()
	_schedule_save()
	Achievements.check_all()

# ---- дневной лимит рекламы за монеты ----
## Можно ли сейчас посмотреть rewarded-рекламу за монеты (не больше лимита в сутки).
func can_watch_coins_ad() -> bool:
	_reset_ad_coin_counter_if_new_day()
	return ad_coins_watched_today < Economy.AD_DAILY_CAP

## Отметить просмотр монетной рекламы. Возвращает true, если засчитано.
func record_coin_ad() -> bool:
	if not can_watch_coins_ad():
		return false
	ad_coins_watched_today += 1
	save_settings()
	return true

## Можно ли посмотреть рекламу за кристаллы сегодня.
func can_watch_crystal_ad() -> bool:
	_reset_crystal_ad_counter_if_new_day()
	return crystal_ads_today < Economy.CRYSTAL_AD_DAILY_CAP

## Отметить рекламу за кристаллы. Возвращает true, если засчитано.
func record_crystal_ad() -> bool:
	if not can_watch_crystal_ad():
		return false
	crystal_ads_today += 1
	save_settings()
	return true

## Сколько реклам за кристаллы осталось сегодня.
func crystal_ads_left() -> int:
	_reset_crystal_ad_counter_if_new_day()
	return maxi(Economy.CRYSTAL_AD_DAILY_CAP - crystal_ads_today, 0)

func _reset_crystal_ad_counter_if_new_day() -> void:
	if crystal_ads_date != today_string():
		crystal_ads_date = today_string()
		crystal_ads_today = 0

## Сколько rewarded-просмотров за монеты осталось сегодня.
func coin_ads_left() -> int:
	_reset_ad_coin_counter_if_new_day()
	return maxi(Economy.AD_DAILY_CAP - ad_coins_watched_today, 0)

func _reset_ad_coin_counter_if_new_day() -> void:
	if ad_coins_watched_date != today_string():
		ad_coins_watched_date = today_string()
		ad_coins_watched_today = 0

func is_objective_claimed(obj_id: String) -> bool:
	return obj_id in claimed_objectives

func claim_objective(obj_id: String) -> void:
	if obj_id not in claimed_objectives:
		claimed_objectives.append(obj_id)
		save_settings()
		economy_changed.emit()

# ---------- лидерборд ----------
const MAX_LEADERBOARD := 10

func add_leaderboard_entry(name: String, score: int, mode: String) -> void:
	leaderboard.append({"name": name, "score": score, "mode": mode})
	leaderboard.sort_custom(func(a, b): return a.score > b.score)
	if leaderboard.size() > MAX_LEADERBOARD:
		leaderboard.resize(MAX_LEADERBOARD)
	save_settings()
	leaderboard_changed.emit()

# ---------- ачивки ----------
func unlock_achievement(a_id: String) -> bool:
	if a_id in unlocked_achievements:
		return false
	unlocked_achievements.append(a_id)
	achievements_changed.emit()
	save_settings()
	Toast.show_reward(tr(" Ачивка открыта!"))
	return true

func has_achievement(a_id: String) -> bool:
	return a_id in unlocked_achievements

# ---------- статистика бесконечного режима ----------
func record_endless_run(wave: int, score: int) -> void:
	_reset_quest_day_if_needed()
	runs_today += 1
	endless_play_count += 1
	add_player_xp(wave * 10)
	# Зачёт в турнир: лучший счёт за неделю.
	Tournament.record_score(score)
	if wave > endless_best_wave:
		endless_best_wave = wave
	if score > best_score_total:
		best_score_total = score
	stats_changed.emit()
	save_settings()
	Achievements.check_all()

# ---------- ежедневные награды ----------
const DAILY_INDEX := [0, 1, 2, 3, 4, 5, 6]  # индекс дня в цикле 7 дней

## Можно ли забрать награду сегодня.
func can_claim_daily() -> bool:
	return today_string() != last_daily_claim

## Забрать ежедневную награду. Возвращает число монет или 0, если нельзя.
func claim_daily() -> int:
	if not can_claim_daily():
		return 0
	# Проверяем серию: если вчера не забирали — серия сбрасывается
	if yesterday_string() != last_daily_claim:
		daily_streak = 0
	daily_streak += 1
	# Индекс дня по календарю повторяется циклом 7 дней
	var day_idx := (daily_reward_index) % 7
	var reward: int = Economy.DAILY_REWARDS[day_idx].coins
	daily_reward_index = (daily_reward_index + 1) % 7
	last_daily_claim = today_string()
	add_coins(reward)
	daily_changed.emit()
	save_settings()
	Achievements.check_all()
	Toast.show_reward(tr("Ежедневная награда: +%d монет") % reward)
	return reward

## Донладанная сумма награды для текущего дня.
func current_daily_reward() -> int:
	var day_idx := daily_reward_index % 7
	return Economy.DAILY_REWARDS[day_idx].coins

func today_string() -> String:
	return Time.get_date_string_from_system()

func yesterday_string() -> String:
	var now := Time.get_datetime_dict_from_system()
	var t := Time.get_unix_time_from_datetime_dict(now) - 86400
	return Time.get_date_string_from_unix_time(t)

# ---------- покупки за рекламу ----------
# Возвращает true, если покупка прошла (предполагается, что выдана награда за рекламу).
func purchase_skin(index: int) -> bool:
	if is_skin_owned(index):
		return false
	if index not in owned_skins:
		owned_skins.append(index)
	save_settings()
	economy_changed.emit()
	Achievements.check_all()
	return true

func purchase_mode(mode: String) -> bool:
	if is_mode_owned(mode):
		return false
	if mode not in owned_modes:
		owned_modes.append(mode)
	save_settings()
	economy_changed.emit()
	Achievements.check_all()
	return true

# ---------- снаряжение ----------
## Куплен ли предмет.
func is_equipment_owned(eq_id: String) -> bool:
	return eq_id in owned_equipment

## Надето ли снаряжение в слот.
func equipped_in(slot: String) -> String:
	return str(equipped.get(slot, ""))

## Купить предмет снаряжения (после списания монет).
func purchase_equipment(eq_id: String) -> void:
	if eq_id not in owned_equipment:
		owned_equipment.append(eq_id)
	save_settings()
	economy_changed.emit()
	Achievements.check_all()

## Надеть предмет в его слот (заменяет старое).
func equip_item(eq_id: String) -> void:
	var it := Economy.find_equipment(eq_id)
	if it.is_empty() or not is_equipment_owned(eq_id):
		return
	equipped[it.slot] = eq_id
	save_settings()
	economy_changed.emit()

## Снять снаряжение со слота.
func unequip_slot(slot: String) -> void:
	if equipped.has(slot):
		equipped.erase(slot)
		save_settings()
		economy_changed.emit()

## Список id надетого снаряжения (для расчёта бонусов).
func equipped_ids() -> Array[String]:
	var ids: Array[String] = []
	for slot: String in Economy.EQUIPMENT:
		if equipped.has(slot) and equipped[slot] != "":
			ids.append(str(equipped[slot]))
	return ids

# ---------- система персонажа (уровни/опыт) ----------
## Добавить опыт, прокачать уровень если нужно.
func add_player_xp(amount: int) -> void:
	if amount <= 0:
		return
	player_xp += amount
	while player_level < Economy.PLAYER_MAX_LEVEL and player_xp >= Economy.player_xp_needed(player_level):
		player_xp -= Economy.player_xp_needed(player_level)
		player_level += 1
	# после максимума — не зацикливаем (лишний опыт просто копится)
	if player_level >= Economy.PLAYER_MAX_LEVEL:
		player_xp = mini(player_xp, Economy.player_xp_needed(player_level))
	stats_changed.emit()
	_schedule_save()
	Achievements.check_all()

# ---------- глифы ----------
## Куплен ли вечный глиф.
func has_glyph(glyph_id: String) -> bool:
	return glyph_id in owned_glyphs

## Погасить один забег у временного глифа.
func tick_temp_glyphs() -> void:
	for gid in temp_glyphs.keys():
		var left := int(temp_glyphs[gid]) - 1
		if left <= 0:
			temp_glyphs.erase(gid)
		else:
			temp_glyphs[gid] = left
	save_settings()
	economy_changed.emit()

## Купить глиф за монеты. Временный — активируется, вечный — навсегда.
func purchase_glyph(glyph_id: String) -> bool:
	var g := Economy.find_glyph(glyph_id)
	if g.is_empty():
		return false
	if glyph_id in owned_glyphs or temp_glyphs.get(glyph_id, 0) > 0:
		return false
	if coins < int(g.price):
		return false
	if not spend_coins(int(g.price)):
		return false
	if g.type == "E":
		owned_glyphs.append(glyph_id)
	else:
		temp_glyphs[glyph_id] = int(g.get("runs", 10))
	# Пытаемся сразу экипировать в свободный слот (если есть место).
	if not glyph_equipped(glyph_id) and equipped_glyphs.size() < glyph_slots():
		equipped_glyphs.append(glyph_id)
	save_settings()
	economy_changed.emit()
	Achievements.check_all()
	return true

## Осталось забегов у временного глифа (или 0 для вечного/нет).
func temp_glyph_runs(glyph_id: String) -> int:
	return int(temp_glyphs.get(glyph_id, 0))

# ---------- шлифовка глифов ----------
## Уровень улучшения глифа (1..5).
func glyph_level(glyph_id: String) -> int:
	return int(glyph_levels.get(glyph_id, 1))

## Можно ли улучшить глиф (куплен и не максимальный уровень).
func can_upgrade_glyph(glyph_id: String) -> bool:
	var owned: bool = (glyph_id in owned_glyphs) or (temp_glyphs.get(glyph_id, 0) > 0)
	if not owned:
		return false
	if glyph_level(glyph_id) >= Economy.GLYPH_MAX_LEVEL:
		return false
	return shards >= Economy.glyph_upgrade_cost(glyph_level(glyph_id))

## Улучшить глиф на уровень. Возвращает true при успехе.
func upgrade_glyph(glyph_id: String) -> bool:
	if not can_upgrade_glyph(glyph_id):
		return false
	var cost := Economy.glyph_upgrade_cost(glyph_level(glyph_id))
	shards -= cost
	glyph_levels[glyph_id] = glyph_level(glyph_id) + 1
	save_settings()
	economy_changed.emit()
	stats_changed.emit()
	return true

func add_shards(amount: int) -> void:
	if amount <= 0:
		return
	shards += amount
	stats_changed.emit()
	_schedule_save()

## Дневной кап осколков за дуэли.
## Daily cap for duel shards.
const DUEL_SHARDS_DAILY_CAP := 10

## Начислить осколки за дуэль с дневным капом. Возвращает выданное кол-во.
## Grant duel shards with daily cap; returns amount actually granted.
func add_duel_shards(amount: int) -> int:
	if amount <= 0:
		return 0
	if shards_day != today_string():
		shards_day = today_string()
		shards_today = 0
	var left := DUEL_SHARDS_DAILY_CAP - shards_today
	if left <= 0:
		return 0
	var granted: int = mini(amount, left)
	shards_today += granted
	add_shards(granted)
	save_settings()
	return granted

## Сколько слотов под активные глифы (прокачивается уровнем персонажа).
func glyph_slots() -> int:
	return 2 + (player_level / 10)  # 2..7 слотов

## Активен ли глиф в слоте (экипирован).
func glyph_equipped(glyph_id: String) -> bool:
	return glyph_id in equipped_glyphs

## Экипировать глиф в свободный слот. Возвращает true/false.
func equip_glyph(glyph_id: String) -> bool:
	# Проверяем владение (вечный куплен или временный активен), но НЕ glyph_active —
	# иначе получается замкнутый цикл.
	if not (glyph_id in owned_glyphs or temp_glyphs.get(glyph_id, 0) > 0):
		return false
	if glyph_equipped(glyph_id):
		return true
	if equipped_glyphs.size() >= glyph_slots():
		return false
	equipped_glyphs.append(glyph_id)
	save_settings()
	economy_changed.emit()
	return true

## Снять глиф со слота.
func unequip_glyph(glyph_id: String) -> void:
	equipped_glyphs.erase(glyph_id)
	save_settings()
	economy_changed.emit()

## Совокупная проверка: глиф даёт эффект, только если он куплен/активен И экипирован в слот.
func glyph_active(glyph_id: String) -> bool:
	if not (glyph_id in owned_glyphs or temp_glyphs.get(glyph_id, 0) > 0):
		return false
	return glyph_equipped(glyph_id)

# ---------- VIP-подписка ----------
## Приносит +5 кристаллов/день, пока активна (не чаще раза в день, как ежедневка).
func claim_vip_daily() -> bool:
	if vip_days_left <= 0:
		return false
	if last_vip_claim == today_string():
		return false
	last_vip_claim = today_string()
	vip_days_left -= 1
	add_crystals(5)
	save_settings()
	return true

## Множитель монет за рекламу (VIP = x2).
func ad_coin_reward() -> int:
	return Economy.AD_REWARD_COINS * (2 if vip_days_left > 0 else 1)

# ---------- покупки (IAP) ----------
## Обработать покупку пака (волю для раздачи наград из PurchaseService).
func grant_iap_pack(pack_id: String) -> void:
	for p in Economy.IAP_PACKS:
		if p.id == pack_id:
			if p.has("coins"):
				add_coins(int(p.coins))
			if p.has("crystals"):
				add_crystals(int(p.crystals))
			if p.has("vip_days"):
				vip_days_left = maxi(vip_days_left, 0) + int(p.vip_days)
				stats_changed.emit()
			save_settings()
			economy_changed.emit()
			return

## Найти цену пака для отображения.
func iap_price(pack_id: String) -> String:
	for p in Economy.IAP_PACKS:
		if p.id == pack_id:
			return str(p.get("price", ""))
	return ""

# ---------- турниры ----------
## Можно ли забрать турнирную награду за текущую неделю.
func can_claim_tournament() -> bool:
	var week := Tournament.current_week()
	return week != tournament_claimed_week and tournament_score > 0

## Забрать награду за участие в турнире (осколки).
func claim_tournament() -> int:
	if not can_claim_tournament():
		return 0
	var week := Tournament.current_week()
	tournament_claimed_week = week
	var shards_reward := Tournament.participation_shards()
	add_shards(shards_reward)
	save_settings()
	economy_changed.emit()
	Toast.show_reward(tr("Турнирная награда: +%d осколков") % shards_reward)
	return shards_reward

# ---------- паки кристаллов за рекламу ----------
## Прогресс по паку (сколько реклам просмотрено).
func crystal_pack_progress(pk_id: String) -> int:
	return int(crystal_pack_prog.get(pk_id, 0))

## Получен ли пак.
func crystal_pack_claimed(pk_id: String) -> bool:
	return pk_id in crystal_pack_claimed_ids

## Можно ли продолжать копить пак (не превышен общий дневной лимит рекламы за кристаллы).
func crystal_pack_progressable(pk_id: String) -> bool:
	return can_watch_crystal_ad()

## Занять прогресс пака одним просмотром рекламы; выдать награду, когда готово.
func record_crystal_pack_ad(pk_id: String) -> void:
	if not can_watch_crystal_ad():
		return
	# находим пак
	var ads_needed := 0
	var crystals := 0
	var found := false
	for pk in Economy.CRYSTAL_AD_PACKS:
		if pk.id == pk_id:
			ads_needed = int(pk.ads)
			crystals = int(pk.crystals)
			found = true
			break
	if not found or crystal_pack_claimed(pk_id):
		return
	record_crystal_ad()
	record_ad_watched()
	crystal_pack_prog[pk_id] = crystal_pack_progress(pk_id) + 1
	if crystal_pack_progress(pk_id) >= ads_needed:
		crystal_pack_claimed_ids.append(pk_id)
		add_crystals(crystals)
		AudioManager.play("level")
	save_settings()
	economy_changed.emit()

# ---------- инвентарь и бустеры ----------
## Сколько бустеров указанного типа есть в инвентаре.
func booster_count(bt_id: String) -> int:
	return int(boosters.get(bt_id, 0))

## Положить бустеры в инвентарь (покупка/награда).
func add_booster(bt_id: String, amount: int) -> void:
	boosters[bt_id] = booster_count(bt_id) + amount
	_schedule_save()
	economy_changed.emit()

## Израсходовать один бустер. Возвращает true, если был в наличии.
func consume_booster(bt_id: String) -> bool:
	if booster_count(bt_id) <= 0:
		return false
	boosters[bt_id] = booster_count(bt_id) - 1
	save_settings()
	economy_changed.emit()
	return true

## Список id бустеров, которые есть в наличии (для выбора экипировки).
func owned_boosters() -> Array[String]:
	var result: Array[String] = []
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		if booster_count(b.id) > 0:
			result.append(b.id)
	return result

# ---------- прогрессия уровня ----------
func report_level(level: int) -> void:
	if level > max_level_reached:
		max_level_reached = level
		save_settings()
		economy_changed.emit()

# ---------- ежедневные квесты ----------
## Актуальное задание на сегодня (заполняется при первом обращении).
func current_quest() -> Dictionary:
	_reset_quest_day_if_needed()
	if quest_id == "":
		quest_id = Quests.pick_for_today().id
		_schedule_save()
	return Quests.pick_for_today()

## Прогресс по текущему заданию.
func quest_progress() -> int:
	var q := current_quest()
	return int(get(q.stat))

## Задание выполнено?
func is_quest_done() -> bool:
	var q := current_quest()
	return quest_progress() >= q.target

## Можно ли забрать награду квеста.
func can_claim_quest() -> bool:
	_reset_quest_day_if_needed()
	return is_quest_done() and not quest_claimed

## Забрать награду квеста. Возвращает число монет или 0.
func claim_quest() -> int:
	if not can_claim_quest():
		return 0
	var q := current_quest()
	var reward: int = q.reward
	quest_claimed = true
	add_coins(reward)
	if q.has("booster") and q.booster != "":
		add_booster(str(q.booster), 1)
	stats_changed.emit()
	_schedule_save()
	Toast.show_reward(tr("Задание выполнено! +%d монет") % reward)
	return reward

## Сброс счётчиков «сегодня», если наступил новый день.
func _reset_quest_day_if_needed() -> void:
	if quest_date != today_string():
		quest_date = today_string()
		hits_today = 0
		catches_today = 0
		golden_today = 0
		runs_today = 0
		earned_today = 0
		quest_claimed = false
		quest_id = Quests.pick_for_today().id

# ---------- отложенное сохранение ----------
## Планирует запись на диск через SAVE_DEBOUNCE_SECONDS, чтобы не писать
## конфиг при каждом попадании/монете. Явные вызовы save_settings() остаются
## для важных моментов (покупки, заход на уровень, завершение игры).
func _schedule_save() -> void:
	if _save_timer != null:
		return
	_save_timer = get_tree().create_timer(SAVE_DEBOUNCE_SECONDS)
	_save_timer.timeout.connect(_flush_save)

func _flush_save() -> void:
	_save_timer = null
	save_settings()

## При сворачивании/закрытии приложения сбрасываем несохранённое немедленно.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _save_timer != null:
			_save_timer = null
		save_settings()

# ---------- авто-настройка под дисплей/управление ----------
func _auto_detect() -> void:
	last_screen = DisplayServer.screen_get_size()
	if DisplayServer.has_method("is_touchscreen_available"):
		is_touch = DisplayServer.is_touchscreen_available()
	if control_mode != "touch" and control_mode != "keyboard":
		control_mode = "touch" if is_touch else "keyboard"
	if auto_detect:
		save_settings()

# ---------- сохранение ----------
const SAVE_VERSION := 1

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var sv: int = int(cfg.get_value("meta", "save_v", 0))
	if sv < SAVE_VERSION:
		_migrate_save(sv)
	volume = cfg.get_value("settings", "volume", 1.0)
	music_volume = cfg.get_value("settings", "music_volume", 1.0)
	sfx_volume = cfg.get_value("settings", "sfx_volume", 1.0)
	tutorial_done = cfg.get_value("settings", "tutorial_done", false)
	locale = cfg.get_value("settings", "locale", "ru")
	control_mode = cfg.get_value("settings", "control_mode", "auto")
	auto_detect = cfg.get_value("settings", "auto_detect", true)
	is_touch = cfg.get_value("settings", "is_touch", false)
	last_screen = cfg.get_value("settings", "last_screen", Vector2i.ZERO)
	last_mode_scene = str(cfg.get_value("settings", "last_mode_scene", ""))
	btn_side = str(cfg.get_value("settings", "btn_side", "right"))
	campaign_intro_seen = bool(cfg.get_value("settings", "campaign_intro_seen", false))
	joy_scale = cfg.get_value("settings", "joy_scale", 1.0)
	auto_aim = cfg.get_value("settings", "auto_aim", true)
	avatar = cfg.get_value("settings", "avatar", 0)
	shake_enabled = cfg.get_value("settings", "shake_enabled", true)
	particles_enabled = cfg.get_value("settings", "particles_enabled", true)
	landscape_mode = cfg.get_value("settings", "landscape_mode", false)
	high_score = cfg.get_value("settings", "high_score", 0)
	difficulty = cfg.get_value("settings", "difficulty", "normal")
	selected_skin = cfg.get_value("settings", "selected_skin", 0)
	selected_modes = cfg.get_value("settings", "selected_modes", [])
	boosters = cfg.get_value("settings", "boosters", {"heart": 0, "shield": 0, "magnet": 0, "talisman": 0})
	armed_booster = cfg.get_value("settings", "armed_booster", "")
	owned_equipment = cfg.get_value("settings", "owned_equipment", [])
	equipped = cfg.get_value("settings", "equipped", {})
	player_xp = cfg.get_value("settings", "player_xp", 0)
	player_level = cfg.get_value("settings", "player_level", 1)
	owned_glyphs = cfg.get_value("settings", "owned_glyphs", [])
	temp_glyphs = cfg.get_value("settings", "temp_glyphs", {})
	equipped_glyphs = cfg.get_value("settings", "equipped_glyphs", [])
	shards = cfg.get_value("settings", "shards", 0)
	tournament_score = cfg.get_value("settings", "tournament_score", 0)
	tournament_claimed_week = cfg.get_value("settings", "tournament_claimed_week", -1)
	glyph_levels = cfg.get_value("settings", "glyph_levels", {})
	vip_days_left = cfg.get_value("settings", "vip_days_left", 0)
	last_vip_claim = cfg.get_value("settings", "last_vip_claim", "")
	max_level_reached = cfg.get_value("settings", "max_level_reached", 1)
	owned_skins = cfg.get_value("settings", "owned_skins", [0])
	owned_avatars = cfg.get_value("settings", "owned_avatars", [0])
	relics_total = cfg.get_value("settings", "relics_total", 0)
	arena_tutorial_done = cfg.get_value("settings", "arena_tutorial_done", false)
	music_track = cfg.get_value("settings", "music_track", -1)
	style_pack = str(cfg.get_value("settings", "style_pack", "base"))
	var sl: Variant = cfg.get_value("settings", "seen_lore", {})
	if sl is Dictionary:
		seen_lore = sl
	is_supporter = bool(cfg.get_value("settings", "supporter", false))
	fortune_day = str(cfg.get_value("settings", "fortune_day", ""))
	login_streak = int(cfg.get_value("settings", "login_streak", 0))
	last_login_unix = int(cfg.get_value("settings", "last_login_unix", 0))
	arena_drops = cfg.get_value("settings", "arena_drops", true)
	survival_mode = cfg.get_value("settings", "survival_mode", false)
	extra_knives = cfg.get_value("settings", "extra_knives", 0)
	arena_ach = cfg.get_value("settings", "arena_ach", [])
	owned_modes = cfg.get_value("settings", "owned_modes", [])
	if 0 not in owned_skins:
		owned_skins.append(0)
	coins = cfg.get_value("settings", "coins", 0)
	crystals = cfg.get_value("settings", "crystals", 0)
	consumables = cfg.get_value("settings", "consumables", {"gold_knife": 0})
	total_hits = cfg.get_value("settings", "total_hits", 0)
	total_catches = cfg.get_value("settings", "total_catches", 0)
	total_levels = cfg.get_value("settings", "total_levels", 0)
	total_ads_watched = cfg.get_value("settings", "total_ads_watched", 0)
	total_duel_wins = cfg.get_value("settings", "total_duel_wins", 0)
	ad_coins_watched_today = cfg.get_value("settings", "ad_coins_watched_today", 0)
	ad_coins_watched_date = cfg.get_value("settings", "ad_coins_watched_date", "")
	shards_today = cfg.get_value("settings", "shards_today", 0)
	shards_day = cfg.get_value("settings", "shards_day", "")
	crystal_ads_today = cfg.get_value("settings", "crystal_ads_today", 0)
	crystal_ads_date = cfg.get_value("settings", "crystal_ads_date", "")
	crystal_pack_prog = cfg.get_value("settings", "crystal_pack_progress", {})
	crystal_pack_claimed_ids = cfg.get_value("settings", "crystal_pack_claimed", [])
	claimed_objectives = cfg.get_value("settings", "claimed_objectives", [])
	last_daily_claim = cfg.get_value("settings", "last_daily_claim", "")
	daily_streak = cfg.get_value("settings", "daily_streak", 0)
	daily_reward_index = cfg.get_value("settings", "daily_reward_index", 0)
	quest_date = cfg.get_value("settings", "quest_date", "")
	quest_id = cfg.get_value("settings", "quest_id", "")
	quest_claimed = cfg.get_value("settings", "quest_claimed", false)
	hits_today = cfg.get_value("settings", "hits_today", 0)
	catches_today = cfg.get_value("settings", "catches_today", 0)
	golden_today = cfg.get_value("settings", "golden_today", 0)
	runs_today = cfg.get_value("settings", "runs_today", 0)
	earned_today = cfg.get_value("settings", "earned_today", 0)
	unlocked_achievements = cfg.get_value("settings", "unlocked_achievements", [])
	endless_best_wave = cfg.get_value("settings", "endless_best_wave", 0)
	endless_play_count = cfg.get_value("settings", "endless_play_count", 0)
	best_score_total = cfg.get_value("settings", "best_score_total", 0)
	leaderboard = cfg.get_value("settings", "leaderboard", [])
	player_name = cfg.get_value("settings", "player_name", tr("Игрок"))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	_fill_cfg(cfg)
	cfg.set_value("meta", "save_v", SAVE_VERSION)
	cfg.save(SAVE_PATH)
	settings_changed.emit()

## Выгружает текущее состояние в текст (для облачного сейва Yandex playerData).
func dump_settings_text() -> String:
	var cfg := ConfigFile.new()
	_fill_cfg(cfg)
	return cfg.to_text()

## Облачная загрузка: переносит ключи, которых нет локально (локальные — приоритет).
func merge_from_text(text: String) -> void:
	if text.is_empty():
		return
	# Не перезаписываем локальные несохранённые изменения (идёт дебаунс-таймер).
	if _save_timer != null:
		return
	var cloud := ConfigFile.new()
	if cloud.parse(text) != OK:
		return
	var current := ConfigFile.new()
	current.load(SAVE_PATH)
	var merged := false
	if cloud.has_section("settings"):
		for key in cloud.get_section_keys("settings"):
			if not current.has_section_key("settings", key):
				current.set_value("settings", key, cloud.get_value("settings", key))
				merged = true
	if merged:
		current.save(SAVE_PATH)
		load_settings()

func _fill_cfg(cfg: ConfigFile) -> void:
	cfg.set_value("settings", "volume", volume)
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "tutorial_done", tutorial_done)
	cfg.set_value("settings", "locale", locale)
	cfg.set_value("settings", "control_mode", control_mode)
	cfg.set_value("settings", "auto_detect", auto_detect)
	cfg.set_value("settings", "is_touch", is_touch)
	cfg.set_value("settings", "last_screen", last_screen)
	cfg.set_value("settings", "joy_scale", joy_scale)
	cfg.set_value("settings", "auto_aim", auto_aim)
	cfg.set_value("settings", "avatar", avatar)
	cfg.set_value("settings", "shake_enabled", shake_enabled)
	cfg.set_value("settings", "particles_enabled", particles_enabled)
	cfg.set_value("settings", "landscape_mode", landscape_mode)
	cfg.set_value("settings", "high_score", high_score)
	cfg.set_value("settings", "difficulty", difficulty)
	cfg.set_value("settings", "selected_skin", selected_skin)
	cfg.set_value("settings", "last_mode_scene", last_mode_scene)
	cfg.set_value("settings", "btn_side", btn_side)
	cfg.set_value("settings", "campaign_intro_seen", campaign_intro_seen)
	cfg.set_value("settings", "selected_modes", selected_modes)
	cfg.set_value("settings", "boosters", boosters)
	cfg.set_value("settings", "armed_booster", armed_booster)
	cfg.set_value("settings", "owned_equipment", owned_equipment)
	cfg.set_value("settings", "equipped", equipped)
	cfg.set_value("settings", "player_xp", player_xp)
	cfg.set_value("settings", "player_level", player_level)
	cfg.set_value("settings", "owned_glyphs", owned_glyphs)
	cfg.set_value("settings", "temp_glyphs", temp_glyphs)
	cfg.set_value("settings", "equipped_glyphs", equipped_glyphs)
	cfg.set_value("settings", "shards", shards)
	cfg.set_value("settings", "tournament_score", tournament_score)
	cfg.set_value("settings", "tournament_claimed_week", tournament_claimed_week)
	cfg.set_value("settings", "glyph_levels", glyph_levels)
	cfg.set_value("settings", "vip_days_left", vip_days_left)
	cfg.set_value("settings", "last_vip_claim", last_vip_claim)
	cfg.set_value("settings", "max_level_reached", max_level_reached)
	cfg.set_value("settings", "owned_skins", owned_skins)
	cfg.set_value("settings", "owned_avatars", owned_avatars)
	cfg.set_value("settings", "relics_total", relics_total)
	cfg.set_value("settings", "arena_tutorial_done", arena_tutorial_done)
	cfg.set_value("settings", "music_track", music_track)
	cfg.set_value("settings", "style_pack", style_pack)
	cfg.set_value("settings", "seen_lore", seen_lore)
	cfg.set_value("settings", "supporter", is_supporter)
	cfg.set_value("settings", "fortune_day", fortune_day)
	cfg.set_value("settings", "login_streak", login_streak)
	cfg.set_value("settings", "last_login_unix", last_login_unix)
	cfg.set_value("settings", "arena_drops", arena_drops)
	cfg.set_value("settings", "survival_mode", survival_mode)
	cfg.set_value("settings", "extra_knives", extra_knives)
	cfg.set_value("settings", "arena_ach", arena_ach)
	cfg.set_value("settings", "owned_modes", owned_modes)
	cfg.set_value("settings", "coins", coins)
	cfg.set_value("settings", "crystals", crystals)
	cfg.set_value("settings", "consumables", consumables)
	cfg.set_value("settings", "total_hits", total_hits)
	cfg.set_value("settings", "total_catches", total_catches)
	cfg.set_value("settings", "total_levels", total_levels)
	cfg.set_value("settings", "total_ads_watched", total_ads_watched)
	cfg.set_value("settings", "total_duel_wins", total_duel_wins)
	cfg.set_value("settings", "ad_coins_watched_today", ad_coins_watched_today)
	cfg.set_value("settings", "ad_coins_watched_date", ad_coins_watched_date)
	cfg.set_value("settings", "shards_today", shards_today)
	cfg.set_value("settings", "shards_day", shards_day)
	cfg.set_value("settings", "crystal_ads_today", crystal_ads_today)
	cfg.set_value("settings", "crystal_ads_date", crystal_ads_date)
	cfg.set_value("settings", "crystal_pack_progress", crystal_pack_prog)
	cfg.set_value("settings", "crystal_pack_claimed", crystal_pack_claimed_ids)
	cfg.set_value("settings", "claimed_objectives", claimed_objectives)
	cfg.set_value("settings", "last_daily_claim", last_daily_claim)
	cfg.set_value("settings", "daily_streak", daily_streak)
	cfg.set_value("settings", "daily_reward_index", daily_reward_index)
	cfg.set_value("settings", "quest_date", quest_date)
	cfg.set_value("settings", "quest_id", quest_id)
	cfg.set_value("settings", "quest_claimed", quest_claimed)
	cfg.set_value("settings", "hits_today", hits_today)
	cfg.set_value("settings", "catches_today", catches_today)
	cfg.set_value("settings", "golden_today", golden_today)
	cfg.set_value("settings", "runs_today", runs_today)
	cfg.set_value("settings", "earned_today", earned_today)
	cfg.set_value("settings", "unlocked_achievements", unlocked_achievements)
	cfg.set_value("settings", "endless_best_wave", endless_best_wave)
	cfg.set_value("settings", "endless_play_count", endless_play_count)
	cfg.set_value("settings", "best_score_total", best_score_total)
	cfg.set_value("settings", "leaderboard", leaderboard)
	cfg.set_value("settings", "player_name", player_name)

func is_avatar_owned(index: int) -> bool:
	return index in owned_avatars

func avatar_price(index: int) -> int:
	return 200 + index * 40

func buy_avatar(index: int) -> bool:
	var pr := avatar_price(index)
	if is_avatar_owned(index) or coins < pr:
		return false
	coins -= pr
	owned_avatars.append(index)
	save_settings()
	economy_changed.emit()
	return true

func unlock_arena_ach(id: String) -> bool:
	if id in arena_ach:
		return false
	arena_ach.append(id)
	save_settings()
	return true

func skin_set_price(indices: Array) -> int:
	var total := 0
	for i in indices:
		if not is_skin_owned(int(i)):
			total += Economy.skin_price(int(i))
	return int(float(total) * 0.8)

func buy_skin_set(indices: Array) -> bool:
	var pr := skin_set_price(indices)
	if pr <= 0 or coins < pr:
		return false
	coins -= pr
	for i in indices:
		if not is_skin_owned(int(i)):
			owned_skins.append(int(i))
	save_settings()
	economy_changed.emit()
	return true


func mark_supporter() -> void:
	if is_supporter:
		return
	is_supporter = true
	save_settings()


func fortune_available() -> bool:
	var d := Time.get_date_string_from_system()
	return fortune_day != d


func claim_fortune() -> Dictionary:
	if not fortune_available():
		return {}
	fortune_day = Time.get_date_string_from_system()
	save_settings()
	var roll := randi() % 4
	if roll == 0:
		add_coins(60)
		return {"kind": "coins", "amount": 60, "label": "+60 монет"}
	if roll == 1:
		add_coins(30)
		return {"kind": "coins", "amount": 30, "label": "+30 монет"}
	if roll == 2:
		add_player_xp(50)
		return {"kind": "xp", "amount": 50, "label": "+50 опыта"}
	return {"kind": "booster", "label": "Одноразовый буст"}


func _migrate_save(from_v: int) -> void:
	# Каркас миграций: сюда добавляются шаги при изменении формата сохранений.
	if from_v == 0:
		pass
	Telemetry.event("save_migrated", {"from": from_v, "to": SAVE_VERSION})


func record_login() -> void:
	var now := int(Time.get_unix_time_from_system())
	var today := now / 86400
	var last := last_login_unix / 86400
	if today == last:
		return
	if today == last + 1:
		login_streak += 1
	else:
		login_streak = 1
	last_login_unix = now
	save_settings()
	Telemetry.event("login", {"streak": login_streak})


func buy_class(index: int, price: int) -> bool:
	if index in owned_avatars:
		return false
	if not spend_crystals(price):
		return false
	owned_avatars.append(index)
	avatar = index
	save_settings()
	economy_changed.emit()
	return true


func chapter_index() -> int:
	var idx := 0
	for i in CHAPTERS.size():
		if max_level_reached >= int(CHAPTERS[i]["unlock"]):
			idx = i
	return idx


func chapter_name() -> String:
	return str(CHAPTERS[chapter_index()]["n"])


func chapter_next_unlock() -> int:
	var i := chapter_index()
	if i + 1 < CHAPTERS.size():
		return int(CHAPTERS[i + 1]["unlock"])
	return 0


func class_bonus(key: String) -> float:
	var b: Dictionary = CLASS_BONUS.get(GameState.avatar, {})
	return float(b.get(key, 1.0))
