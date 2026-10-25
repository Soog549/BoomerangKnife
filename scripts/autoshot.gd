class_name Autoshot
extends Node
## Autoshot — автосъёмка чистого геймплея для витрин (probe-режим).
## Включается env BK_PROBE=1 (или OS.get_environment). При активном режиме:
##  - прячет курсор ОС,
##  - прячет демо-баннер (заглушку),
##  - авто-бросает нож в ближайшую цель (вызывает метод сцены),
##  - каждые N кадров сохраняет кадр экрана в user://autoshots/.
## Подключается хуком из сцен: Autoshot.begin(self); Autoshot.tick(1) в _process.
## Статичное состояние — в одном экземпляре.

static var _scene: Node = null
static var _active := false
static var _shot_interval := 25        # каждые ~25 кадров (~0.4с при 60fps)
static var _throw_interval := 30       # каждые ~30 кадров бросок
static var _frame := 0
static var _shot_i := 0
static var _throw_after := true
static var _dir := "user://autoshots"

static func begin(scene: Node) -> void:
	_scene = scene
	_active = OS.get_environment("BK_PROBE") == "1"
	if not _active:
		return
	# курсор скрыть, демо-баннер спрятать
	if scene is Node2D:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	# спрятать banner_demo (узел $UI/BannerDemo), если есть
	for n in scene.find_children("BannerDemo", "Control", true, false):
		n.visible = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	print("AUTOSHOT: ON  (shots -> ", _dir, ")")

static func tick(delta: float) -> void:
	if not _active or _scene == null or not is_instance_valid(_scene):
		return
	_frame += 1
	# авто-бросок
	if _frame % _throw_interval == 0:
		_auto_throw()
	# авто-скриншот
	if _frame % _shot_interval == 0:
		_save_shot()

static func _auto_throw() -> void:
	var s = _scene
	# единый вход: вызвать _throw / _handle_tap сцены в ближайшую цель
	var aim := _aim_at_target()
	if s.has_method("_throw"):
		s._throw(aim)
	elif s.has_method("_handle_tap"):
		s._handle_tap(aim)

static func _aim_at_target() -> Vector2:
	var s = _scene
	if s.has_method("_target_pos"):
		return s._target_pos()
	if s.has_method("_predict"):
		# дуэль: цель = мишень игрока 1
		var t = s.get("target_p1")
		if t != null and is_instance_valid(t):
			return s._predict(t)
	return Vector2(360, 300)

static func _save_shot() -> void:
	if _scene == null or not is_instance_valid(_scene):
		return
	var vp := _scene.get_viewport()
	if vp == null:
		return
	var img := vp.get_texture().get_image()
	_shot_i += 1
	var path := "%s/auto_%03d.png" % [ProjectSettings.globalize_path(_dir), _shot_i]
	img.save_png(path)
	print("AUTOSHOT: saved ", path)
