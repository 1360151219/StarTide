extends Node2D


func _draw_pickup_xp(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	for index in range(5):
		var angle := index * TAU / 5.0 + progress * 2.0
		var point := center + Vector2.from_angle(angle) * radius * (0.2 + progress) + Vector2(0, -progress * 18.0)
		draw_circle(point, 3.0 * alpha, Color(0.42, 0.94, 1.0, alpha))
	draw_arc(center, radius * (0.45 + progress), 0.0, TAU, 28, Color(0.04, 0.35, 0.46, alpha * 0.85), 2.4)


func _draw_pickup_heal(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var ring := radius * (0.45 + progress * 0.9)
	draw_arc(center, ring, 0.0, TAU, 32, Color(0.1, 0.38, 0.28, alpha * 0.78), 5.0)
	draw_arc(center, ring, 0.0, TAU, 32, Color(0.54, 0.94, 0.62, alpha), 2.4)
	for side in [-1.0, 1.0]:
		draw_circle(center + Vector2(side * 4.0, -progress * 22.0), 5.0 * alpha, Color(0.95, 0.38, 0.5, alpha))


func _draw_pickup_magnet(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var ring := radius * (0.28 + progress * 0.72)
	draw_arc(center, ring, -PI * 0.85, PI * 0.85, 44, Color(0.06, 0.37, 0.45, alpha * 0.86), 7.0)
	draw_arc(center, ring, -PI * 0.85, PI * 0.85, 44, Color(1.0, 0.84, 0.4, alpha), 3.0)
	for index in range(6):
		var direction := Vector2.from_angle(index * TAU / 6.0 + progress)
		draw_line(center + direction * ring * 0.42, center + direction * ring, Color(0.46, 0.92, 0.91, alpha * 0.72), 1.8, true)


func _draw_pickup_haste(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	for index in range(5):
		var y := (index - 2) * 8.0
		var length := radius * (0.55 + index % 2 * 0.22)
		draw_line(center + Vector2(-length - progress * 16.0, y), center + Vector2(length, y - 3.0), Color(0.05, 0.34, 0.38, alpha * 0.7), 5.0, true)
		draw_line(center + Vector2(-length - progress * 16.0, y), center + Vector2(length, y - 3.0), Color(0.58, 0.94, 0.62, alpha), 2.0, true)


func _draw_pickup_bomb(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var ring := radius * (0.12 + progress * 0.88)
	draw_circle(center, ring, Color(1.0, 0.4, 0.12, alpha * 0.14))
	draw_arc(center, ring, 0.0, TAU, 64, Color(0.25, 0.1, 0.17, alpha * 0.9), 8.0)
	draw_arc(center, ring, 0.0, TAU, 64, Color(1.0, 0.82, 0.36, alpha), 3.5)


func _draw_grub_trail(center: Vector2, radius: float, _progress: float, alpha: float, data: Dictionary) -> void:
	var direction: Vector2 = data.get("direction", Vector2.RIGHT)
	for index in range(4):
		var offset := -direction * index * radius * 0.5 + direction.orthogonal() * sin(index * 2.1) * 5.0
		draw_circle(center + offset, maxf(1.0, radius * (0.28 - index * 0.035)), Color(0.28, 0.42, 0.24, alpha * (0.5 - index * 0.08)))


func _draw_grub_recover(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	for index in range(3):
		var angle := progress * 3.0 + index * TAU / 3.0
		_draw_small_star(center + Vector2(0, -radius) + Vector2.from_angle(angle) * radius * 0.55, 5.0, Color(1.0, 0.88, 0.34, alpha), Color(0.16, 0.32, 0.22, alpha))


func _draw_bat_launch(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	for index in range(8):
		var direction := Vector2.from_angle(index * TAU / 8.0 + progress)
		draw_line(center + direction * radius * 0.2, center + direction * radius * (0.4 + progress), Color(0.37, 0.16, 0.5, alpha), 5.0, true)
		draw_line(center + direction * radius * 0.2, center + direction * radius * (0.4 + progress), Color(1.0, 0.58, 0.28, alpha), 2.0, true)


func _draw_bat_impact(center: Vector2, radius: float, progress: float, alpha: float, dissolve: bool) -> void:
	for index in range(7):
		var angle := index * TAU / 7.0 + progress * (1.2 if dissolve else -0.6)
		var point := center + Vector2.from_angle(angle) * radius * (0.2 + progress)
		draw_circle(point, maxf(1.0, 4.0 * alpha), Color(0.55, 0.34, 0.84, alpha * (0.65 if dissolve else 1.0)))
	draw_arc(center, radius * (0.35 + progress), 0.0, TAU, 28, Color(1.0, 0.56, 0.28, alpha * 0.72), 2.0)


func _draw_elite_burst(center: Vector2, radius: float, progress: float, alpha: float, defeated: bool) -> void:
	var ring := radius * (0.3 + progress * 0.9)
	draw_arc(center, ring, 0.0, TAU, 64, Color(0.05, 0.25, 0.3, alpha * 0.8), 8.0)
	draw_arc(center, ring, 0.0, TAU, 64, Color(1.0, 0.82, 0.34, alpha), 3.0)
	for index in range(8):
		var point := center + Vector2.from_angle(index * TAU / 8.0 + progress) * ring
		_draw_small_star(point, 5.0 + int(defeated) * 2.0, Color(1.0, 0.93, 0.62, alpha), Color(0.1, 0.3, 0.34, alpha))


func _draw_boss_appear(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var colors := [Color("77c8c2"), Color("f1c45b"), Color("e98d78"), Color("78b979"), Color("6679b9")]
	var ring := radius * (0.24 + progress * 0.86)
	for index in range(colors.size()):
		var start_angle := -PI * 0.5 + index * TAU / colors.size() + progress * 0.22
		var color: Color = colors[index]
		color.a = alpha
		draw_arc(center, ring, start_angle, start_angle + TAU / colors.size() - 0.08, 16, Color(0.06, 0.24, 0.28, alpha * 0.8), 8.0, true)
		draw_arc(center, ring, start_angle, start_angle + TAU / colors.size() - 0.08, 16, color, 3.2, true)
		var point := center + Vector2.from_angle(start_angle + TAU / colors.size() * 0.5) * ring
		_draw_small_star(point, 7.0, Color(color.r, color.g, color.b, alpha), Color(0.08, 0.27, 0.3, alpha))


func _draw_defeat(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	for index in range(9):
		var angle := index * TAU / 9.0 + index * 0.21
		var distance := radius * (0.3 + progress * (0.8 + index % 3 * 0.25))
		var fragment := center + Vector2.from_angle(angle) * distance + Vector2(0, progress * progress * 18.0)
		draw_circle(fragment, maxf(1.0, 5.0 * alpha), Color(color.r, color.g, color.b, alpha))
	draw_arc(center, radius * (0.4 + progress * 0.8), 0.0, TAU, 32, Color(0.03, 0.2, 0.26, alpha * 0.66), 4.5)


func _draw_grub_defeat(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	for index in range(8):
		var angle := index * TAU / 8.0 + 0.22
		var fragment := center + Vector2.from_angle(angle) * radius * (0.25 + progress)
		if index % 2 == 0:
			var leaf := PackedVector2Array([fragment + Vector2(-5, 0), fragment + Vector2(0, -8), fragment + Vector2(5, 0), fragment + Vector2(0, 5)])
			draw_colored_polygon(leaf, Color(0.48, 0.86, 0.29, alpha))
		else:
			_draw_small_star(fragment, 6.0, Color(1.0, 0.88, 0.34, alpha), Color(0.1, 0.31, 0.23, alpha))


func _draw_small_star(center: Vector2, radius: float, fill: Color, outline: Color) -> void:
	var points := PackedVector2Array()
	for point in range(10):
		points.append(center + Vector2.from_angle(point * TAU / 10.0 - PI * 0.5) * (radius if point % 2 == 0 else radius * 0.42))
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, outline, 1.4, true)
