extends Control

## Экран ачивок: показывает все достижения, статус и награду.

@onready var info_label: Label = $InfoLabel
@onready var items_box: VBoxContainer = $Scroll/Items

func _ready() -> void:
	AudioManager.play("click")
	_rebuild()

func _rebuild() -> void:
	for child in items_box.get_children():
		child.queue_free()
	var unlocked_count := 0
	for a in Achievements.LIST:
		if Achievements.is_unlocked(a):
			unlocked_count += 1
	info_label.text = tr("Открыто: %d из %d") % [unlocked_count, Achievements.LIST.size()]
	for a in Achievements.LIST:
		items_box.add_child(_make_row(a))

func _make_row(a: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	var unlocked := Achievements.is_unlocked(a)

	var icon := Label.new()
	icon.custom_minimum_size = Vector2(40, 0)
	icon.text = "" if unlocked else ""
	row.add_child(icon)

	var label := Label.new()
	label.custom_minimum_size = Vector2(460, 0)
	if unlocked:
		var reward_text := tr("+%d монет") % a.reward
		if a.has("crystals") and a.crystals > 0:
			reward_text += tr(", +%d крист.") % a.crystals
		label.text = "%s — %s (%s)" % [tr(a.label), tr(a.desc), reward_text]
	else:
		label.text = "%s — ???" % tr(a.label)
	row.add_child(label)

	var status := Label.new()
	status.text = "" if unlocked else "…"
	status.custom_minimum_size = Vector2(40, 0)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(status)
	return row

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
