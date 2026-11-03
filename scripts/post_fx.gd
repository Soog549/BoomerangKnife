extends CanvasLayer
## PostFX — кино-виньетка поверх игры (отключаемая).

var _rect: ColorRect = null


func _ready() -> void:
	layer = 89
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	var sh := load("res://shaders/vignette.gdshader")
	if sh != null:
		mat.shader = sh
		_rect.material = mat
	add_child(_rect)
	_apply()


func _apply() -> void:
	if _rect == null:
		return
	_rect.visible = bool(GameState.postfx_enabled)
