extends Node
## ЛОГИЧЕСКИЕ ТЕСТЫ (реальные проверки в движке). Запуск: godot --headless --path . tests/logic_test.tscn

var passed := 0
var failed := 0


func _ready() -> void:
	_check("objectives_509", func() -> bool: return Objectives.all().size() == 509)
	_check("objectives_unique", func() -> bool:
		var ids := {}
		for o: Dictionary in Objectives.all():
			if ids.has(o.id):
				return false
			ids[o.id] = true
		return true)
	_check("worlds_8", func() -> bool: return Worlds.LIST.size() == 8)
	_check("worlds_index", func() -> bool:
		var i := Worlds.current_index()
		return i >= 0 and i < Worlds.LIST.size())
	_check("skin_has_label", func() -> bool:
		var s: Dictionary = GameState.current_skin()
		return s.has("label") and s.has("blade"))
	_check("xp_needed_monotonic", func() -> bool:
		var prev := 0
		for lv in range(1, 10):
			var v := Economy.player_xp_needed(lv)
			if v <= 0:
				return false
			if lv > 1 and v < prev:
				return false
			prev = v
		return true)
	_check("coins_no_negative", func() -> bool:
		var before := GameState.coins
		GameState.add_coins(-999999)
		var ok := GameState.coins >= 0
		GameState.coins = before
		return ok)
	_check("style_known", func() -> bool:
		var ok := ["base", "imperial", "epic", "space", "anime", "eurasia", "norse", "kids", "cyber", "dark"]
		return str(GameState.style_pack) in ok)
	_check("achievements_nonempty", func() -> bool: return Achievements.LIST.size() >= 12)
	_check("glyphs_nonempty", func() -> bool: return Economy.GLYPHS.size() >= 5)
	_check("telemetry_event", func() -> bool:
		Telemetry.event("logic_test", {"n": passed})
		return Telemetry.summary().events > 0)
	_check("rune_assets", func() -> bool:
		for i in range(1, 13):
			if not ResourceLoader.exists("res://assets/images/glyphs/rune-%02d.png" % i):
				return false
		return true)
	_check("packs_assets", func() -> bool:
		var styles := ["base", "imperial", "epic", "space", "anime", "eurasia", "norse", "kids", "cyber", "dark"]
		for st in styles:
			for f in ["mob-1.png", "tower-1.png", "knife-1.png", "shield-1.png"]:
				if not ResourceLoader.exists("res://assets/images/packs/%s/%s" % [st, f]):
					return false
		return true)
	print("TEST SUMMARY passed=%d failed=%d" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)


func _check(name: String, fn: Callable) -> void:
	var ok := false
	ok = bool(fn.call())
	if ok:
		passed += 1
		print("TEST OK ", name)
	else:
		failed += 1
		print("TEST FAIL ", name)
		Telemetry.error("test_fail", {"test": name})
