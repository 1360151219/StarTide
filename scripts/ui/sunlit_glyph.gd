extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var glyph_id := "expedition"
var _selected := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_selected(value: bool) -> void:
	_selected = value
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(28, 28))
	var color := UiFactory.ACCENT if _selected else UiFactory.PRIMARY
	match glyph_id:
		"character": _draw_character(color)
		"compendium": _draw_compendium(color)
		"pause": _draw_pause(color)
		"clock": _draw_clock(color)
		"enemy": _draw_enemy(color)
		"level": _draw_level(color)
		"lock": _draw_lock(color)
		"sound": _draw_sound(color)
		"settings": _draw_settings(color)
		"equipment": _draw_equipment(color)
		"back": _draw_back(color)
		"confirm": _draw_confirm(color)
		"empty": _draw_empty(color)
		"heal": _draw_heal(color)
		"haste": _draw_haste(color)
		"magnet": _draw_magnet(color)
		"bomb": _draw_bomb(color)
		_: _draw_expedition(color)


func _draw_expedition(color: Color) -> void:
	var center := Vector2(14, 12)
	var compass := _star_points(center, 7.7, 2.8, 4)
	if _selected:
		draw_colored_polygon(compass, Color(UiFactory.ACCENT, 0.28))
	var outline := compass.duplicate()
	outline.append(compass[0])
	draw_polyline(outline, color, 2.0, true)
	draw_arc(Vector2(14, 18), 8.0, 0.25, PI - 0.25, 20, color, 1.8, true)
	draw_line(Vector2(6, 20), Vector2(22, 20), Color(color, 0.72), 1.5, true)


func _draw_character(color: Color) -> void:
	draw_circle(Vector2(14, 8), 4.2, Color(UiFactory.ACCENT, 0.2) if _selected else Color.TRANSPARENT)
	draw_arc(Vector2(14, 8), 4.2, 0.0, TAU, 24, color, 1.9, true)
	draw_arc(Vector2(14, 22), 9.0, PI + 0.32, TAU - 0.32, 24, color, 2.0, true)
	draw_line(Vector2(10, 16), Vector2(7, 21), color, 1.7, true)
	draw_line(Vector2(18, 16), Vector2(21, 21), color, 1.7, true)


func _draw_compendium(color: Color) -> void:
	var left := PackedVector2Array([Vector2(4, 6), Vector2(8, 5), Vector2(13, 7), Vector2(13, 23), Vector2(8, 21), Vector2(4, 22), Vector2(4, 6)])
	var right := PackedVector2Array([Vector2(24, 6), Vector2(20, 5), Vector2(15, 7), Vector2(15, 23), Vector2(20, 21), Vector2(24, 22), Vector2(24, 6)])
	if _selected:
		draw_colored_polygon(left, Color(UiFactory.ACCENT, 0.16))
		draw_colored_polygon(right, Color(UiFactory.ACCENT, 0.16))
	draw_polyline(left, color, 1.8, true)
	draw_polyline(right, color, 1.8, true)
	draw_line(Vector2(14, 7), Vector2(14, 23), color, 1.5, true)


func _draw_pause(color: Color) -> void:
	draw_rect(Rect2(7, 5, 5, 18), color, true)
	draw_rect(Rect2(16, 5, 5, 18), color, true)


func _draw_clock(color: Color) -> void:
	draw_arc(Vector2(14, 14), 9.5, 0.0, TAU, 32, color, 2.0, true)
	draw_line(Vector2(14, 14), Vector2(14, 8), color, 2.0, true)
	draw_line(Vector2(14, 14), Vector2(19, 17), color, 2.0, true)
	draw_circle(Vector2(14, 14), 1.5, color)


func _draw_enemy(color: Color) -> void:
	draw_arc(Vector2(14, 15), 8.5, PI, TAU, 24, color, 2.0, true)
	draw_line(Vector2(5.5, 15), Vector2(7.5, 22), color, 2.0, true)
	draw_line(Vector2(22.5, 15), Vector2(20.5, 22), color, 2.0, true)
	draw_circle(Vector2(10.5, 14), 1.5, color)
	draw_circle(Vector2(17.5, 14), 1.5, color)
	draw_line(Vector2(9, 7), Vector2(5, 3), color, 2.0, true)
	draw_line(Vector2(19, 7), Vector2(23, 3), color, 2.0, true)


func _draw_level(color: Color) -> void:
	var badge := PackedVector2Array([Vector2(14, 3), Vector2(23, 8), Vector2(21, 20), Vector2(14, 25), Vector2(7, 20), Vector2(5, 8), Vector2(14, 3)])
	draw_polyline(badge, color, 1.8, true)
	draw_line(Vector2(9, 15), Vector2(13, 19), color, 2.2, true)
	draw_line(Vector2(13, 19), Vector2(20, 10), color, 2.2, true)


func _draw_lock(color: Color) -> void:
	draw_arc(Vector2(14, 11), 6.0, PI, TAU, 20, color, 2.4, true)
	draw_rect(Rect2(7, 11, 14, 12), Color(color, 0.22), true)
	draw_rect(Rect2(7, 11, 14, 12), color, false, 2.0)
	draw_circle(Vector2(14, 17), 1.8, color)


func _draw_sound(color: Color) -> void:
	var speaker := PackedVector2Array([Vector2(4, 11), Vector2(9, 11), Vector2(15, 6), Vector2(15, 22), Vector2(9, 17), Vector2(4, 17)])
	draw_colored_polygon(speaker, Color(color, 0.24))
	draw_polyline(speaker, color, 1.8, true)
	draw_arc(Vector2(15, 14), 6.0, -0.8, 0.8, 12, color, 1.8, true)
	draw_arc(Vector2(15, 14), 9.0, -0.72, 0.72, 12, Color(color, 0.7), 1.5, true)


func _draw_settings(color: Color) -> void:
	for index in range(8):
		var direction := Vector2.from_angle(index * TAU / 8.0)
		draw_line(Vector2(14, 14) + direction * 8.0, Vector2(14, 14) + direction * 11.0, color, 3.2, true)
	draw_arc(Vector2(14, 14), 8.5, 0.0, TAU, 32, color, 2.4, true)
	draw_circle(Vector2(14, 14), 3.4, Color(UiFactory.SURFACE, 0.2) if _selected else Color.TRANSPARENT)
	draw_arc(Vector2(14, 14), 3.4, 0.0, TAU, 20, color, 2.0, true)


func _draw_equipment(color: Color) -> void:
	draw_line(Vector2(6, 22), Vector2(21, 7), color, 3.0, true)
	draw_line(Vector2(8, 24), Vector2(4, 20), color, 2.4, true)
	draw_line(Vector2(18, 6), Vector2(22, 10), color, 2.4, true)
	draw_arc(Vector2(10, 9), 5.0, 0.2, 1.5, 12, color, 1.7, true)


func _draw_back(color: Color) -> void:
	draw_line(Vector2(22, 14), Vector2(7, 14), color, 2.6, true)
	draw_line(Vector2(7, 14), Vector2(13, 8), color, 2.6, true)
	draw_line(Vector2(7, 14), Vector2(13, 20), color, 2.6, true)


func _draw_confirm(color: Color) -> void:
	draw_line(Vector2(5, 15), Vector2(11, 21), color, 2.8, true)
	draw_line(Vector2(11, 21), Vector2(23, 7), color, 2.8, true)


func _draw_empty(color: Color) -> void:
	var diamond := PackedVector2Array([Vector2(14, 5), Vector2(23, 14), Vector2(14, 23), Vector2(5, 14), Vector2(14, 5)])
	draw_polyline(diamond, Color(color, 0.56), 1.7, true)
	draw_circle(Vector2(14, 14), 2.0, Color(color, 0.42))


func _draw_heal(color: Color) -> void:
	var healing := UiFactory.HEALING if not _selected else UiFactory.ACCENT
	draw_arc(Vector2(14, 15), 8.5, 0.15, PI - 0.15, 24, healing, 2.2, true)
	draw_line(Vector2(6, 15), Vector2(14, 23), healing, 2.2, true)
	draw_line(Vector2(22, 15), Vector2(14, 23), healing, 2.2, true)
	draw_line(Vector2(14, 7), Vector2(14, 17), color, 2.0, true)


func _draw_haste(color: Color) -> void:
	for offset in [0.0, 5.0, 10.0]:
		draw_line(Vector2(4 + offset, 21), Vector2(14 + offset, 7), color, 2.0, true)
		draw_line(Vector2(14 + offset, 7), Vector2(16 + offset, 13), color, 2.0, true)


func _draw_magnet(color: Color) -> void:
	draw_arc(Vector2(14, 14), 8.0, 0.0, PI, 24, color, 3.0, true)
	draw_line(Vector2(6, 14), Vector2(6, 22), color, 3.0, true)
	draw_line(Vector2(22, 14), Vector2(22, 22), color, 3.0, true)
	draw_line(Vector2(5, 22), Vector2(9, 22), UiFactory.DANGER, 3.0, true)
	draw_line(Vector2(19, 22), Vector2(23, 22), UiFactory.BLOCK, 3.0, true)


func _draw_bomb(color: Color) -> void:
	draw_circle(Vector2(13, 16), 7.0, Color(color, 0.22))
	draw_arc(Vector2(13, 16), 7.0, 0.0, TAU, 24, color, 2.0, true)
	draw_line(Vector2(17, 10), Vector2(21, 6), color, 2.0, true)
	draw_circle(Vector2(22, 5), 2.0, UiFactory.ACCENT)


func _star_points(center: Vector2, outer_radius: float, inner_radius: float, arms: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(arms * 2):
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + float(index) * PI / float(arms)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
