extends GutTest

## Юнит-тесты экономики/казармы (GUT).

func test_hire_unit_spends_coins() -> void:
	GameState.coins = 200
	GameState.units = {}
	var ok: bool = GameState.hire_unit("warrior")
	assert_true(ok, "найм прошёл")
	assert_eq(GameState.coins, 80, "списано 120 монет")
	assert_eq(GameState.unit_level("warrior"), 1, "юнит уровня 1")


func test_hire_unit_not_enough_coins() -> void:
	GameState.coins = 50
	GameState.units = {}
	var ok: bool = GameState.hire_unit("warrior")
	assert_false(ok, "нельзя нанять без монет")
	assert_eq(GameState.unit_level("warrior"), 0, "юнит не нанят")


func test_spend_shards_guard() -> void:
	GameState.shards = 2
	assert_false(GameState.spend_shards(5), "нельзя потратить больше, чем есть")
	assert_eq(GameState.shards, 2, "осколки не списаны")
	assert_true(GameState.spend_shards(2), "можно потратить ровно сколько есть")
	assert_eq(GameState.shards, 0, "осколки списаны")
