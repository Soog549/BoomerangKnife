extends Node
## Тестовые прогоны, включаются флагами командной строки:
##   godot <scene> -- --overflow   → замер переполнения UI
##   godot <scene> -- --autoplay   → авто-игра (броски) + проверка живучести

var _overflow := false
var _autoplay := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_overflow = "--overflow" in args
	_autoplay = "--autoplay" in args
	if _overflow:
		_run_overflow()
	elif _autoplay:
		_run_autoplay()


func _run_overflow() -> void:
	await get_tree().create_timer(1.2).timeout
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var sc := get_tree().current_scene
	var bad := 0
	var worst := ""
	var worst_area := 0.0
	if sc != null:
		var stack: Array = [sc]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for c in n.get_children():
				stack.append(c)
			if not (n is Control):
				continue
			var c2 := n as Control
			if not c2.is_visible_in_tree():
				continue
			if c2.size.x < 4.0 or c2.size.y < 4.0:
				continue
			if _in_scroll(c2):
				continue
			var pos := c2.global_position
			var over_x: float = maxf(0.0, pos.x + c2.size.x - vp.x)
			var over_y: float = maxf(0.0, pos.y + c2.size.y - vp.y)
			var over_neg: float = maxf(0.0, -pos.x) + maxf(0.0, -pos.y)
			var area: float = over_x + over_y + over_neg
			if area > 2.0:
				bad += 1
				if area > worst_area:
					worst_area = area
					worst = "%s(+%.0f px)" % [c2.name, area]
	print("OVERFLOW %d worst=%s viewport=%dx%d" % [bad, worst, int(vp.x), int(vp.y)])
	get_tree().quit()


func _run_autoplay() -> void:
	await get_tree().create_timer(1.0).timeout
	var sc := get_tree().current_scene
	if sc == null:
		print("AUTOPLAY_FAIL no_scene")
		get_tree().quit()
		return
	if sc.has_method("_start_round"):
		sc.call("_start_round")
	var throws := 0
	for i in 16:
		await get_tree().create_timer(0.35).timeout
		if sc.has_method("_throw_auto"):
			sc.call("_throw_auto")
			throws += 1
		var alive: bool = is_instance_valid(sc) and sc.is_inside_tree()
		if not alive:
			print("AUTOPLAY_FAIL scene_died throws=%d" % throws)
			get_tree().quit()
			return
	print("AUTOPLAY_OK throws=%d" % throws)
	get_tree().quit()


func _in_scroll(n: Node) -> bool:
	var p: Node = n.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false
