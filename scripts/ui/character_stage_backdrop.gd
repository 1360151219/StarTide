extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var bands := 48
	for index in range(bands):
		var ratio := float(index) / float(bands - 1)
		var color := UiFactory.BACKGROUND.lerp(Color("b8ddcf"), ratio)
		draw_rect(Rect2(0.0, size.y * ratio, size.x, size.y / bands + 1.0), color)
	_draw_hills()
	_draw_foliage()
	_draw_platform()


func _draw_hills() -> void:
	var distant := PackedVector2Array([
		Vector2(0, 152), Vector2(68, 112), Vector2(126, 142), Vector2(204, 90),
		Vector2(286, 138), Vector2(356, 98), Vector2(432, 144), Vector2(size.x, 116),
		Vector2(size.x, 210), Vector2(0, 210),
	])
	draw_colored_polygon(distant, Color(UiFactory.PRIMARY_LIGHT, 0.42))
	var near := PackedVector2Array([
		Vector2(0, 176), Vector2(74, 142), Vector2(154, 184), Vector2(246, 132),
		Vector2(332, 174), Vector2(410, 138), Vector2(size.x, 166),
		Vector2(size.x, 230), Vector2(0, 230),
	])
	draw_colored_polygon(near, Color(UiFactory.SUPPORTING, 0.3))


func _draw_foliage() -> void:
	for index in range(22):
		var x := 14.0 + fmod(float(index * 79), maxf(1.0, size.x - 28.0))
		var y := 28.0 + fmod(float(index * 53), 162.0)
		var leaf_color := Color(UiFactory.SUPPORTING, 0.32 if index % 2 == 0 else 0.2)
		draw_circle(Vector2(x, y), 3.0 + index % 3, leaf_color)
		if index % 4 == 0:
			draw_circle(Vector2(x + 5, y - 2), 2.2, Color(UiFactory.ACCENT, 0.52))


func _draw_platform() -> void:
	draw_set_transform(Vector2(size.x * 0.5, 238.0), 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 92.0, Color(UiFactory.SURFACE, 0.9))
	draw_arc(Vector2.ZERO, 92.0, 0.0, TAU, 52, Color(UiFactory.CANVAS_EDGE, 0.72), 5.0)
	draw_arc(Vector2.ZERO, 76.0, 0.0, TAU, 52, Color(UiFactory.PRIMARY, 0.44), 2.0)
	for angle in range(0, 360, 45):
		var direction := Vector2.from_angle(deg_to_rad(angle))
		draw_line(direction * 26.0, direction * 72.0, Color(UiFactory.CANVAS_EDGE, 0.18), 1.5)
	draw_set_transform(Vector2.ZERO)
