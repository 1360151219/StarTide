extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var progress := 0.0


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x < 160.0:
		return
	var line_y := 22.0
	var start_x := 44.0
	var end_x := size.x - 42.0
	_draw_mountain(Vector2(26, line_y + 1))
	_draw_chest(Vector2(size.x - 26, line_y + 1))
	var segment_count := 8
	for index in range(segment_count):
		var from_x := lerpf(start_x, end_x, float(index) / segment_count)
		var to_x := lerpf(start_x, end_x, float(index + 0.78) / segment_count)
		var reached := float(index + 1) / segment_count <= progress
		_draw_rope_segment(Vector2(from_x, line_y), Vector2(to_x, line_y), reached)
	for index in range(4):
		var ratio := float(index + 1) / 5.0
		var center := Vector2(lerpf(start_x, end_x, ratio), line_y)
		var reached := ratio <= progress
		_draw_waypoint(center, index, reached)
	_draw_flag(Vector2(lerpf(start_x, end_x, clampf(progress, 0.04, 0.96)), line_y - 1))


func _draw_rope_segment(start: Vector2, finish: Vector2, reached: bool) -> void:
	var outer := UiFactory.ACCENT_DARK if reached else Color(UiFactory.INK, 0.58)
	var inner := UiFactory.ACCENT if reached else Color(UiFactory.SURFACE, 0.58)
	draw_line(start, finish, outer, 4.0, true)
	draw_line(start, finish, inner, 1.8, true)


func _draw_waypoint(center: Vector2, index: int, reached: bool) -> void:
	var outer := PackedVector2Array()
	var sides := 4 + index % 2
	for point_index in range(sides):
		outer.append(center + Vector2.from_angle(-PI * 0.5 + point_index * TAU / sides) * 6.0)
	draw_colored_polygon(outer, UiFactory.ACCENT if reached else UiFactory.SURFACE)
	var outline := outer.duplicate()
	outline.append(outer[0])
	draw_polyline(outline, UiFactory.INK, 1.4, true)


func _draw_mountain(at: Vector2) -> void:
	var mountains := PackedVector2Array([
		at + Vector2(-14, 7), at + Vector2(-5, -7), at + Vector2(1, 1),
		at + Vector2(7, -6), at + Vector2(15, 7),
	])
	draw_colored_polygon(mountains, Color(UiFactory.SURFACE, 0.9))
	draw_polyline(PackedVector2Array([mountains[0], mountains[1], mountains[2], mountains[3], mountains[4]]), UiFactory.INK, 1.8, true)


func _draw_flag(at: Vector2) -> void:
	draw_line(at + Vector2(0, 6), at + Vector2(0, -9), UiFactory.SURFACE, 1.5, true)
	var flag := PackedVector2Array([at + Vector2(1, -9), at + Vector2(10, -6), at + Vector2(1, -2)])
	draw_colored_polygon(flag, UiFactory.ACCENT)
	draw_polyline(PackedVector2Array([flag[0], flag[1], flag[2], flag[0]]), UiFactory.INK, 1.2, true)


func _draw_chest(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-9, -3), Vector2(18, 12)), Color("e2b95f"), true)
	draw_rect(Rect2(at + Vector2(-9, -3), Vector2(18, 12)), UiFactory.INK, false, 1.5)
	draw_arc(at + Vector2(0, -3), 9.0, PI, TAU, 18, UiFactory.SURFACE, 2.5, true)
	draw_rect(Rect2(at + Vector2(-2, 1), Vector2(4, 5)), UiFactory.INK, true)
