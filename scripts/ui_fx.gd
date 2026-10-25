extends Node

## Глобальная мини-анимация нажатия для всех кнопок (Button/CheckButton/
## OptionButton/TextureButton). При button_down кнопка слегка сжимается,
## при button_up — возвращается. Чисто визуально; логику нажатий НЕ трогает
## (сигналы pressed/подключения сцен остаются как были).
## Web-совместимо: используются только Tween и сигналы, платформенных API нет.
##
## Состояния hover/pressed/disabled у кнопок задаются темой
## `assets/theme/concept_theme.tres` (Button/styles/normal|hover|pressed|disabled|focus),
## которая подключена глобально в project.godot. Этот скрипт лишь добавляет
## «отзыв» при физическом нажатии.

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	# Повесить на кнопки, созданные до готовности автолоада (обычно их нет,
	# но подстраховываемся).
	for n in get_tree().root.find_children("*", "BaseButton", true, false):
		if n is BaseButton:
			_register(n)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_register(node)


func _register(btn: BaseButton) -> void:
	if btn.has_meta("_uipress_fx"):
		return
	btn.set_meta("_uipress_fx", true)
	btn.button_down.connect(_on_down.bind(btn))
	btn.button_up.connect(_on_up.bind(btn))
	btn.mouse_exited.connect(_on_up.bind(btn))


func _on_down(btn: BaseButton) -> void:
	btn.pivot_offset = btn.size * 0.5
	_kill(btn)
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.05)
	btn.set_meta("_uipress_tween", tw)


func _on_up(btn: BaseButton) -> void:
	_kill(btn)
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE, 0.10)
	btn.set_meta("_uipress_tween", tw)


func _kill(btn: BaseButton) -> void:
	if btn.has_meta("_uipress_tween"):
		var tw: Tween = btn.get_meta("_uipress_tween")
		if tw.is_valid():
			tw.kill()
		btn.remove_meta("_uipress_tween")
