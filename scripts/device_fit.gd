extends Node
## DeviceFit — авто-подгонка UI под экран устройства.
## Читает размеры экрана, сохраняет профиль, умеет поджимать элементы,
## вылезающие за пределы viewport.

var profile: Dictionary = {}


func _ready() -> void:
	capture()


func capture() -> Dictionary:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var safe := DisplayServer.get_display_safe_area()
	profile = {
		"viewport_w": int(vp.x),
		"viewport_h": int(vp.y),
		"screen_w": DisplayServer.screen_get_size().x,
		"screen_h": DisplayServer.screen_get_size().y,
		"dpi": DisplayServer.screen_get_dpi(),
		"aspect": snappedf(vp.x / maxf(1.0, vp.y), 0.001),
		"safe_x": safe.position.x,
		"safe_y": safe.position.y,
		"safe_w": safe.size.x,
		"safe_h": safe.size.y,
		"model": OS.get_model_name(),
		"os": OS.get_name(),
	}
	save()
	return profile


func fit(root: Node) -> Dictionary:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var moved := 0
	var clipped := 0
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is Control):
			continue
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		if c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		var pos := c.global_position
		var size := c.size
		if pos.x + size.x > vp.x + 1.0 or pos.y + size.y > vp.y + 1.0:
			clipped += 1
			var nx: float = clampf(pos.x, 0.0, maxf(0.0, vp.x - size.x))
			var ny: float = clampf(pos.y, 0.0, maxf(0.0, vp.y - size.y))
			if size.x > vp.x:
				nx = 0.0
			if size.y > vp.y:
				ny = 0.0
			if nx != pos.x or ny != pos.y:
				c.global_position = Vector2(nx, ny)
				moved += 1
	return {"clipped": clipped, "moved": moved, "viewport": vp}


func summary() -> String:
	return "Экран: %dx%d · viewport %dx%d · DPI %d · модель %s" % [
		int(profile.get("screen_w", 0)), int(profile.get("screen_h", 0)),
		int(profile.get("viewport_w", 0)), int(profile.get("viewport_h", 0)),
		int(profile.get("dpi", 0)), str(profile.get("model", "?")),
	]


func save() -> void:
	var f := FileAccess.open("user://device_profile.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(profile, "  "))
		f.close()
