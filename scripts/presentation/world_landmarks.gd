extends Node2D

var map: MapConfig


func configure(map_config: MapConfig) -> void:
	map = map_config
	queue_redraw()


func _draw() -> void:
	if map == null:
		return
	_draw_expedition_road()
	match map.biome_id:
		"golden_oasis": _draw_oasis_landmarks()
		"crystal_volcano": _draw_volcano_landmarks()
		_: _draw_meadow_landmarks()


func _draw_expedition_road() -> void:
	var points := PackedVector2Array()
	var top := map.world_bounds.position.y - 80.0
	var bottom := map.world_bounds.end.y + 80.0
	var y := top
	while y <= bottom:
		var x := sin(y * 0.0027) * 165.0 + sin(y * 0.0061) * 46.0
		points.append(Vector2(x, y))
		y += 150.0
	var outer := Color("81734f", 0.16)
	var inner := Color("f1daa0", 0.22)
	if map.biome_id == "golden_oasis":
		outer = Color("9a6841", 0.2)
		inner = Color("ffe0a0", 0.2)
	elif map.biome_id == "crystal_volcano":
		outer = Color("382f3f", 0.28)
		inner = Color("7e6765", 0.18)
	draw_polyline(points, outer, 142.0, true)
	draw_polyline(points, inner, 92.0, true)
	for index in range(1, points.size() - 1, 2):
		draw_ellipse(points[index], 24.0, 12.0, Color(inner, inner.a * 0.75))


func _draw_meadow_landmarks() -> void:
	_draw_fence(Vector2(-250, -225), Vector2(1.0, 0.48), 5)
	_draw_fence(Vector2(205, 265), Vector2(-0.95, 0.52), 4)
	_draw_meadow_pool(Vector2(225, -235))
	_draw_sign(Vector2(-285, 105), Vector2.RIGHT)
	_draw_windmill_shadow(Vector2(-190, 365))
	for center in [Vector2(-270, -40), Vector2(270, 15), Vector2(-245, 280), Vector2(250, 350)]:
		_draw_flower_bush(center)


func _draw_oasis_landmarks() -> void:
	_draw_stream(Vector2(-255, -370), Vector2(210, 390))
	_draw_palm(Vector2(-245, -130), 1.2)
	_draw_palm(Vector2(255, 225), 0.95)
	_draw_fence(Vector2(-270, 250), Vector2(1.0, 0.3), 4)
	_draw_sign(Vector2(270, -250), Vector2.LEFT)
	for center in [Vector2(210, -90), Vector2(-220, 370), Vector2(275, 360)]:
		_draw_desert_cluster(center)


func _draw_volcano_landmarks() -> void:
	_draw_crystal_cluster(Vector2(-255, -180), 1.25)
	_draw_crystal_cluster(Vector2(245, 215), 0.95)
	_draw_crystal_cluster(Vector2(-225, 360), 0.8)
	_draw_fence(Vector2(-270, 120), Vector2(1.0, 0.25), 4)
	_draw_sign(Vector2(265, -260), Vector2.LEFT)
	for center in [Vector2(220, -70), Vector2(-240, 260)]:
		_draw_rock_cluster(center)


func _draw_fence(start: Vector2, direction: Vector2, count: int) -> void:
	var step := direction.normalized() * 54.0
	for index in range(count - 1):
		var from := start + step * index + Vector2(0, -10)
		var to := start + step * (index + 1) + Vector2(0, -10)
		draw_line(from, to, Color("8b653d", 0.82), 7.0, true)
		draw_line(from + Vector2(0, 13), to + Vector2(0, 13), Color("a77b46", 0.75), 5.0, true)
	for index in range(count):
		var post := start + step * index
		draw_line(post + Vector2(0, 17), post + Vector2(0, -24), Color("6d4b32"), 9.0, true)
		draw_line(post + Vector2(-2, -22), post + Vector2(-2, 13), Color("c09255", 0.72), 3.0, true)


func _draw_sign(at: Vector2, direction: Vector2) -> void:
	draw_line(at + Vector2(0, 22), at + Vector2(0, -26), Color("715038"), 8.0, true)
	var facing := 1.0 if direction.x >= 0.0 else -1.0
	var points := PackedVector2Array()
	for local in [Vector2(-28, -28), Vector2(22, -28), Vector2(42, -18), Vector2(22, -8), Vector2(-28, -8)]:
		points.append(at + Vector2(local.x * facing, local.y))
	draw_colored_polygon(points, Color("b48650", 0.9))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[0]]), Color("5e432f"), 2.0, true)


func _draw_meadow_pool(at: Vector2) -> void:
	draw_ellipse(at, 66.0, 31.0, Color("62c9ce", 0.32))
	draw_arc(at + Vector2(-9, -4), 39.0, 3.35, 5.65, 26, Color("d9fff0", 0.48), 3.0, true)


func _draw_windmill_shadow(at: Vector2) -> void:
	var shade := Color(0.05, 0.12, 0.08, 0.12)
	draw_line(at + Vector2(0, 110), at + Vector2(0, -70), shade, 18.0, true)
	for index in range(4):
		var direction := Vector2.from_angle(index * PI * 0.5 + 0.35)
		draw_line(at, at + direction * 110.0, shade, 24.0, true)


func _draw_flower_bush(at: Vector2) -> void:
	for index in range(9):
		var angle := index * 2.37
		var offset := Vector2(cos(angle) * (15 + index % 3 * 8), sin(angle) * (9 + index % 2 * 6))
		draw_circle(at + offset, 11.0 + index % 3 * 2.0, Color("3f8f4e", 0.72))
		if index % 2 == 0:
			draw_circle(at + offset + Vector2(3, -8), 3.0, Color("f7f1c5" if index % 4 else "7ebaf0"))


func _draw_stream(start: Vector2, end: Vector2) -> void:
	var points := PackedVector2Array()
	for index in range(11):
		var ratio := index / 10.0
		var point := start.lerp(end, ratio)
		point.x += sin(ratio * TAU * 1.5) * 55.0
		points.append(point)
	draw_polyline(points, Color("42c3c7", 0.38), 72.0, true)
	draw_polyline(points, Color("b8f4df", 0.26), 28.0, true)


func _draw_palm(at: Vector2, scale: float) -> void:
	draw_line(at + Vector2(0, 25) * scale, at + Vector2(3, -35) * scale, Color("8d613d", 0.9), 10.0 * scale, true)
	for angle in [-2.8, -2.2, -1.55, -0.9, -0.3]:
		draw_line(at + Vector2(3, -35) * scale, at + Vector2.from_angle(angle) * 48.0 * scale, Color("3f9660", 0.88), 12.0 * scale, true)


func _draw_desert_cluster(at: Vector2) -> void:
	for offset in [Vector2(-22, 4), Vector2(0, -8), Vector2(24, 6)]:
		draw_ellipse(at + offset, 18.0, 9.0, Color("cf8356", 0.75))


func _draw_crystal_cluster(at: Vector2, scale: float) -> void:
	for data in [[-22.0, 24.0], [0.0, 40.0], [24.0, 28.0]]:
		var center := at + Vector2(float(data[0]), 0) * scale
		var height := float(data[1]) * scale
		var points := PackedVector2Array([center + Vector2(-10, 12) * scale, center + Vector2(0, -height), center + Vector2(11, 12) * scale])
		draw_colored_polygon(points, Color("55d4d2", 0.82))
		draw_line(points[1], points[2], Color("c7fff1", 0.7), 2.0, true)


func _draw_rock_cluster(at: Vector2) -> void:
	for offset in [Vector2(-24, 7), Vector2(0, -6), Vector2(25, 8)]:
		draw_circle(at + offset, 17.0, Color("4f4148", 0.78))
