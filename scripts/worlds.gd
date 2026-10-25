class_name Worlds
extends RefCounted

## Слой «лор + миры» (см. LORE-WORLDS.md). Данные 8 миров + хелперы.
## Мир открывается по GameState.max_level_reached. Аркаду не трогает.

const LIST := [
	{"id": "forest", "name": "Лесная Опушка", "unlock": 1, "skin": 0, "art": "world_forest",
		"lore": "Опушка учит главному: бросил — жди возвращения. Нож вернётся в ладонь, даже если ты уже забыл, зачем его отпускал."},
	{"id": "neon", "name": "Неоновый Тракт", "unlock": 3, "skin": 1, "art": "world_neon",
		"lore": "Тракт светится только там, где нож уже прошёл, — дорога пишется твоим броском. Сбей ритм ловли, и огни погаснут за спиной."},
	{"id": "ice", "name": "Ледяное Ущелье", "unlock": 5, "skin": 2, "art": "world_ice",
		"lore": "Мороз здесь тормозит всё, кроме лезвия. Лови нож на возврате — это единственное тепло, которое ущелье признаёт."},
	{"id": "ruby", "name": "Рубиновая Кузня", "unlock": 8, "skin": 3, "art": "world_ruby",
		"lore": "Кузня принимает только тех, кто бросает без паузы: горн гаснет на вдохе. Каждый пойманный нож подкидывает уголёк, каждый промах — гасит."},
	{"id": "shadow", "name": "Тенистая Чаща", "unlock": 12, "skin": 4, "art": "world_shadow",
		"lore": "Чаща повторяет имена тех, кто бросил и не дождался возврата. Слушай свист лезвия, а не шёпот: свист не врёт."},
	{"id": "elektro", "name": "Грозовой Пик", "unlock": 16, "skin": 5, "art": "world_elektro",
		"lore": "Пик бьёт в самое высокое, а нож на возврате всегда выше тебя. Подставь ладонь под разряд — или гром заберёт бросок."},
	{"id": "toxic", "name": "Токсичные Топи", "unlock": 20, "skin": 6, "art": "world_toxic",
		"lore": "Топь уговаривает: отпусти нож, он всё равно вернётся. Врёт — тянет лезвие вниз ровно до тех пор, пока ты слушаешь."},
	{"id": "cosmos", "name": "Космический Предел", "unlock": 25, "skin": 7, "art": "world_cosmos",
		"lore": "На Пределе нет верха и низа — есть траектория и рука, которая её держит. Брось последний нож в Рассвет и поймай его уже дома."},
]


## Индекс самого дальнего открытого мира (0, если ничего не открыто сверх старта).
static func current_index()-> int:
	var idx := 0
	for i in range(LIST.size()):
		if GameState.max_level_reached >= int(LIST[i]["unlock"]):
			idx = i
	return idx


static func is_unlocked(i: int) -> bool:
	return i >= 0 and i < LIST.size() and GameState.max_level_reached >= int(LIST[i]["unlock"])


## Индекс следующего (ещё закрытого) мира, или -1 если все открыты.
static func next_index()-> int:
	var cur := current_index()
	if cur + 1 < LIST.size():
		return cur + 1
	return -1


## Сколько уровней осталось до мира i (>=0).
static func levels_to(i: int) -> int:
	if i < 0 or i >= LIST.size():
		return 0
	return maxi(int(LIST[i]["unlock"]) - GameState.max_level_reached, 0)


## Мир, чья вставка-лор ещё не показана (новейший разблокированный), или -1.
static func pending_lore()-> int:
	var best := -1
	for i in range(LIST.size()):
		var id := str(LIST[i]["id"])
		if is_unlocked(i) and not GameState.seen_lore.has(id):
			best = i
	return best


static func mark_seen(i: int) -> void:
	if i < 0 or i >= LIST.size():
		return
	GameState.seen_lore[str(LIST[i]["id"])] = true
	GameState.save_settings()
