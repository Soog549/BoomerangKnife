extends Control

const DIFF_ORDER := ["easy", "normal", "hard"]

var mode_buttons: Dictionary = {}

@onready var skin_label: Label = $Scroll/VBox/SkinLabel
@onready var diff_label: Label = $Scroll/VBox/DifficultyLabel
@onready var modes_box: VBoxContainer = $Scroll/VBox/ModesBox
@onready var booster_box: VBoxContainer = $Scroll/VBox/BoosterBox
@onready var gear_box: VBoxContainer = $Scroll/VBox/GearBox
@onready var preview_box: VBoxContainer = $Scroll/VBox/PreviewBox

const AVATAR_PATHS := [
	"res://assets/images/avatars/avatar_0.png",
	"res://assets/images/avatars/avatar_1.png",
	"res://assets/images/avatars/avatar_2.png",
	"res://assets/images/avatars/avatar_3.png",
	"res://assets/images/avatars/avatar_4.png",
	"res://assets/images/avatars/avatar_5.png",
	"res://assets/images/avatars/avatar_6.png",
	"res://assets/images/avatars/avatar_7.png",
	"res://assets/images/avatars/avatar_8.png",
	"res://assets/images/avatars/avatar_9.png",
	"res://assets/images/avatars/avatar_10.png",
	"res://assets/images/avatars/avatar_11.png",
	"res://assets/images/avatars/avatar_12.png",
	"res://assets/images/avatars/avatar_13.png",
	"res://assets/images/avatars/avatar_14.png",
	"res://assets/images/avatars/avatar_15.png",
	"res://assets/images/avatars/avatar_16.png",
	"res://assets/images/avatars/avatar_17.png",
	"res://assets/images/avatars/avatar_18.png",
	"res://assets/images/avatars/avatar_19.png",
	"res://assets/images/avatars/avatar_20.png",
]

func _ready() -> void:
	AudioManager.play("click")
	_build_preview()
	_build_mode_buttons()
	_build_boosters()
	_build_gear()
	_refresh_ui()
	GameState.economy_changed.connect(_build_boosters)

func _build_preview() -> void:
	for child in preview_box.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = tr("ПЕРСОНАЖ")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(header)
	var av := CharacterPreview.new()
	av.avatar_texture = load(AVATAR_PATHS[clampi(GameState.avatar, 0, AVATAR_PATHS.size() - 1)])
	av.size_flags_horizontal = SIZE_SHRINK_CENTER
	preview_box.add_child(av)

func _refresh_preview() -> void:
	for child in preview_box.get_children():
		if child is CharacterPreview:
			child.refresh()

func _build_mode_buttons() -> void:
	for child in modes_box.get_children():
		child.queue_free()
	mode_buttons.clear()
	for mode_key: String in GameState.MODES:
		var data: Dictionary = GameState.MODES[mode_key]
		if not GameState.is_mode_owned(mode_key):
			# Закрытый мод: показываем замок и отправляем в магазин
			var locked := Button.new()
			locked.text = tr(" %s [ур. %d] — открой в магазине") % [data.label, data.unlock_level]
			locked.pressed.connect(func(): _go_shop())
			modes_box.add_child(locked)
			continue
		var btn := CheckButton.new()
		btn.text = "%s — %s" % [tr(data.label), tr(data.desc)]
		btn.button_pressed = GameState.has_mode(mode_key)
		btn.toggled.connect(func(on: bool) -> void:
			_toggle_mode(mode_key, on))
		modes_box.add_child(btn)
		mode_buttons[mode_key] = btn

func _build_boosters() -> void:
	for child in booster_box.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = tr("БУСТЕРЫ (одноразово за забег)")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	booster_box.add_child(header)
	# Несколько «пустых» пунктов экипировки: бустер, срабатывающий в забеге.
	for b: Dictionary in Economy.BOOSTER_ITEMS:
		var row := HBoxContainer.new()
		var amount := GameState.booster_count(b.id)
		var label := Label.new()
		label.custom_minimum_size = Vector2(360, 0)
		if amount > 0:
			label.text = "%s — %s  (x%d)" % [tr(b.label), tr(b.desc), amount]
		else:
			label.text = tr("%s — %s  (нет в наличии)") % [b.label, b.desc]
			label.modulate = Color(0.7, 0.7, 0.7, 1)
		row.add_child(label)
		var btn := Button.new()
		if GameState.armed_booster == b.id:
			btn.text = tr("ГОТОВ ")
			btn.disabled = true
		elif amount > 0:
			btn.text = tr("В ЛОАДАУТ")
			btn.pressed.connect(func() -> void:
				GameState.armed_booster = b.id
				GameState.save_settings()
				AudioManager.play("click")
				_build_boosters())
		else:
			btn.text = tr("В МАГАЗИН")
			btn.pressed.connect(func() -> void:
				AudioManager.play("click")
				get_tree().change_scene_to_file("res://scenes/shop.tscn"))
		row.add_child(btn)
		booster_box.add_child(row)
	var clear := Button.new()
	clear.text = tr("Снять бустер")
	clear.pressed.connect(func() -> void:
		GameState.armed_booster = ""
		GameState.save_settings()
		AudioManager.play("click")
		_build_boosters())
	booster_box.add_child(clear)

func _build_gear() -> void:
	for child in gear_box.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = tr("СНАРЯЖЕНИЕ (шлем / доспех / ботинки / оружие / кольца)")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear_box.add_child(header)
	for it in Economy.all_equipment():
		var eq_id: String = it.id
		var owned := GameState.is_equipment_owned(eq_id)
		var row := HBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(420, 0)
		if owned:
			label.text = "%s — %s" % [tr(it.label), tr(it.desc)]
			if GameState.equipped_in(it.slot) == eq_id:
				label.text += "  "
		else:
			label.text = tr(" %s — открой в магазине") % it.label
			label.modulate = Color(0.7, 0.7, 0.7, 1)
		row.add_child(label)
		var btn := Button.new()
		if owned:
			if GameState.equipped_in(it.slot) == eq_id:
				btn.text = tr("СНЯТЬ")
				btn.pressed.connect(func() -> void:
					GameState.unequip_slot(it.slot)
					GameState.save_settings()
					AudioManager.play("click")
					_build_gear()
					_refresh_preview())
			else:
				btn.text = tr("НАДЕТЬ")
				btn.pressed.connect(func() -> void:
					GameState.equip_item(eq_id)
					GameState.save_settings()
					AudioManager.play("level")
					_build_gear()
					_refresh_preview())
		else:
			btn.text = tr("В МАГАЗИН")
			btn.pressed.connect(func() -> void:
				AudioManager.play("click")
				get_tree().change_scene_to_file("res://scenes/shop.tscn"))
		row.add_child(btn)
		gear_box.add_child(row)

func _toggle_mode(mode_key: String, on: bool) -> void:
	if on:
		if not GameState.has_mode(mode_key):
			GameState.selected_modes.append(mode_key)
	else:
		GameState.selected_modes.erase(mode_key)
	GameState.save_settings()
	AudioManager.play("click")
	_refresh_ui()

func _on_skin_prev_pressed() -> void:
	# Цикл только по открытым скинам
	var owned: Array[int] = []
	for i in GameState.SKINS.size():
		if GameState.is_skin_owned(i):
			owned.append(i)
	if owned.size() == 0:
		return
	var idx := owned.find(GameState.selected_skin)
	GameState.selected_skin = owned[(idx + 1) % owned.size()]
	GameState.save_settings()
	AudioManager.play("click")
	_refresh_ui()

func _go_shop() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func _on_difficulty_prev_pressed() -> void:
	var idx := DIFF_ORDER.find(GameState.difficulty)
	GameState.difficulty = DIFF_ORDER[(idx + 1) % DIFF_ORDER.size()]
	GameState.save_settings()
	AudioManager.play("click")
	_refresh_ui()

func _refresh_ui() -> void:
	var skin: Dictionary = GameState.current_skin()
	if GameState.is_skin_owned(GameState.selected_skin):
		skin_label.text = tr("Скин: %s") % skin.label
	else:
		skin_label.text = tr("Скин:  (открой в магазине)")
	diff_label.text = GameState.difficulty_data().label
	for mode_key: String in mode_buttons:
		if mode_buttons.has(mode_key) and is_instance_valid(mode_buttons[mode_key]):
			mode_buttons[mode_key].button_pressed = GameState.has_mode(mode_key)

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
