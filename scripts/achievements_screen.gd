extends Control

## Экран ачивок: AI-медальоны, статус, награда.

@onready var info_label: Label = $InfoLabel
@onready var items_box: VBoxContainer = $Scroll/Items

func _ready() -> void:
	UIKit.normalize(self)
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
	for i in Achievements.LIST.size():
		items_box.add_child(_make_row(Achievements.LIST[i], i))

func _make_row(a: Dictionary, idx: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var unlocked := Achievements.is_unlocked(a)

	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(72, 72)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var p := "res://assets/images/fanclub/achievements/ach-%02d.png" % (idx + 1)
	if ResourceLoader.exists(p):
		tex.texture = load(p)
	tex.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.35, 0.35, 0.42, 1)
	row.add_child(tex)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if unlocked:
		var reward_text := tr("+%d монет") % a.reward
		if a.has("crystals") and a.crystals > 0:
			reward_text += tr(", +%d крист.") % a.crystals
		label.text = "%s — %s (%s)" % [tr(a.label), tr(a.desc), reward_text]
	else:
		label.text = "%s — ???" % tr(a.label)
	row.add_child(label)

	var status := Label.new()
	status.custom_minimum_size = Vector2(48, 0)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.text = "✓" if unlocked else "🔒"
	status.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6) if unlocked else Color(0.5, 0.5, 0.6))
	row.add_child(status)
	return row

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
