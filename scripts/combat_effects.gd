extends Node2D

const GAME_FONT := preload("res://assets/fonts/NotoSansSC-Regular.otf")

var effects: Array = []


func add_effect(center: Vector2, radius: float, color: Color, duration: float, kind: String) -> void:
	effects.append({
		"position": center,
		"radius": radius,
		"color": color,
		"duration": duration,
		"time": duration,
		"kind": kind,
	})
	queue_redraw()


func add_damage_number(center: Vector2, amount: float, color: Color, is_player := false) -> void:
	effects.append({
		"position": center,
		"radius": 0.0,
		"color": color,
		"duration": 0.62 if is_player else 0.46,
		"time": 0.62 if is_player else 0.46,
		"kind": "damage_text",
		"text": "-%d" % roundi(amount) if is_player else "%d" % roundi(amount),
		"is_player": is_player,
	})
	queue_redraw()


func advance(delta: float) -> void:
	for effect in effects.duplicate():
		effect["time"] -= delta
		if effect["time"] <= 0.0:
			effects.erase(effect)
	queue_redraw()


func _draw() -> void:
	for effect in effects:
		var progress: float = 1.0 - effect["time"] / effect["duration"]
		var alpha: float = 1.0 - progress
		var color: Color = effect["color"]
		var center: Vector2 = effect["position"]
		var radius: float = effect["radius"]
		match effect["kind"]:
			"damage_text":
				_draw_damage_text(effect, progress, alpha)
			"meteor":
				_draw_meteor(center, radius, progress, alpha, color)
			"phoenix":
				_draw_phoenix(center, radius, progress, alpha, color)
			"ember":
				_draw_ember_bloom(center, radius, progress, alpha, color)
			"star_hit":
				_draw_star_hit(center, radius, progress, alpha, color)
			"sun_hit":
				_draw_sun_hit(center, radius, progress, alpha, color)
			"defeat":
				_draw_defeat(center, radius, progress, alpha, color)


func _draw_damage_text(effect: Dictionary, progress: float, alpha: float) -> void:
	var is_player: bool = effect["is_player"]
	var font_size := 27 if is_player else 20
	var position: Vector2 = effect["position"] + Vector2(0, -28.0 - progress * (42.0 if is_player else 27.0))
	var color: Color = effect["color"]
	color.a = alpha
	var shadow := Color(0.015, 0.02, 0.06, alpha * 0.9)
	draw_string(GAME_FONT, position + Vector2(2, 2), effect["text"], HORIZONTAL_ALIGNMENT_CENTER, 54.0, font_size, shadow)
	draw_string(GAME_FONT, position, effect["text"], HORIZONTAL_ALIGNMENT_CENTER, 54.0, font_size, color)


func _draw_meteor(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var impact_progress := clampf(progress / 0.38, 0.0, 1.0)
	var fall_position := center + Vector2(78.0, -260.0).lerp(Vector2.ZERO, impact_progress)
	if progress < 0.45:
		draw_line(fall_position - Vector2(64, -120), fall_position, Color(1.0, 0.35, 0.12, alpha * 0.32), 24.0, true)
		draw_line(fall_position - Vector2(38, -76), fall_position, Color(1.0, 0.86, 0.42, alpha), 9.0, true)
		draw_circle(fall_position, 10.0 + radius * 0.035, Color(1.0, 0.88, 0.48, alpha * 0.9))
	var ring_progress := clampf((progress - 0.25) / 0.75, 0.0, 1.0)
	var ring_radius := radius * (0.18 + ring_progress * 0.82)
	draw_circle(center, ring_radius, Color(color.r, color.g, color.b, alpha * 0.14))
	draw_arc(center, ring_radius, 0.0, TAU, 56, Color(color.r, color.g, color.b, alpha * 0.9), 7.0)
	for index in range(10):
		var angle := index * TAU / 10.0 + 0.17
		var start := center + Vector2.from_angle(angle) * ring_radius * 0.35
		var finish := center + Vector2.from_angle(angle) * ring_radius * (0.75 + index % 3 * 0.12)
		draw_line(start, finish, Color(1.0, 0.68, 0.28, alpha * 0.8), 3.0, true)


func _draw_phoenix(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var spread := radius * (0.25 + progress * 0.75)
	var body_color := Color(1.0, 0.88, 0.42, alpha)
	var flame_color := Color(color.r, color.g, color.b, alpha * 0.8)
	draw_arc(center, spread, 0.0, TAU, 64, flame_color, 8.0)
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			center + Vector2(0, -spread * 0.12),
			center + Vector2(side * spread * 0.35, -spread * 0.42),
			center + Vector2(side * spread * 0.9, -spread * 0.18),
			center + Vector2(side * spread * 0.48, spread * 0.04),
			center + Vector2(side * spread * 0.82, spread * 0.32),
		])
		draw_polyline(wing, body_color, 6.0, true)
		for feather in range(3):
			var offset := spread * (0.18 + feather * 0.14)
			draw_arc(center + Vector2(side * offset, 0), spread * (0.34 + feather * 0.06), PI * 1.05 if side < 0 else -PI * 0.05, PI * 1.5 if side < 0 else PI * 0.45, 18, flame_color, 2.5)
	draw_circle(center + Vector2(0, -spread * 0.18), 7.0 + 5.0 * alpha, body_color)
	draw_line(center + Vector2(0, -spread * 0.08), center + Vector2(0, spread * 0.45), body_color, 5.0, true)


func _draw_ember_bloom(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var bloom_radius := radius * (0.15 + progress * 0.85)
	draw_circle(center, bloom_radius, Color(color.r, color.g, color.b, alpha * 0.16))
	for index in range(8):
		var angle := index * TAU / 8.0 + progress * 0.8
		var inner := center + Vector2.from_angle(angle) * bloom_radius * 0.25
		var tip := center + Vector2.from_angle(angle) * bloom_radius
		draw_line(inner, tip, Color(1.0, 0.42 + index % 2 * 0.2, 0.16, alpha), 5.0 - progress * 2.0, true)
		draw_circle(tip, 3.5 * alpha, Color(1.0, 0.92, 0.58, alpha))
	draw_arc(center, bloom_radius * 0.72, -progress * PI, TAU - progress * PI, 36, Color(1.0, 0.82, 0.36, alpha), 3.0)


func _draw_star_hit(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var outer := radius * (0.25 + progress * 0.75)
	var points := PackedVector2Array()
	for index in range(16):
		var point_radius := outer if index % 2 == 0 else outer * 0.34
		points.append(center + Vector2.from_angle(index * TAU / 16.0 - PI * 0.5) * point_radius)
	points.append(points[0])
	draw_polyline(points, Color(color.r, color.g, color.b, alpha), 3.0, true)
	draw_circle(center, outer * 0.22, Color(0.86, 0.98, 1.0, alpha * 0.8))


func _draw_sun_hit(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	var size := radius * (0.45 + progress * 0.55)
	draw_circle(center, size * 0.36, Color(1.0, 0.88, 0.36, alpha * 0.82))
	for index in range(12):
		var direction := Vector2.from_angle(index * TAU / 12.0 + progress)
		draw_line(center + direction * size * 0.45, center + direction * size, Color(color.r, color.g, color.b, alpha), 2.5, true)


func _draw_defeat(center: Vector2, radius: float, progress: float, alpha: float, color: Color) -> void:
	for index in range(9):
		var angle := index * TAU / 9.0 + index * 0.21
		var distance := radius * (0.3 + progress * (0.8 + index % 3 * 0.25))
		var fragment := center + Vector2.from_angle(angle) * distance + Vector2(0, progress * progress * 18.0)
		draw_circle(fragment, maxf(1.0, 5.0 * alpha), Color(color.r, color.g, color.b, alpha))
	draw_arc(center, radius * (0.4 + progress * 0.8), 0.0, TAU, 32, Color(color.r, color.g, color.b, alpha * 0.55), 2.5)
