extends Control

var max_value := 100.0:
	set(next_value):
		max_value = maxf(next_value, 0.001)
		value = minf(value, max_value)
		queue_redraw()

var value := 0.0:
	set(next_value):
		value = clampf(next_value, 0.0, max_value)
		queue_redraw()

var fill_color := Color.WHITE
var background_color := Color(0.35, 0.5, 0.52, 0.24)
var corner_radius := 4.0


func configure_colors(fill: Color, background: Color, radius: float) -> void:
	fill_color = fill
	background_color = background
	corner_radius = maxf(0.0, radius)
	queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_style_box(_style(background_color), bounds)
	var ratio := clampf(value / max_value, 0.0, 1.0)
	if ratio <= 0.0:
		return
	var fill_bounds := Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y))
	draw_style_box(_style(fill_color), fill_bounds)


func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	var radius := mini(roundi(corner_radius), roundi(size.y * 0.5))
	style.set_corner_radius_all(radius)
	return style
