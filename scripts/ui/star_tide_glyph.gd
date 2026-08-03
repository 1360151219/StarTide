extends Control

const INK := Color("173d49")
const CREAM := Color("fff4cf")
const GOLD := Color("e8b84d")

var glyph_id := "expedition"
var _selected := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_selected(value: bool) -> void:
	_selected = value
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(28, 28))
	var color := CREAM if _selected else GOLD
	match glyph_id:
		"character":
			_draw_character(color)
		"compendium":
			_draw_compendium(color)
		"pause":
			_draw_pause(color)
		"clock":
			_draw_clock(color)
		"enemy":
			_draw_enemy(color)
		"level":
			_draw_level(color)
		_:
			_draw_expedition(color)


func _draw_expedition(color: Color) -> void:
	var center := Vector2(14, 12)
	var star := _star_points(center, 7.7, 3.2, 4)
	if _selected:
		draw_colored_polygon(star, Color(GOLD, 0.28))
	var outline := star.duplicate()
	outline.append(star[0])
	draw_polyline(outline, color, 2.0, true)
	draw_arc(Vector2(14, 17), 8.0, 0.25, PI - 0.25, 20, color, 1.8, true)
	draw_arc(Vector2(14, 20), 6.0, 0.28, PI - 0.28, 16, Color(color, 0.72), 1.5, true)


func _draw_character(color: Color) -> void:
	draw_circle(Vector2(14, 8), 4.2, Color(GOLD, 0.24) if _selected else Color.TRANSPARENT)
	draw_arc(Vector2(14, 8), 4.2, 0.0, TAU, 24, color, 1.9, true)
	draw_arc(Vector2(14, 22), 9.0, PI + 0.32, TAU - 0.32, 24, color, 2.0, true)
	draw_line(Vector2(10, 16), Vector2(7, 21), color, 1.7, true)
	draw_line(Vector2(18, 16), Vector2(21, 21), color, 1.7, true)
	_draw_small_star(Vector2(22.5, 6), color)


func _draw_compendium(color: Color) -> void:
	var left := PackedVector2Array([
		Vector2(3.5, 6),
		Vector2(8, 4.5),
		Vector2(13.5, 7),
		Vector2(13.5, 23),
		Vector2(8, 20.5),
		Vector2(3.5, 22),
		Vector2(3.5, 6),
	])
	var right := PackedVector2Array([
		Vector2(24.5, 6),
		Vector2(20, 4.5),
		Vector2(14.5, 7),
		Vector2(14.5, 23),
		Vector2(20, 20.5),
		Vector2(24.5, 22),
		Vector2(24.5, 6),
	])
	if _selected:
		draw_colored_polygon(left, Color(GOLD, 0.18))
		draw_colored_polygon(right, Color(GOLD, 0.18))
	draw_polyline(left, color, 1.8, true)
	draw_polyline(right, color, 1.8, true)
	draw_line(Vector2(14, 7), Vector2(14, 23), color, 1.5, true)
	_draw_small_star(Vector2(20, 11), color)


func _draw_pause(color: Color) -> void:
	draw_style_box(_pause_bar(color), Rect2(6.5, 5, 5.5, 18))
	draw_style_box(_pause_bar(color), Rect2(16, 5, 5.5, 18))


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
	var star := _star_points(Vector2(14, 12), 8.0, 3.2, 5)
	var outline := star.duplicate()
	outline.append(star[0])
	draw_polyline(outline, color, 1.8, true)
	draw_line(Vector2(8, 23), Vector2(14, 19), color, 1.8, true)
	draw_line(Vector2(14, 19), Vector2(20, 23), color, 1.8, true)


func _pause_bar(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style


func _draw_small_star(center: Vector2, color: Color) -> void:
	var star := _star_points(center, 3.3, 1.3, 4)
	var outline := star.duplicate()
	outline.append(star[0])
	draw_polyline(outline, color, 1.3, true)


func _star_points(center: Vector2, outer_radius: float, inner_radius: float, arms: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(arms * 2):
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + float(index) * PI / float(arms)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
