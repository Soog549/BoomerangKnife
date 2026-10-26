extends Control

## Экран ежедневных наград: календарь на 7 дней + кнопка «Забрать»
## и ежедневный квест (одно задание на день с наградой-монетами).

@onready var streak_label: Label = $StreakLabel
@onready var calendar: GridContainer = $Calendar
@onready var message_label: Label = $Message
@onready var claim_button: Button = $ClaimButton
@onready var quest_title: Label = $QuestTitle
@onready var quest_label: Label = $QuestLabel
@onready var quest_claim: Button = $QuestClaim

func _ready() -> void:
	var fb := Button.new()
	fb.text = tr("🎲 ФОРТУНА (1 в день)")
	fb.custom_minimum_size = Vector2(600, 56)
	fb.position = Vector2(60, 1150)
	fb.size = Vector2(600, 56)
	fb.pressed.connect(_fortune_pressed)
	add_child(fb)
	AudioManager.play("click")
	# «Просыпаем» квест (сброс по дате, если нужно) и перерисовываемся
	GameState.current_quest()
	_build_calendar()
	_refresh()

func _build_calendar() -> void:
	for child in calendar.get_children():
		child.queue_free()
	# Показываем 7 дней календаря; крайний справа — текущий день.
	for i in 7:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(96, 96)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var reward: int = Economy.DAILY_REWARDS[i].coins
		label.text = tr("День %d\n+%d") % [i + 1, reward]
		cell.add_child(label)
		calendar.add_child(cell)

func _refresh() -> void:
	streak_label.text = tr("Серия: %d дней") % GameState.daily_streak
	if GameState.can_claim_daily():
		claim_button.text = tr("ЗАБРАТЬ +%d монет") % GameState.current_daily_reward()
		claim_button.disabled = false
		message_label.text = tr("Ежедневная награда доступна! Приходи каждый день для серии.")
	else:
		claim_button.text = tr("УЖЕ ЗАБРАНО (завтра)")
		claim_button.disabled = true
		message_label.text = tr("Возвращайся завтра, чтобы продолжить серию!")
	_refresh_quest()

func _refresh_quest() -> void:
	var q: Dictionary = GameState.current_quest()
	var prog := GameState.quest_progress()
	quest_title.text = tr("ЕЖЕДНЕВНЫЙ КВЕСТ")
	var reward_part := tr("+%d монет") % q.reward
	if q.has("booster") and q.booster != "":
		var bid: String = q.booster
		for b: Dictionary in Economy.BOOSTER_ITEMS:
			if b.id == bid:
				reward_part += " + %s" % b.label
				break
	quest_label.text = "%s  (%d/%d)    %s" % [tr(q.label), prog, q.target, reward_part]
	if GameState.can_claim_quest():
		quest_claim.text = tr("ЗАБРАТЬ: %s") % reward_part
		quest_claim.disabled = false
	elif GameState.quest_claimed:
		quest_claim.text = tr("КВЕСТ ЗАБРАН ")
		quest_claim.disabled = true
	else:
		quest_claim.text = tr("В ПРОЦЕССЕ")
		quest_claim.disabled = true

func _on_claim_pressed() -> void:
	var reward := GameState.claim_daily()
	if reward > 0:
		AudioManager.play("level")
	message_label.text = tr("Получено +%d монет!") % reward
	_refresh()

func _on_quest_claim_pressed() -> void:
	var reward := GameState.claim_quest()
	if reward > 0:
		AudioManager.play("level")
		message_label.text = tr("Квест выполнен: +%d монет!") % reward
	_refresh()

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _fortune_pressed() -> void:
	AudioManager.play("click")
	if not GameState.fortune_available():
		message_label.text = tr("Фортуна уже использована сегодня. Возвращайся завтра!")
		return
	var r := GameState.claim_fortune()
	if r.is_empty():
		return
	AudioManager.play("level")
	message_label.text = tr("Фортуна: %s") % str(r.get("label", ""))
