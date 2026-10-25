extends Node

## Всплывающие уведомления (тосты) о наградах: +монеты, +кристаллы, «награда получена».
## Autoload-синглтон Toast. Создаёт временные сообщения в верхней части экрана.

const DURATION := 2.2   # сек, сколько виден тост
const SPACING := 48.0   # вертикальный шаг между тостами

var _toasts: Array[Control] = []   # активные тосты (самый новый — последний)
var _layer: CanvasLayer = null

## Основной метод: показать сообщение.
func show_message(text: String, color := Color.WHITE) -> void:
	_ensure_layer()
	if _layer == null:
		return

	var panel := PanelContainer.new()
	panel.modulate = Color(1, 1, 1, 0)
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)

	_layer.add_child(panel)
	panel.reset_size()
	panel.position.x = (screen_width() - panel.size.x) / 2.0
	panel.position.y = 60.0 + _place_at()

	_toasts.append(panel)

	var tween := create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.tween_interval(DURATION)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func() -> void:
		_toasts.erase(panel)
		panel.queue_free()
		_reflow()
	)

## Короткий вариант для «награда получена».
func show(text: String) -> void:
	show_message(text)

## Тост с бонусом валюты (жёлтый).
func show_reward(text: String) -> void:
	show_message(text, Color(1.0, 0.85, 0.3))

func _place_at() -> float:
	return _toasts.size() * SPACING

func _ensure_layer() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	if scene == null:
		return
	if _layer == null or not is_instance_valid(_layer) or _layer.get_parent() != scene:
		_layer = CanvasLayer.new()
		_layer.layer = 10
		scene.add_child(_layer)

func _reflow() -> void:
	for i in _toasts.size():
		_toasts[i].position.y = 60.0 + i * SPACING

func screen_width() -> float:
	if _layer != null and _layer.get_parent() != null:
		var parent := _layer.get_parent()
		if parent is Control:
			return parent.size.x
	return 720.0
