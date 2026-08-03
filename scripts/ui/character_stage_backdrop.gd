extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var bands := 64
	for index in range(bands):
		var ratio := float(index) / float(bands - 1)
		var color := Color("174c68").lerp(Color("082535"), ratio)
		draw_rect(Rect2(0.0, size.y * ratio, size.x, size.y / bands + 1.0), color)
	draw_circle(Vector2(size.x * 0.5, 144.0), 118.0, Color(0.23, 0.82, 0.78, 0.08))
	draw_arc(Vector2(size.x * 0.5, 144.0), 108.0, PI * 0.08, PI * 0.92, 48, Color(0.4, 0.94, 0.86, 0.28), 2.0)
	draw_arc(Vector2(size.x * 0.5, 144.0), 92.0, PI * 1.08, PI * 1.92, 48, Color(1.0, 0.77, 0.31, 0.28), 2.0)
	for index in range(18):
		var x := 24.0 + fmod(float(index * 83), maxf(1.0, size.x - 48.0))
		var y := 26.0 + fmod(float(index * 47), 180.0)
		var radius := 1.5 if index % 3 else 2.5
		draw_circle(Vector2(x, y), radius, Color(1.0, 0.93, 0.58, 0.62))
	draw_set_transform(Vector2(size.x * 0.5, 234.0), 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 88.0, Color(0.01, 0.08, 0.12, 0.55))
	draw_arc(Vector2.ZERO, 88.0, 0.0, TAU, 48, Color(0.34, 0.9, 0.82, 0.44), 3.0)
	draw_set_transform(Vector2.ZERO)
