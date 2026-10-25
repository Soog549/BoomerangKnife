extends CanvasLayer

## Онбординг первого запуска (классика). Показывается один раз, пока
## GameState.tutorial_done = false. Шаги ведут игрока: тап -> бросок ->
## заполнение сегментов -> золотой сектор. Оверлей НЕ блокирует ввод
## (все контролы MOUSE_FILTER_IGNORE), а прогресс идёт по событиям игры
## (первый бросок, зачистка уровня). Страховка — таймер, который завершает
## подсказку, даже если игрок ничего не сделал.

const HINTS := [
	"Тапни в мишень — нож улетит и вернётся!",
	"Каждое попадание заполняет сегмент. Заполни весь круг!",
	"Золотой сектор даёт больше очков. Попади в него!",
]

const TIMEOUT_SECONDS := 25.0

var _stage := -1
var _clears := 0
var _active := false
var _dim: ColorRect
var _panel: PanelContainer
var _label: Label
var _timeout: SceneTreeTimer = null


func begin() -> void:
	layer = 100

	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.03, 0.08, 0.35)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_anchors(_dim, 0.0, 0.0, 1.0, 1.0)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.18, 0.92)
	sb.border_color = Color(0.4, 0.55, 0.3, 0.6)
	sb.set_corner_radius_all(14)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.content_margin_left = 18
	sb.content_margin_top = 14
	sb.content_margin_right = 18
	sb.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", sb)
	# Привязываем панель к низу экрана по центру. Важно: задаём и offset_top,
	# и offset_bottom, чтобы у контрола был ПОЛОЖИТЕЛЬНЫЙ размер (иначе панель
	# с отрицательной высотой не отрисовывается корректно).
	_set_anchors(_panel, 0.5, 1.0, 0.5, 1.0)
	_panel.offset_left = -320.0
	_panel.offset_right = 320.0
	_panel.offset_top = -230.0
	_panel.offset_bottom = -56.0
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1))
	_panel.add_child(_label)

	_active = true
	_show(0)
	_timeout = get_tree().create_timer(TIMEOUT_SECONDS)
	_timeout.timeout.connect(complete)


func _set_anchors(node: Control, ax: float, ay: float, bx: float, by: float) -> void:
	node.anchor_left = ax
	node.anchor_top = ay
	node.anchor_right = bx
	node.anchor_bottom = by
	node.grow_horizontal = Control.GROW_DIRECTION_BOTH


func _show(idx: int) -> void:
	if idx < 0 or idx >= HINTS.size():
		complete()
		return
	_stage = idx
	_label.text = tr(HINTS[idx])


func on_first_throw() -> void:
	if _active and _stage == 0:
		_show(1)


func on_target_cleared() -> void:
	if not _active:
		return
	_clears += 1
	if _stage == 0 and _clears >= 1:
		# Игрок зачистил уровень, не сделав ни одного тапа у нас на глазах —
		# всё равно двигаем подсказку дальше, чтобы она не зависла.
		_show(1)
	elif _stage == 1 and _clears >= 1:
		# Круг заполнен — показываем подсказку про золотой сектор.
		_show(2)
	elif _stage == 2 and _clears >= 2:
		complete()


func complete() -> void:
	if not _active:
		return
	_active = false
	if _timeout != null:
		_timeout.timeout.disconnect(complete)
		_timeout = null
	GameState.tutorial_done = true
	GameState.save_settings()
	queue_free()
