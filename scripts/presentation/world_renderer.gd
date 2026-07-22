extends Node2D

const EnvironmentMotes = preload("res://scripts/presentation/environment_motes.gd")

var map: MapConfig
var environment_motes: Node2D


func configure(map_config: MapConfig) -> void:
	map = map_config
	if is_instance_valid(environment_motes):
		environment_motes.queue_free()
	environment_motes = EnvironmentMotes.new()
	add_child(environment_motes)
	environment_motes.configure(map)
	queue_redraw()


func _draw() -> void:
	if map == null:
		return
	draw_rect(map.world_bounds.grow(32.0), map.background_color)
	draw_texture_rect(map.floor_texture, map.world_bounds, true, map.floor_tint)
	for index in range(14):
		var glow_position := Vector2(
			map.world_bounds.position.x + fposmod(float(index * 617 + 180), map.world_bounds.size.x),
			map.world_bounds.position.y + fposmod(float(index * 953 + 320), map.world_bounds.size.y)
		)
		draw_circle(glow_position, 105.0 + index % 4 * 24.0, map.glow_color)
	_draw_decorations()
	draw_rect(map.world_bounds, map.border_color, false, 8.0)


func _draw_decorations() -> void:
	var inset := map.world_bounds.grow(-72.0)
	for index in range(map.decoration_count):
		var position := Vector2(
			inset.position.x + fposmod(float(index * 701 + 113), inset.size.x),
			inset.position.y + fposmod(float(index * 997 + 337), inset.size.y)
		)
		if position.distance_to(map.player_start) < 190.0:
			position.x = clampf(position.x + 230.0, inset.position.x, inset.end.x)
		match map.biome_id:
			"golden_oasis":
				_draw_desert_decor(position, index % 8, index)
			"crystal_volcano":
				_draw_volcano_decor(position, index % 8, index)
			_:
				_draw_meadow_decor(position, index % 8, index)


func _draw_meadow_decor(at: Vector2, kind: int, variant: int) -> void:
	var green := Color("3e9e55")
	match kind:
		0:
			for offset in [Vector2(-6, 0), Vector2(0, -5), Vector2(6, 1)]:
				draw_circle(at + offset, 4.2, Color("ff9aa8") if variant % 2 == 0 else Color("85bdf2"))
			draw_circle(at, 2.2, Color("ffe47a"))
		1:
			draw_line(at + Vector2(0, 9), at + Vector2(0, -5), green, 2.0)
			for angle in range(0, 360, 60):
				draw_circle(at + Vector2.from_angle(deg_to_rad(angle)) * 6.0 + Vector2(0, -7), 2.2, Color("fff8d5"))
		2:
			_draw_oval(at, Vector2(24, 10), Color("79dce0", 0.7))
			draw_arc(at + Vector2(-3, -1), 13.0, 3.6, 5.7, 12, Color("ddfff1", 0.75), 2.0)
		3:
			for offset in [-7.0, 0.0, 7.0]:
				draw_line(at + Vector2(offset, 8), at + Vector2(offset * 0.55, -8), green, 2.4)
		4:
			for angle in range(0, 360, 90):
				draw_circle(at + Vector2.from_angle(deg_to_rad(angle)) * 5.0, 5.0, Color("79ce58"))
		5:
			_draw_oval(at, Vector2(13, 8), Color("d8ddae"))
			draw_arc(at, 8.0, 3.4, 5.7, 12, Color("f7f2cd"), 2.0)
		6:
			draw_line(at + Vector2(0, 10), at + Vector2(0, -8), green, 2.0)
			draw_circle(at + Vector2(0, -10), 7.0, Color("8a7de3"))
			draw_circle(at + Vector2(2, -8), 3.0, Color("d9d3ff"))
		7:
			draw_arc(at, 13.0, 0.2, 5.4, 18, Color("c9ef78", 0.72), 3.0)


func _draw_desert_decor(at: Vector2, kind: int, variant: int) -> void:
	match kind:
		0:
			draw_rect(Rect2(at + Vector2(-4, -16), Vector2(8, 29)), Color("49a66e"))
			draw_line(at + Vector2(-4, -5), at + Vector2(-13, -11), Color("49a66e"), 6.0)
			draw_line(at + Vector2(4, 2), at + Vector2(13, -5), Color("49a66e"), 6.0)
		1:
			_draw_oval(at, Vector2(25, 10), Color("5bcbd0", 0.78))
			_draw_oval(at + Vector2(-3, -2), Vector2(16, 5), Color("c6f4d5", 0.75))
		2:
			_draw_oval(at, Vector2(18, 10), Color("d48c59"))
			draw_line(at + Vector2(-10, -2), at + Vector2(8, 3), Color("f5b96d"), 2.0)
		3:
			draw_line(at + Vector2(0, 12), at + Vector2(0, -9), Color("8a7046"), 4.0)
			for angle in range(200, 341, 35):
				draw_line(at + Vector2(0, -8), at + Vector2.from_angle(deg_to_rad(angle)) * 14.0, Color("4fa36b"), 5.0)
		4:
			for angle in range(205, 336, 32):
				draw_line(at + Vector2(0, 5), at + Vector2.from_angle(deg_to_rad(angle)) * 12.0, Color("a0a853"), 2.3)
		5:
			_draw_star(at, 9.0, Color("ff9c6d" if variant % 2 == 0 else "72d7ca"))
		6:
			for offset in [Vector2(-10, 3), Vector2(0, -4), Vector2(11, 4)]:
				draw_circle(at + offset, 5.0, Color("e99563"))
		7:
			for offset in [Vector2(-7, 2), Vector2(0, -5), Vector2(8, 3)]:
				_draw_oval(at + offset, Vector2(6, 3), Color("58bd82"))


func _draw_volcano_decor(at: Vector2, kind: int, variant: int) -> void:
	match kind:
		0:
			for offset in [Vector2(-9, 4), Vector2(0, -10), Vector2(10, 3)]:
				draw_colored_polygon(PackedVector2Array([at + offset + Vector2(-5, 7), at + offset + Vector2(0, -8), at + offset + Vector2(6, 7)]), Color("62ded6"))
		1:
			draw_line(at + Vector2(-19, -8), at + Vector2(18, 9), Color("ffc65a", 0.9), 7.0)
			draw_line(at + Vector2(-18, -8), at + Vector2(17, 8), Color("fff08a", 0.8), 2.0)
		2:
			for radius in [4.0, 7.0, 10.0]:
				draw_arc(at + Vector2(radius * 0.7, -radius), radius, 0.0, TAU, 16, Color("d9fff0", 0.58), 2.0)
		3:
			for offset in [Vector2(-10, 3), Vector2(0, -4), Vector2(11, 4)]:
				draw_circle(at + offset, 7.0, Color("9d5c5d"))
		4:
			draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 8), at + Vector2(-2, -13), at + Vector2(8, -4), at + Vector2(5, 9)]), Color("65d9d0"))
		5:
			_draw_star(at, 11.0, Color("ffe174", 0.82))
		6:
			draw_arc(at, 15.0, 0.0, 1.8, 12, Color("f7ad78"), 2.4)
			draw_line(at, at + Vector2(-12, -6), Color("f7ad78"), 2.4)
			draw_line(at, at + Vector2(4, 13), Color("f7ad78"), 2.4)
		7:
			for angle in range(210, 331, 30):
				draw_line(at + Vector2(0, 7), at + Vector2.from_angle(deg_to_rad(angle)) * 14.0, Color("62d5bd"), 3.5)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(20):
		var angle := index * TAU / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(10):
		var angle := -PI * 0.5 + index * PI / 5.0
		var point_radius := radius if index % 2 == 0 else radius * 0.45
		points.append(center + Vector2.from_angle(angle) * point_radius)
	draw_colored_polygon(points, color)
