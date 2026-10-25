extends RefCounted
class_name Economy

## Центральный модуль экономики.
##
## Все балансовые константы собраны здесь — награды за геймплей,
## цены в магазине и лимиты. Значения подбирались так, чтобы:
##   - первый скин/мод был доступен примерно за 2-3 короткие сессии;
##   - реклама была бонусом, а не фермой (дневной лимит);
##   - длинная игра ощущалась щедрой (ежедневки, цели, ачивки).

# ---- награды за геймплей (монеты) ----
const COINS_PER_LEVEL := 6       # за прохождение уровня (классика)
const COINS_PER_REVIVE := 8      # бонус за просмотр рекламы-возрождения
const GOLDEN_COIN := 10          # за забитый золотой сектор
const ENDLESS_WAVE_BASE := 4     # база бонуса за волну в бесконечном режиме
const ENDLESS_WAVE_STEP := 2     # шаг бонуса за волну (за волну n: base + n*step)
const DUEL_WIN_REWARD := 20      # монеты победителю дуэли

# ---- реклама (монеты и кристаллы) ----
const AD_REWARD_COINS := 40      # за rewarded-рекламу в магазине
const AD_DAILY_CAP := 5          # максимум rewarded-реклам с монетами в сутки
const CRYSTALS_PER_AD := 2       # кристаллы за rewarded-рекламу
const CRYSTAL_AD_DAILY_CAP := 3  # максимум реклам за кристаллы в сутки

# ---- цены в магазине ----
# Скин i: база + шаг*i. Скин 0 (Золото) бесплатный по уровню.
const SKIN_PRICE_BASE := 100
const SKIN_PRICE_STEP := 60
# Мод: база + шаг*индекс в словаре MODES.
const MODE_PRICE_BASE := 120
const MODE_PRICE_STEP := 50

# ---- множители наград от сложности ----
# На лёгкой сложности монет меньше, на сложной — больше (бонус за риск).
const REWARD_MULT := {
	"easy":   0.75,
	"normal": 1.0,
	"hard":   1.5,
}

## Цена скина.
static func skin_price(index: int) -> int:
	return SKIN_PRICE_BASE + index * SKIN_PRICE_STEP

## Цена мода по ключу.
static func mode_price(mode_key: String) -> int:
	var idx := GameState.MODES.keys().find(mode_key)
	if idx < 0:
		idx = 0
	return MODE_PRICE_BASE + idx * MODE_PRICE_STEP

## Множитель наград по текущей сложности.
static func reward_mult() -> float:
	return REWARD_MULT.get(GameState.difficulty, 1.0)

## Сколько монет за прохождение уровня с учётом сложности.
static func level_reward() -> int:
	return int(COINS_PER_LEVEL * reward_mult())

## Бонус монет за волну в бесконечном режиме.
static func endless_wave_reward(wave_number: int) -> int:
	var base := ENDLESS_WAVE_BASE + wave_number * ENDLESS_WAVE_STEP
	return int(base * reward_mult())

# ---- предметы-бустеры (инвентарь): покупаются в магазине, расходуются за забег ----
const BOOSTER_ITEMS := [
	{"id": "heart",    "label": "Сердце",   "desc": "+1 жизнь в начале забега",            "price": 60},
	{"id": "shield",   "label": "Щит",      "desc": "Поглощает первый промах",            "price": 90},
	{"id": "magnet",   "label": "Магнит",   "desc": "Золотые секторы дают x2 монет",      "price": 120},
	{"id": "talisman", "label": "Талисман", "desc": "+50% очков за забег",                "price": 150},
]

# ---- расходники (предметы) ----
const CONSUMABLE_ITEMS := [
	{"id": "gold_knife", "label": "Золотой нож",
	 "desc": "Каждый удар засчитывает 2 сегмента (на один забег)",
	 "price_crystals": 10},
]

# ---- снаряжение (слоты экипировки) ----
# Каждый предмет даёт бонус:
#   lives     +N жизней
#   speed     множитель скорости ножа
#   score     множитель очков
#   magnet    золотые монеты x2 (stack с бустером-магнитом)
#   shield    блок первого промаха (как бустер, но пассивно каждый забег)
const EQUIPMENT := {
	"shield": [
		{"id": "shield_01", "label": "Щит 1", "desc": "+1 щит", "slot": "shield", "price": 150, "shield": 1},
		{"id": "shield_02", "label": "Щит 2", "desc": "+1 щит", "slot": "shield", "price": 190, "shield": 1},
		{"id": "shield_03", "label": "Щит 3", "desc": "+1 щит", "slot": "shield", "price": 230, "shield": 1},
		{"id": "shield_04", "label": "Щит 4", "desc": "+1 щит", "slot": "shield", "price": 270, "shield": 1},
		{"id": "shield_05", "label": "Щит 5", "desc": "+2 щит", "slot": "shield", "price": 310, "shield": 2},
		{"id": "shield_06", "label": "Щит 6", "desc": "+2 щит", "slot": "shield", "price": 350, "shield": 2},
		{"id": "shield_07", "label": "Щит 7", "desc": "+2 щит", "slot": "shield", "price": 390, "shield": 2},
		{"id": "shield_08", "label": "Щит 8", "desc": "+2 щит", "slot": "shield", "price": 430, "shield": 2},
		{"id": "shield_09", "label": "Щит 9", "desc": "+3 щит", "slot": "shield", "price": 470, "shield": 3},
		{"id": "shield_10", "label": "Щит 10", "desc": "+3 щит", "slot": "shield", "price": 510, "shield": 3},
		{"id": "shield_11", "label": "Щит 11", "desc": "+3 щит", "slot": "shield", "price": 550, "shield": 3},
		{"id": "shield_12", "label": "Щит 12", "desc": "+3 щит", "slot": "shield", "price": 590, "shield": 3},
	],
	"helmet": [
		{"id": "head_basic", "label": "Кожаный шлем",    "desc": "+1 жизнь",         "slot": "helmet", "price": 120, "lives": 1},
		{"id": "head_iron",  "label": "Железный шлем",   "desc": "+2 жизни",         "slot": "helmet", "price": 260, "lives": 2},
	],
	"armor": [
		{"id": "armor_torn", "label": "Изношенный доспех", "desc": "+1 жизнь",       "slot": "armor",  "price": 140, "lives": 1},
		{"id": "armor_plate","label": "Латы",            "desc": "+2 жизни",          "slot": "armor",  "price": 300, "lives": 2},
	],
	"boots": [
		{"id": "boots_fast", "label": "Лёгкие ботинки",  "desc": "Скорость ножа x1.1", "slot": "boots", "price": 130, "speed": 1.1},
		{"id": "boots_wing", "label": "Крылатые ботинки","desc": "Скорость ножа x1.2", "slot": "boots", "price": 280, "speed": 1.2},
	],
	"weapon": [
		{"id": "weap_lucky", "label": "Счастливый нож",  "desc": "Золотые монеты x2",  "slot": "weapon", "price": 200, "magnet": true},
		{"id": "weap_sharp", "label": "Острый клинок",   "desc": "+20% очков",         "slot": "weapon", "price": 320, "score": 1.2},
	],
	"ring": [
		{"id": "ring_ward",  "label": "Щит-кольцо",      "desc": "Блок первого промаха", "slot": "ring",  "price": 240, "shield": true},
	]
}

## Все предметы снаряжения плоским списком.
static func all_equipment() -> Array:
	var out: Array = []
	for slot: String in EQUIPMENT:
		for it in EQUIPMENT[slot]:
			out.append(it)
	return out

## Найти предмет по id.
static func find_equipment(eq_id: String) -> Dictionary:
	for it in all_equipment():
		if it.id == eq_id:
			return it
	return {}

## Расчёт суммарных бонусов от надетого снаряжения.
static func totals(eq_ids: Array) -> Dictionary:
	var t := {"lives": 0, "speed": 1.0, "score": 1.0, "magnet": false, "shield": false}
	for id in eq_ids:
		var it := find_equipment(id)
		if it.is_empty():
			continue
		t.lives += int(it.get("lives", 0))
		t.speed *= float(it.get("speed", 1.0))
		t.score *= float(it.get("score", 1.0))
		if bool(it.get("magnet", false)):
			t.magnet = true
		if bool(it.get("shield", false)):
			t.shield = true
	return t

# ---- осколки глифов (валюта шлифовки) ----
# Осколки даются за еженедельные турниры и дуэли. Тратятся на улучшение глифов.
const SHARDS_PER_DUEL_WIN := 2     # осколки за победу в дуэли
const SHARDS_PER_TOURNAMENT := 20  # осколки за участие в недельном турнире

# Максимальный уровень улучшения глифа (улучшение лишний раз не требуется).
const GLYPH_MAX_LEVEL := 5
# Стоимость улучшения глифа на уровень: shards * level (12 стоит 5 и т.д.)
static func glyph_upgrade_cost(current_level: int) -> int:
	return 5 * current_level

## Насколько усилить эффект глифа от его уровня улучшения (1..5).
## 1.0 на 1-м уровне, +0.3 за каждый следующий (1.0, 1.3, 1.6, 1.9, 2.2).
static func glyph_power(level: int) -> float:
	return 1.0 + (clamp(level, 1, GLYPH_MAX_LEVEL) - 1) * 0.3

# ---- паки кристаллов за рекламу (альтернатива IAP в РФ) ----
# Можно «выбить» кристаллы за rewarded-рекламу вместо реальной оплаты.
const CRYSTAL_AD_PACKS := [
	{"id": "ad_cry_1",   "label": "Капля кристаллов", "crystals": 15, "ads": 1},
	{"id": "ad_cry_2",   "label": "Капсула кристаллов", "crystals": 45, "ads": 3},
	{"id": "ad_cry_3",   "label": "Гейзер кристаллов", "crystals": 150, "ads": 8},
]

# ---- покупки (IAP) ----
# В демо-режиме покупки «проходят» мгновенно (играбельно без платёжного SDK).
# При подключении магазина (RuStore/Google Play/VK Play) повесь реальный
# биллинг на функции GameState.purchase_iap().
const DONATIONS_ONLY := true
const DONATIONS := [
	{"label": "Boosty", "url": "https://boosty.to/imperiya-zws", "desc": "Подписка и разовые донаты"},
	{"label": "DonationAlerts", "url": "https://www.donationalerts.com/r/imperiya_zws", "desc": "Разовый донат"},
	{"label": "Telegram", "url": "https://t.me/imperiya_zws", "desc": "Сборы и новости"},
]
const IAP_PACKS := [
	{"id": "starter",   "label": "Стартовый набор",  "desc": "500 монет + 10 кристаллов",
	 "coins": 500, "crystals": 10, "price": "49руб."},
	{"id": "crystals_s", "label": "Мешок кристаллов", "desc": "60 кристаллов",
	 "crystals": 60, "price": "99руб."},
	{"id": "crystals_l", "label": "Сундук кристаллов", "desc": "200 кристаллов",
	 "crystals": 200, "price": "199руб."},
	{"id": "vip_month", "label": "VIP-подписка (30 дн.)", "desc": "+5 кристаллов в день, х2 монет за рекламу",
	 "vip_days": 30, "price": "149руб./мес"},
]

# ---- система персонажа (уровни) ----
# Опыт: +1 за попадание, +5 за уровень, +2 за возврат ножа, +10 за волну эндлесса,
# +15 за победу в дуэли. XP_NEXT_FORMULA(level) = 100 + (level - 1) * 50.
## Сколько опыта нужно для перехода на следующий уровень.
static func player_xp_needed(level: int) -> int:
	return 100 + (level - 1) * 50

## Премиум-статы от уровня персонажа (1..): +0.5% очков за уровень сверх базы.
static func player_score_bonus(level: int) -> float:
	return 1.0 + (level - 1) * 0.005

## Максимальный уровень персонажа (после — опыт просто копится).
const PLAYER_MAX_LEVEL := 50

# ---- глифы: временные (T) и вечные (E) ----
# T — активируется на N забегов, затем исчезает (можно купить снова).
# E — покупается один раз и работает всегда.
# Эффекты складываются с бустерами/снаряжением.
const GLYPHS := [
	{"id": "glyph_crit_t",   "label": "Глиф критического удара",   "type": "T", "runs": 10, "price": 180,  "desc": "+50% очков за попадание (10 забегов)"},
	{"id": "glyph_speed_t",  "label": "Глиф скорости",            "type": "T", "runs": 10, "price": 150,  "desc": "Скорость ножа x1.2 (10 забегов)"},
	{"id": "glyph_magnet_e", "label": "Вечный глиф магнита",       "type": "E", "price": 900,  "desc": "Золотые секторы всегда дают x2"},
	{"id": "glyph_luck_e",   "label": "Вечный глиф удачи",         "type": "E", "price": 1200, "desc": "+50% монет за золотые секторы"},
	{"id": "glyph_vital_e",  "label": "Вечный глиф жизни",         "type": "E", "price": 750,  "desc": "+1 жизнь на старте каждого забега"},
]

## Найти глиф по id.
static func find_glyph(glyph_id: String) -> Dictionary:
	for g in GLYPHS:
		if g.id == glyph_id:
			return g
	return {}

# ---- ежедневные награды (календарь на 7 дней) ----
const DAILY_REWARDS := [
	{"day": 1,  "coins": 15},
	{"day": 2,  "coins": 18},
	{"day": 3,  "coins": 22},
	{"day": 4,  "coins": 28},
	{"day": 5,  "coins": 35},
	{"day": 6,  "coins": 50},
	{"day": 7,  "coins": 80},   # большой бонус за неделю
]
