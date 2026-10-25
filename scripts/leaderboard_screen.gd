extends Control

## Лидерборд: показывает топ-10. Источник — OnlineService.
## Пока онлайн-сервер не подключён, работает локальный топ (GameState.leaderboard).
## При подключении USE_ONLINE загружается серверный топ и он выводится вместо локального.

@onready var scroll: ScrollContainer = $Scroll
@onready var rows: VBoxContainer = $Scroll/Rows
@onready var empty_label: Label = $EmptyLabel
@onready var status_label: Label = $StatusLabel
@onready var tour_theme: Label = $TournamentPanel/HBox/Info/ThemeLabel
@onready var tour_timer: Label = $TournamentPanel/HBox/Info/TimerLabel

func _ready() -> void:
	AudioManager.play("click")
	_refresh_tournament()
	_rebuild()
	if OnlineService.is_online():
		status_label.text = tr("ОНЛАЙН: загрузка…")
		OnlineService.fetch_top(_on_online_fetch)
	else:
		status_label.text = tr("Локальный топ-10")

## Турнир недели встроен в лидерборд (единый раздел «лидеры и награды»).
func _refresh_tournament() -> void:
	var week := Tournament.current_week()
	tour_theme.text = tr("ТУРНИР НЕДЕЛИ: %s") % Tournament.theme_for_week(week)
	var secs := Tournament.seconds_to_next_week()
	var h := secs / 3600
	var m := (secs % 3600) / 60
	var s2 := secs % 60
	tour_timer.text = tr("до конца: %02d:%02d:%02d") % [h, m, s2]

func _on_tournament_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/tournament.tscn")

func _rebuild() -> void:
	_render(GameState.leaderboard)

func _on_online_fetch(entries: Array) -> void:
	if entries.is_empty():
		status_label.text = tr("ОНЛАЙН: пока пусто")
		return
	status_label.text = tr("ОНЛАЙН: серверный топ-10")
	_render(entries)

func _render(entries: Array) -> void:
	for child in rows.get_children():
		child.queue_free()
	if entries.is_empty():
		empty_label.visible = true
		scroll.visible = false
		return
	empty_label.visible = false
	scroll.visible = true
	for i in mini(entries.size(), 10):
		var entry: Dictionary = entries[i]
		var row := HBoxContainer.new()
		var rank := Label.new()
		rank.custom_minimum_size = Vector2(60, 0)
		rank.text = "%d." % (i + 1)
		row.add_child(rank)
		var name := Label.new()
		name.custom_minimum_size = Vector2(260, 0)
		name.text = str(entry.get("name", "—"))
		row.add_child(name)
		var mode := Label.new()
		mode.custom_minimum_size = Vector2(160, 0)
		mode.text = str(entry.get("mode", "—"))
		row.add_child(mode)
		var score := Label.new()
		score.custom_minimum_size = Vector2(100, 0)
		score.text = str(entry.get("score", 0))
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(score)
		rows.add_child(row)

func _on_back() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
