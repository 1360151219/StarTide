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
	var pulse := 0.82 + sin(progress * PI * 7.0) * 0.08
	draw_circle(center, radius * pulse, Color(1.0, 0.7, 0.24, 0.08 + progress * 0.08))
	draw_arc(center, radius * pulse, 0.0, TAU, 56, Color(0.18, 0.11, 0.16, 0.72), 6.0)
	draw_arc(center, radius * pulse, 0.0, TAU, 56, Color(1.0, 0.9, 0.56, 0.86), 2.6)
	for index in range(4):
		var angle := progress * 1.8 + index * TAU / 4.0
		draw_circle(center + Vector2.from_angle(angle) * radius * 0.7, 3.0 + progress * 2.0, Color(1.0, 0.76, 0.3, alpha))


func _draw_meteor_impact(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var ring_radius := radius * (0.18 + progress * 0.82)
	draw_circle(center, radius * maxf(0.0, 0.32 - progress) * 1.6, Color(1.0, 0.96, 0.72, alpha * 0.9))
	draw_circle(center, ring_radius, Color(color.r, color.g, color.b, alpha * 0.12))
	draw_arc(center, ring_radius, 0.0, TAU, 56, Color(0.28, 0.12, 0.16, alpha * 0.82), 8.0)
	draw_arc(center, ring_radius, 0.0, TAU, 56, Color(1.0, 0.68, 0.28, alpha), 4.0)
	for index in range(9):
		var direction := Vector2.from_angle(index * TAU / 9.0 + 0.17)
		draw_line(center + direction * ring_radius * 0.28, center + direction * ring_radius * (0.74 + index % 3 * 0.1), Color(1.0, 0.88, 0.48, alpha * 0.9), 3.0, true)


func _draw_phoenix(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var spread := radius * (0.2 + progress * 0.8)
	var body_color := Color(1.0, 0.9, 0.48, alpha)
	var flame_color := Color(color.r, color.g, color.b, alpha * 0.74)
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			center + Vector2(0, -spread * 0.12),
			center + Vector2(side * spread * 0.35, -spread * 0.42),
			center + Vector2(side * spread * 0.9, -spread * 0.18),
			center + Vector2(side * spread * 0.48, spread * 0.04),
			center + Vector2(side * spread * 0.82, spread * 0.32),
		])
		draw_polyline(wing, Color(0.25, 0.11, 0.17, alpha * 0.8), 9.0, true)
		draw_polyline(wing, body_color, 5.0, true)
		for feather in range(3):
			var offset := spread * (0.18 + feather * 0.14)
			draw_arc(center + Vector2(side * offset, 0), spread * (0.34 + feather * 0.06), PI * 1.05 if side < 0 else -PI * 0.05, PI * 1.5 if side < 0 else PI * 0.45, 18, flame_color, 2.5)
	draw_circle(center + Vector2(0, -spread * 0.18), 7.0 + 5.0 * alpha, body_color)


func _draw_phoenix_impact(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var ring := radius * (0.28 + progress * 0.72)
	draw_circle(center, ring, Color(1.0, 0.48, 0.16, alpha * 0.11))
	draw_arc(center, ring, 0.0, TAU, 64, Color(0.28, 0.11, 0.18, alpha * 0.76), 7.0)
	draw_arc(center, ring, 0.0, TAU, 64, Color(1.0, 0.82, 0.34, alpha), 3.5)
	for index in range(10):
		var angle := index * TAU / 10.0 + progress
		var feather := center + Vector2.from_angle(angle) * ring * 0.72
		draw_line(feather, feather + Vector2.from_angle(angle - 0.45) * 12.0, Color(1.0, 0.93, 0.62, alpha), 3.0, true)


func _draw_frost_hit(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	draw_circle(center, radius * (0.3 + progress * 0.7), Color(0.42, 0.86, 1.0, alpha * 0.1))
	for index in range(6):
		var angle := index * TAU / 6.0 + progress * 0.35
		var inner := center + Vector2.from_angle(angle) * radius * 0.18
		var outer := center + Vector2.from_angle(angle) * radius * (0.55 + progress * 0.42)
		draw_line(inner, outer, Color(0.03, 0.27, 0.38, alpha * 0.78), 5.0, true)
		draw_line(inner, outer, Color(0.74, 0.98, 1.0, alpha), 2.4, true)


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
	var size := radius * (0.45 + progress * 0.55)
	draw_circle(center, size * 0.36, Color(1.0, 0.88, 0.36, alpha * 0.82))
	for index in range(10):
		var direction := Vector2.from_angle(index * TAU / 10.0 + progress)
		draw_line(center + direction * size * 0.45, center + direction * size, Color(0.25, 0.12, 0.16, alpha * 0.75), 5.0, true)
		draw_line(center + direction * size * 0.45, center + direction * size, Color(color.r, color.g, color.b, alpha), 2.2, true)
