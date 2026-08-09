extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	draw_circle(center, radius, Color(UiFactory.SURFACE_ALT, 0.98))
	draw_arc(center, radius, 0.0, TAU, 36, Color(UiFactory.MUTED_INK, 0.82), 2.0, true)
	var shackle_center := center - Vector2(0, 5)
	draw_arc(shackle_center, 8.0, PI, TAU, 18, UiFactory.INK, 3.0, true)
	var body := Rect2(center - Vector2(11, 3), Vector2(22, 18))
	draw_rect(body, UiFactory.PRIMARY, true)
	draw_rect(body, UiFactory.INK, false, 2.0)
	draw_circle(center + Vector2(0, 5), 2.2, UiFactory.SURFACE)
	var buckle := Rect2(center + Vector2(13, -20), Vector2(9, 9))
	draw_rect(buckle, UiFactory.ACCENT, true)
	draw_rect(buckle, UiFactory.INK, false, 1.5)
