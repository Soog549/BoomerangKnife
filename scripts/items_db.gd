extends Node
class_name ItemsDB
## База предметов снаряжения: качество, уровень, характеристики.
## 6 слотов × 23 предмета, названия по сетам и качеству.

const SLOTS := ["helmet", "armor", "boots", "weapon", "ring", "shield"]

const SLOT_NAMES := {
	"helmet": ["шлем", "Шлем"],
	"armor": ["доспех", "Доспех"],
	"boots": ["сапоги", "Сапоги"],
	"weapon": ["клинок", "Клинок"],
	"ring": ["кольцо", "Кольцо"],
	"shield": ["щит", "Щит"],
}

# качество: название, цвет, множитель статов, множитель цены
const QUALITY := [
	{"name": "Обычный", "col": Color(0.75, 0.78, 0.84), "mult": 1.0, "price": 1.0},
	{"name": "Необычный", "col": Color(0.45, 0.85, 0.45), "mult": 1.35, "price": 1.8},
	{"name": "Редкий", "col": Color(0.40, 0.65, 1.00), "mult": 1.8, "price": 3.2},
	{"name": "Эпический", "col": Color(0.75, 0.45, 1.00), "mult": 2.4, "price": 5.5},
	{"name": "Легендарный", "col": Color(1.00, 0.80, 0.30), "mult": 3.2, "price": 9.0},
]

# наборы-сеты (по 2-3 предмета каждого качества в слоте)
const SETS := ["стража", "легиона", "степи", "бездны", "империи"]

const BASE_STATS := {
	"helmet": {"hp": 8.0, "def": 2.0},
	"armor": {"hp": 14.0, "def": 4.0, "speed": -0.01},
	"boots": {"speed": 0.03, "dodge": 0.02},
	"weapon": {"dmg": 2.0, "throw": 0.03},
	"ring": {"crit": 0.02, "luck": 0.02},
	"shield": {"block": 4.0, "hp": 6.0},
}

const BASE_PRICE := {
	"helmet": 120.0, "armor": 200.0, "boots": 150.0,
	"weapon": 250.0, "ring": 180.0, "shield": 220.0,
}

const STAT_LABELS := {
	"hp": "HP", "def": "защита", "dmg": "урон", "speed": "скорость",
	"dodge": "уклонение", "crit": "крит", "luck": "удача",
	"block": "блок", "throw": "бросок",
}


static func _fmt(key: String, value: float) -> String:
	var label: String = STAT_LABELS.get(key, key)
	if key in ["speed", "dodge", "crit", "luck", "throw"]:
		return "%s +%d%%" % [label, int(round(value * 100.0))]
	return "%s +%d" % [label, int(round(value))]


static func build_slot(slot: String) -> Array:
	var out: Array = []
	var base_price: float = float(BASE_PRICE.get(slot, 150.0))
	var stats: Dictionary = BASE_STATS.get(slot, {})
	var nouns: Array = SLOT_NAMES.get(slot, ["предмет", "Предмет"])
	var i := 0
	for qi in QUALITY.size():
		var q: Dictionary = QUALITY[qi]
		for s in 2:
			if out.size() >= 23:
				break
			var setname: String = SETS[(qi + s) % SETS.size()]
			var scaled := {}
			var parts: Array = []
			for k in stats.keys():
				var v: float = float(stats[k]) * float(q["mult"]) * (1.0 + 0.06 * float(i))
				scaled[k] = v
				parts.append(_fmt(str(k), v))
			out.append({
				"id": "%s_q%d_%d" % [slot, qi + 1, s + 1],
				"slot": slot,
				"name": "%s %s" % [nouns[1], setname],
				"quality": qi,
				"quality_name": str(q["name"]),
				"set": setname,
				"color": q["col"],
				"req_level": 1 + qi * 4 + s * 2,
				"stats": scaled,
				"stats_text": ", ".join(parts),
				"price": int(round(base_price * float(q["price"]) * (1.0 + 0.05 * float(i)))),
				"desc": "Снаряжение сета «%s»." % setname,
			})
			i += 1
	# добить до 23 «комплектными» вариантами
	while out.size() < 23:
		var q2: Dictionary = QUALITY[mini(out.size() % QUALITY.size(), QUALITY.size() - 1)]
		var sn: String = SETS[out.size() % SETS.size()]
		var sc := {}
		var p2: Array = []
		for k in stats.keys():
			var v2: float = float(stats[k]) * float(q2["mult"])
			sc[k] = v2
			p2.append(_fmt(str(k), v2))
		out.append({
			"id": "%s_x%d" % [slot, out.size() + 1],
			"slot": slot,
			"name": "%s %s" % [nouns[1], sn],
			"quality": mini(out.size() % QUALITY.size(), QUALITY.size() - 1),
			"quality_name": str(q2["name"]),
			"set": sn,
			"color": q2["col"],
			"req_level": 1 + (out.size() % 24),
			"stats": sc,
			"stats_text": ", ".join(p2),
			"price": int(round(float(BASE_PRICE.get(slot, 150.0)) * 1.5)),
			"desc": "Снаряжение сета «%s»." % sn,
		})
	return out


static func all_slots() -> Dictionary:
	var out: Dictionary = {}
	for s in SLOTS:
		out[s] = build_slot(s)
	return out


static func find_item(slot: String, id: String) -> Dictionary:
	for it in build_slot(slot):
		if str(it["id"]) == id:
			return it
	return {}
