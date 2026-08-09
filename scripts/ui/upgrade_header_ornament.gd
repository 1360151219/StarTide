extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 13)
	for index in range(11):
		var angle := lerpf(PI + 0.28, TAU - 0.28, float(index) / 10.0)
		var inner := center + Vector2.from_angle(angle) * 18.0
		var outer := center + Vector2.from_angle(angle) * (31.0 if index % 2 == 0 else 25.0)
		draw_line(inner, outer, Color(UiFactory.ACCENT, 0.86), 3.0, true)
	draw_arc(center, 21.0, PI + 0.15, TAU - 0.15, 26, UiFactory.ACCENT, 4.0, true)
	for left in [true, false]:
		var sign_value := -1.0 if left else 1.0
		var anchor := Vector2(28 if left else size.x - 28, size.y * 0.55)
		draw_arc(anchor, 15.0, -PI * 0.55 if left else PI * 0.55, PI * 0.55 if left else PI * 1.45, 18, Color("9b7544"), 4.0, true)
		for index in range(3):
			var leaf_center := anchor + Vector2(sign_value * (12 + index * 9), -8 + index * 8)
			_draw_leaf(leaf_center, sign_value, Color(UiFactory.SUPPORTING, 0.82 - index * 0.1))


func _draw_leaf(center: Vector2, direction: float, color: Color) -> void:
	var axis := Vector2(direction, -0.35).normalized()
	var side := axis.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		center - axis * 7.0, center + side * 4.0, center + axis * 8.0, center - side * 4.0,
	]), color)
