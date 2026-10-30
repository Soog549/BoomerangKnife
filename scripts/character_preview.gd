extends Control
class_name CharacterPreview

## Превью персонажа с экипировкой «на теле». Рисует стилизованный силуэт
## (палитра концепта «Уютная Лесная Ночь»): зона-слот каждого предмета
## подсвечивается, когда предмет надет. Носится на экранах лоадаута/профиля.

const FILL_BODY := Color(0.11, 0.14, 0.25, 1.0)
const FILL_BODY_2 := Color(0.16, 0.21, 0.38, 1.0)
const OUTLINE := Color(0.6, 0.66, 0.75, 0.9)
const ACCENT_GEAR := Color(1.0, 0.835, 0.29, 1.0)
const ACCENT_ICE := Color(0.302, 0.882, 1.0, 1.0)
const ACCENT_METAL := Color(0.604, 0.647, 0.698, 1.0)
const NEON_GREEN := Color(0.224, 1.0, 0.533, 1.0)
const EMPTY_HINT := Color(0.28, 0.32, 0.42, 0.85)

var avatar_texture: Texture2D = null
var _t := 0.0
var body_col := Color(0.12, 0.15, 0.23)
var body_hi := Color(0.19, 0.23, 0.33)
var accent_col := Color(0.95, 0.8, 0.3)

## Слот -> признаки предмета (для отрисовки зон).
const SLOT_STYLES := {
	"shield": {"label": "Щит", "color": ACCENT_ICE},
	"helmet": {"label": "Шлем",   "color": ACCENT_GEAR},
	"armor":  {"label": "Доспех", "color": ACCENT_GEAR},
	"boots":  {"label": "Ботинки", "color": ACCENT_ICE},
	"weapon": {"label": "Оружие", "color": ACCENT_METAL},
	"ring":   {"label": "Кольцо", "color": ACCENT_METAL},
}

func _ready() -> void:
	custom_minimum_size = Vector2(480, 300)
	size = Vector2(480, 300)
	queue_redraw()

func _process(dt: float) -> void:
	_t += dt
	if avatar_texture != null:
		queue_redraw()

func refresh() -> void:
	queue_redraw()

func _equipped_slots() -> Dictionary:
	return GameState.equipped

func _equipped_id(slot: String) -> String:
	return str(_equipped_slots().get(slot, ""))

func _draw() -> void:
	var w := size.x
	var cx := w * 0.5
	var skin: Dictionary = GameState.current_skin()
	accent_col = skin.get("blade", ACCENT_GEAR)

	# ---- голова + аватар ----
	var head_c := Vector2(cx, 78.0)
	if avatar_texture == null:
		draw_circle(head_c, 32.0, FILL_BODY_2)
	if avatar_texture == null:
		draw_arc(head_c, 32.0, 0, TAU, 40, OUTLINE, 2.0)
	if avatar_texture != null:
		var av_size := 96.0
		var bob := sin(_t * 2.6) * 3.0
		var tilt := sin(_t * 1.7) * 0.05
		draw_set_transform(head_c + Vector2(0, bob), tilt, Vector2.ONE)
		draw_texture_rect(avatar_texture, Rect2(Vector2(-av_size, -av_size) * 0.5, Vector2(av_size, av_size)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Шлем: ободок + гребень
	if _equipped_id("helmet") != "":
		draw_arc(head_c, 32.0, PI * 0.85, PI * 2.15, 30, ACCENT_GEAR, 5.0)
		draw_line(head_c + Vector2(-6, -30), head_c + Vector2(6, -34), ACCENT_GEAR, 3.0)
	else:
		if avatar_texture == null:
			draw_arc(head_c, 30.0, PI * 0.95, PI * 2.05, 24, EMPTY_HINT, 1.5)

	# ---- торс ----
	var torso_top := 134.0
	var torso_bot := 192.0
	var torso_w := 62.0
	var box := Rect2(cx - torso_w * 0.5, torso_top, torso_w, torso_bot - torso_top)
	draw_rect(box, body_hi, true)
	draw_circle(Vector2(cx - torso_w * 0.5 + 10, torso_top), 10.0, body_hi)
	draw_circle(Vector2(cx + torso_w * 0.5 - 10, torso_top), 10.0, body_hi)
	draw_rect(box, OUTLINE, false, 2.0)
	draw_line(Vector2(cx - torso_w * 0.5 + 6, torso_bot - 6), Vector2(cx + torso_w * 0.5 - 6, torso_bot - 6), accent_col, 3.0)
	draw_line(Vector2(cx, torso_top + 6), Vector2(cx, torso_bot - 10), body_col, 3.0)
	# Доспех: нагрудник
	if _equipped_id("armor") != "":
		draw_rect(Rect2(cx - torso_w * 0.5 + 8, torso_top + 10, torso_w - 16, torso_bot - torso_top - 20), ACCENT_GEAR, false, 4.0)
		draw_rect(Rect2(cx - torso_w * 0.5 + 12, torso_top + 16, torso_w - 24, 14), ACCENT_GEAR, false, 2.0)

	# ---- руки (левая с кольцом, правая с оружием) ----
	var shoulder_l := Vector2(cx - torso_w * 0.5 - 4, torso_top + 14)
	var shoulder_r := Vector2(cx + torso_w * 0.5 + 4, torso_top + 14)
	_draw_arm(shoulder_l, Vector2(cx - 66, 184.0))
	_draw_arm(shoulder_r, Vector2(cx + 66, 166.0))
	# Кольцо на левом кулаке
	if _equipped_id("ring") != "":
		draw_arc(Vector2(cx - 66, 184.0), 8.0, 0, TAU, 20, ACCENT_METAL, 3.0)
	else:
		draw_arc(Vector2(cx - 62, 182.0), 7.0, 0, TAU, 16, EMPTY_HINT, 1.5)
	if _equipped_id("shield") != "":
		var shp := "res://assets/images/shields/%s.png" % _equipped_id("shield")
		if ResourceLoader.exists(shp):
			draw_texture_rect(load(shp), Rect2(cx - 96.0, 122.0, 52.0, 52.0), false)
	# Оружие в правой руке: клинок-капля (стилизованный нож)
	var weapon_pos := Vector2(cx + 66, 166.0)
	if _equipped_id("weapon") != "":
		var blade := PackedVector2Array([
			weapon_pos + Vector2(-6, 4), weapon_pos + Vector2(34, -26),
			weapon_pos + Vector2(30, -18), weapon_pos + Vector2(4, 10),
		])
		draw_colored_polygon(blade, ACCENT_METAL)
		draw_polyline(blade, OUTLINE, 1.5, true)
	else:
		draw_line(weapon_pos, weapon_pos + Vector2(22, -22), EMPTY_HINT, 1.5)

	# ---- ноги + ботинки ----
	var hip_l := Vector2(cx - 18, torso_bot - 4)
	var hip_r := Vector2(cx + 18, torso_bot - 4)
	_draw_leg(hip_l, Vector2(cx - 16, 236.0))
	_draw_leg(hip_r, Vector2(cx + 16, 236.0))
	_draw_foot(Vector2(cx - 16, 240.0), true)
	_draw_foot(Vector2(cx + 16, 240.0), false)

	# ---- подпись зон: что надето ----
	var equipped_parts: Array[String] = []
	for slot: String in SLOT_STYLES:
		var id := _equipped_id(slot)
		var style: Dictionary = SLOT_STYLES[slot]
		if id != "":
			equipped_parts.append(tr(style.label))
	if equipped_parts.is_empty():
		equipped_parts.append(tr("нет снаряжения"))
	var font := ThemeDB.fallback_font
	var sub := ", ".join(PackedStringArray(equipped_parts))
	var sub_size_px := 15.0
	draw_string(font, Vector2(0, size.y - 6), sub, HORIZONTAL_ALIGNMENT_CENTER, size.x, sub_size_px)
	for slot: String in SLOT_STYLES:
		if _equipped_id(slot) != "":
			var style: Dictionary = SLOT_STYLES[slot]
			var marker := "+ %s" % tr(style.label)
			var mw := font.get_string_size(marker, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size_px - 3.0).x
			draw_string(font, Vector2(size.x - mw - 8, size.y - 6), marker, HORIZONTAL_ALIGNMENT_LEFT, mw, sub_size_px - 3.0, style.color)

func _draw_arm(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, OUTLINE, 18.0)
	draw_line(from, to, body_hi, 14.0)
	draw_circle(to, 8.0, body_hi)

func _draw_leg(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, OUTLINE, 20.0)
	draw_line(from, to, body_hi, 16.0)
	draw_circle(to, 9.0, body_hi)

func _draw_foot(at: Vector2, left: bool) -> void:
	var dir := -1.0 if left else 1.0
	if _equipped_id("boots") != "":
		draw_rect(Rect2(at, Vector2(20.0 * dir, 12.0)), ACCENT_ICE, true)
		draw_rect(Rect2(at, Vector2(20.0 * dir, 12.0)), OUTLINE, false, 1.5)
		return
	draw_rect(Rect2(at, Vector2(20.0 * dir, 12.0)), body_hi, true)
	draw_rect(Rect2(at, Vector2(20.0 * dir, 12.0)), OUTLINE, false, 1.5)