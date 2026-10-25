extends Control

## Экран еженедельного турнира: тема недели, твой результат,
## таймер до конца, награда за участие (осколки).

@onready var title_label: Label = $Title
@onready var theme_label: Label = $Theme
@onready var score_label: Label = $Score
@onready var timer_label: Label = $Timer
@onready var claim_btn: Button = $ClaimButton
@onready var message_label: Label = $Message

func _ready() -> void:
	AudioManager.play("click")
	_refresh()
	# Обновляем таймер раз в минуту
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_refresh_timer)
	add_child(t)

func _refresh() -> void:
	var week := Tournament.current_week()
	theme_label.text = tr("Тема недели: %s") % Tournament.theme_for_week(week)
	score_label.text = tr("Твой результат: %d очков") % GameState.tournament_score
	_refresh_timer()
	if GameState.can_claim_tournament():
		claim_btn.text = tr("ЗАБРАТЬ %d осколков") % Tournament.participation_shards()
		claim_btn.disabled = false
		message_label.text = tr("Ты участвовал — забирай награду!")
	else:
		if GameState.tournament_claimed_week == week:
			claim_btn.text = tr("НАГРАДА ЗАБРАНА ")
		else:
			claim_btn.text = tr("ЗАБРАТЬ %d осколков") % Tournament.participation_shards()
		claim_btn.disabled = true
		message_label.text = tr("Играй в бесконечный режим, чтобы попасть в турнир.")

func _refresh_timer() -> void:
	var secs := Tournament.seconds_to_next_week()
	var h := secs / 3600
	var m := (secs % 3600) / 60
	var s2 := secs % 60
	timer_label.text = tr("До конца недели: %02d:%02d:%02d") % [h, m, s2]

func _on_claim_pressed() -> void:
	var reward := GameState.claim_tournament()
	if reward > 0:
		AudioManager.play("level")
		message_label.text = tr("Получено +%d осколков!") % reward
	else:
		message_label.text = tr("Награда уже забрана за эту неделю.")
	_refresh()

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
