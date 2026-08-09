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
	var line_y := 18.0
	var start_x := 56.0
	var end_x := size.x - 52.0
	_draw_mountain(Vector2(23, line_y + 2))
	_draw_chest(Vector2(size.x - 23, line_y + 1))
	var segment_count := 18
	for index in range(segment_count):
		var from_x := lerpf(start_x, end_x, float(index) / segment_count)
		var to_x := lerpf(start_x, end_x, float(index + 0.65) / segment_count)
		var reached := float(index + 1) / segment_count <= progress
		draw_line(Vector2(from_x, line_y), Vector2(to_x, line_y), UiFactory.ACCENT if reached else Color(UiFactory.SURFACE, 0.76), 3.0, true)
	for index in range(4):
		var ratio := float(index + 1) / 5.0
		var center := Vector2(lerpf(start_x, end_x, ratio), line_y)
		var reached := ratio <= progress
		draw_circle(center, 7.0, UiFactory.ACCENT if reached else UiFactory.SURFACE)
		draw_circle(center, 3.7, UiFactory.HUD_SURFACE)
	_draw_flag(Vector2(lerpf(start_x, end_x, clampf(progress, 0.04, 0.96)), line_y - 1))


func _draw_mountain(at: Vector2) -> void:
	var mountains := PackedVector2Array([
		at + Vector2(-20, 10), at + Vector2(-7, -10), at + Vector2(1, 2),
		at + Vector2(10, -8), at + Vector2(22, 10),
	])
	draw_colored_polygon(mountains, Color(UiFactory.SURFACE, 0.9))
	draw_polyline(PackedVector2Array([mountains[0], mountains[1], mountains[2], mountains[3], mountains[4]]), UiFactory.INK, 1.8, true)


func _draw_flag(at: Vector2) -> void:
	draw_line(at + Vector2(0, 8), at + Vector2(0, -14), UiFactory.SURFACE, 2.0, true)
	var flag := PackedVector2Array([at + Vector2(1, -14), at + Vector2(15, -10), at + Vector2(1, -5)])
	draw_colored_polygon(flag, UiFactory.ACCENT)
	draw_polyline(PackedVector2Array([flag[0], flag[1], flag[2], flag[0]]), UiFactory.INK, 1.2, true)


func _draw_chest(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-13, -5), Vector2(26, 18)), Color("e2b95f"), true)
	draw_rect(Rect2(at + Vector2(-13, -5), Vector2(26, 18)), UiFactory.INK, false, 2.0)
	draw_arc(at + Vector2(0, -5), 13.0, PI, TAU, 18, UiFactory.SURFACE, 4.0, true)
	draw_rect(Rect2(at + Vector2(-3, 1), Vector2(6, 7)), UiFactory.INK, true)
