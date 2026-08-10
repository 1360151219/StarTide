extends "res://scripts/presentation/combat_effect_draw_rewards.gd"

const GAME_FONT := preload("res://assets/fonts/NotoSansSC-Regular.otf")


func _draw_floating_text(effect: Dictionary, center: Vector2, progress: float, alpha: float) -> void:
	var is_player: bool = bool(effect["is_player"])
	var font_size := 27 if is_player else 20
	var position := center + Vector2(0, -28.0 - progress * (42.0 if is_player else 27.0))
	var color: Color = effect["color"]
	color.a = alpha
	var shadow := Color(0.015, 0.02, 0.06, alpha * 0.9)
	draw_string(GAME_FONT, position + Vector2(2, 2), effect["text"], HORIZONTAL_ALIGNMENT_CENTER, 54.0, font_size, shadow)
	draw_string(GAME_FONT, position, effect["text"], HORIZONTAL_ALIGNMENT_CENTER, 54.0, font_size, color)


func _draw_meteor_warning(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var visible_alpha := maxf(alpha, 0.58)
	var landing_radius := radius * (0.92 - progress * 0.08 + sin(progress * PI * 6.0) * 0.025)
	draw_circle(center, landing_radius, Color(1.0, 0.7, 0.24, 0.07 + progress * 0.05))
	var gap_half := PI * 0.19
	var arc_start := -PI * 0.5 + gap_half
	var arc_end := -PI * 0.5 - gap_half + TAU
	draw_arc(center, landing_radius, arc_start, arc_end, 48, Color(0.18, 0.11, 0.16, visible_alpha * 0.82), 6.0)
	draw_arc(center, landing_radius, arc_start, arc_end, 48, Color(1.0, 0.9, 0.56, visible_alpha), 2.6)
	for side in [-1.0, 1.0]:
		var edge_angle: float = -PI * 0.5 + side * gap_half
		var edge := center + Vector2.from_angle(edge_angle) * landing_radius
		var inward := Vector2.from_angle(edge_angle) * -1.0
		draw_line(edge, edge + inward * 13.0, Color(1.0, 0.82, 0.36, visible_alpha), 3.0, true)
	var fall_progress := progress * progress * (3.0 - 2.0 * progress)
	var meteor_position := center + Vector2(
		lerpf(-radius * 0.34, -radius * 0.06, fall_progress),
		lerpf(-radius * 1.48, -radius * 0.14, fall_progress)
	)
	var trail_direction := Vector2(-0.18, -1.0).normalized()
	draw_line(meteor_position, meteor_position + trail_direction * (28.0 + radius * 0.18), Color(0.23, 0.12, 0.17, visible_alpha * 0.74), 8.0, true)
	draw_line(meteor_position, meteor_position + trail_direction * (26.0 + radius * 0.16), Color(1.0, 0.68, 0.27, visible_alpha), 3.4, true)
	var meteor := PackedVector2Array([
		meteor_position + Vector2(0, 8),
		meteor_position + Vector2(7, 0),
		meteor_position + Vector2(0, -9),
		meteor_position + Vector2(-7, 0),
	])
	draw_colored_polygon(meteor, Color(1.0, 0.86, 0.48, visible_alpha))
	draw_polyline(PackedVector2Array([meteor[0], meteor[1], meteor[2], meteor[3], meteor[0]]), Color(0.25, 0.12, 0.17, visible_alpha), 2.0, true)


func _draw_meteor_impact(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var shock_radius := radius * (0.18 + progress * 0.82)
	draw_circle(center, radius * maxf(0.0, 0.28 - progress) * 1.8, Color(1.0, 0.96, 0.72, alpha * 0.92))
	draw_circle(center, shock_radius, Color(color.r, color.g, color.b, alpha * 0.1))
	var gap_half := PI * 0.15
	draw_arc(center, shock_radius, -PI * 0.5 + gap_half, -PI * 0.5 - gap_half + TAU, 46, Color(0.28, 0.12, 0.16, alpha * 0.84), 8.0)
	draw_arc(center, shock_radius, -PI * 0.5 + gap_half, -PI * 0.5 - gap_half + TAU, 46, Color(1.0, 0.68, 0.28, alpha), 3.6)
	draw_line(center - Vector2(0, radius * (1.18 - progress * 0.7)), center - Vector2(0, shock_radius * 0.14), Color(1.0, 0.9, 0.5, alpha * maxf(0.0, 1.0 - progress * 2.4)), 4.0, true)
	for index in range(7):
		var angle := lerpf(-PI * 0.92, PI * 0.92, float(index) / 6.0)
		var direction := Vector2.from_angle(angle)
		var start := center + direction * shock_radius * 0.28
		var end := center + direction * shock_radius * (0.72 + index % 3 * 0.1)
		draw_line(start, end, Color(1.0, 0.88, 0.48, alpha * 0.88), 2.8, true)
		draw_circle(end, 2.4 + index % 2, Color(0.42, 0.25, 0.2, alpha * 0.72))


func _draw_phoenix(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var spread := radius * (0.2 + progress * 0.8)
	var wing_color := Color(color.r, color.g, color.b, alpha * 0.5)
	var edge_color := Color(1.0, 0.9, 0.48, alpha)
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			center + Vector2(side * spread * 0.08, -spread * 0.17),
			center + Vector2(side * spread * 0.34, -spread * 0.46),
			center + Vector2(side * spread * 0.94, -spread * 0.2),
			center + Vector2(side * spread * 0.58, spread * 0.02),
			center + Vector2(side * spread * 0.88, spread * 0.34),
			center + Vector2(side * spread * 0.28, spread * 0.13),
			center + Vector2(side * spread * 0.04, spread * 0.3),
		])
		draw_colored_polygon(wing, wing_color)
		var wing_outline := PackedVector2Array(wing)
		wing_outline.append(wing[0])
		draw_polyline(wing_outline, Color(0.25, 0.11, 0.17, alpha * 0.84), 6.5, true)
		draw_polyline(wing_outline, edge_color, 2.8, true)
		var heart_edge := PackedVector2Array([
			center + Vector2(0, -spread * 0.17),
			center + Vector2(side * spread * 0.18, -spread * 0.32),
			center + Vector2(side * spread * 0.31, -spread * 0.11),
			center + Vector2(0, spread * 0.31),
		])
		draw_polyline(heart_edge, Color(0.25, 0.11, 0.17, alpha * 0.86), 7.0, true)
		draw_polyline(heart_edge, edge_color, 3.0, true)
		for feather in range(3):
			var feather_root := center + Vector2(side * spread * (0.3 + feather * 0.12), -spread * 0.04 + feather * spread * 0.08)
			draw_line(feather_root, feather_root + Vector2(side * spread * (0.22 + feather * 0.04), spread * 0.16), Color(1.0, 0.66, 0.24, alpha * (0.78 - feather * 0.12)), 2.6, true)


func _draw_phoenix_impact(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var spread := radius * (0.28 + progress * 0.72)
	for side in [-1.0, 1.0]:
		var sweep := PackedVector2Array([
			center + Vector2(0, -spread * 0.12),
			center + Vector2(side * spread * 0.28, -spread * 0.38),
			center + Vector2(side * spread * 0.92, -spread * 0.14),
			center + Vector2(side * spread * 0.52, spread * 0.08),
			center + Vector2(0, spread * 0.32),
		])
		draw_polyline(sweep, Color(0.28, 0.11, 0.18, alpha * 0.78), 8.0, true)
		draw_polyline(sweep, Color(1.0, 0.82, 0.34, alpha), 3.5, true)
	for index in range(8):
		var side := -1.0 if index % 2 == 0 else 1.0
		var feather := center + Vector2(side * spread * (0.28 + index * 0.07), lerpf(-spread * 0.2, spread * 0.32, float(index) / 7.0))
		draw_line(feather, feather + Vector2(side * (9.0 + index), 8.0 + index % 3 * 3.0), Color(1.0, 0.93, 0.62, alpha * 0.88), 2.8, true)


func _draw_frost_hit(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var direction := Vector2(0.82, -0.58)
	var tangent := direction.orthogonal()
	var length := radius * (0.45 + progress * 0.55)
	var width := maxf(5.0, radius * 0.18)
	var crystal := PackedVector2Array([
		center + direction * length,
		center + tangent * width,
		center - direction * length * 0.42,
		center - tangent * width,
	])
	draw_colored_polygon(crystal, Color(0.66, 0.96, 1.0, alpha * 0.34))
	draw_polyline(PackedVector2Array([crystal[0], crystal[1], crystal[2], crystal[3], crystal[0]]), Color(0.03, 0.27, 0.38, alpha * 0.84), 4.8, true)
	draw_line(center - direction * length * 0.18, center + direction * length, Color(0.82, 0.99, 1.0, alpha), 2.2, true)
	for index in range(3):
		var root := center + direction * length * (0.08 + index * 0.18)
		var side := -1.0 if index % 2 == 0 else 1.0
		var tip := root - direction * radius * 0.14 + tangent * side * radius * (0.22 + index * 0.05)
		draw_line(root, tip, Color(0.68, 0.94, 1.0, alpha * 0.9), 2.4, true)


func _draw_ember_bloom(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var bloom_radius := radius * (0.15 + progress * 0.85)
	draw_circle(center, bloom_radius, Color(color.r, color.g, color.b, alpha * 0.14))
	for index in range(8):
		var angle := index * TAU / 8.0 + progress * 0.8
		var inner := center + Vector2.from_angle(angle) * bloom_radius * 0.25
		var tip := center + Vector2.from_angle(angle) * bloom_radius
		draw_line(inner, tip, Color(0.25, 0.1, 0.17, alpha * 0.78), 7.0 - progress * 2.0, true)
		draw_line(inner, tip, Color(1.0, 0.42 + index % 2 * 0.2, 0.16, alpha), 3.5 - progress, true)


func _draw_star_hit(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var outer := radius * (0.25 + progress * 0.75)
	var points := PackedVector2Array()
	for index in range(16):
		var point_radius := outer if index % 2 == 0 else outer * 0.34
		points.append(center + Vector2.from_angle(index * TAU / 16.0 - PI * 0.5) * point_radius)
	points.append(points[0])
	draw_polyline(points, Color(0.02, 0.25, 0.34, alpha * 0.88), 6.0, true)
	draw_polyline(points, Color(color.r, color.g, color.b, alpha), 2.6, true)
	draw_circle(center, outer * 0.22, Color(0.86, 0.98, 1.0, alpha * 0.8))


func _draw_sun_hit(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var orbit_radius := radius * (0.38 + progress * 0.5)
	var rotation := progress * 1.1
	draw_arc(center, orbit_radius, rotation + PI * 0.18, rotation + PI * 1.28, 22, Color(0.25, 0.12, 0.16, alpha * 0.76), 5.0)
	draw_arc(center, orbit_radius, rotation + PI * 0.18, rotation + PI * 1.28, 22, Color(color.r, color.g, color.b, alpha), 2.2)
	for index in range(3):
		var angle := rotation + index * PI * 0.48
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal()
		var node_center := center + direction * orbit_radius
		var node := PackedVector2Array([
			node_center + direction * 6.0,
			node_center + tangent * 4.0,
			node_center - direction * 6.0,
			node_center - tangent * 4.0,
		])
		draw_colored_polygon(node, Color(1.0, 0.88, 0.36, alpha))
		draw_polyline(PackedVector2Array([node[0], node[1], node[2], node[3], node[0]]), Color(0.25, 0.12, 0.16, alpha * 0.8), 1.6, true)
