extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	draw_circle(center, radius, Color(UiFactory.SURFACE_ALT, 0.96))
	draw_arc(center, radius, 0.0, TAU, 36, Color(UiFactory.PRIMARY, 0.62), 2.0, true)
	draw_arc(center, radius - 6.0, -PI * 0.2, PI * 0.9, 28, Color(UiFactory.GOLD, 0.62), 2.0, true)
	var shackle_center := center - Vector2(0, 5)
	draw_arc(shackle_center, 8.0, PI, TAU, 18, UiFactory.PRIMARY_DARK, 3.0, true)
	var body := Rect2(center - Vector2(11, 3), Vector2(22, 18))
	draw_rect(body, UiFactory.PRIMARY, true)
	draw_rect(body, UiFactory.PRIMARY_DARK, false, 2.0)
	draw_circle(center + Vector2(0, 5), 2.2, UiFactory.CREAM)
	var star_center := center + Vector2(17, -17)
	var star := PackedVector2Array([
		star_center - Vector2(0, 6), star_center + Vector2(2, -2),
		star_center + Vector2(6, 0), star_center + Vector2(2, 2),
		star_center + Vector2(0, 6), star_center + Vector2(-2, 2),
		star_center + Vector2(-6, 0), star_center + Vector2(-2, -2),
	])
	draw_colored_polygon(star, UiFactory.GOLD)
