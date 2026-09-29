extends "res://scripts/presentation/combat_effect_draw_rewards.gd"

const ABILITY_INK := Color("3f1721")
const ABILITY_LIGHT := Color("fff6de")
const WIND_COLOR := Color("8fe1cf")
const BELL_COLOR := Color("f2be58")
const ZOUWU_COLORS := [Color("69c8c1"), Color("f1c45b"), Color("e98272"), Color("75b779"), Color("667bbb")]


func _draw_cloud_hart_sweep(center: Vector2, radius: float, progress: float, alpha: float, data: Dictionary) -> void:
	var direction := Vector2(data.get("direction", Vector2.RIGHT))
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var heading := direction.angle()
	var half_angle := deg_to_rad(float(data.get("arc_degrees", 110.0)) * 0.5)
	var strike := 1.0 - pow(1.0 - progress, 3.0)
	_draw_ability_arc(center, radius, heading - half_angle, heading + half_angle, ABILITY_LIGHT, alpha * (1.0 - smoothstep(0.1, 0.3, progress)), 8.0)
	for band in range(3):
		var band_radius := radius * (1.0 - band * 0.07 - strike * 0.14)
		var offset := (float(band) - 1.0) * 0.035
		_draw_ability_arc(center, band_radius, heading - half_angle + absf(offset) + strike * 0.22, heading + half_angle - absf(offset), WIND_COLOR, alpha * alpha * (1.0 - band * 0.17), (7.0 - band) * alpha)
	var fragment_travel := 1.0 - pow(1.0 - progress, 2.0)
	for index in range(5):
		var angle := heading - half_angle * 0.82 + half_angle * 1.64 * float(index) / 4.0
		var fragment_direction := Vector2.from_angle(angle)
		var point := center + fragment_direction * radius * lerpf(0.62, 0.94, fragment_travel)
		var tangent := fragment_direction.orthogonal()
		point += tangent * sin(progress * PI) * 9.0
		var leaf := PackedVector2Array([point + fragment_direction * 8.0, point + tangent * 3.0, point - fragment_direction * 6.0, point - tangent * 3.0])
		draw_colored_polygon(leaf, Color(WIND_COLOR, alpha * 0.78))
		draw_polyline(PackedVector2Array([leaf[0], leaf[1], leaf[2], leaf[3], leaf[0]]), Color(ABILITY_INK, alpha * 0.72), 1.5, true)


func _draw_bellfeather_impact(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var ring_radius := radius
	for segment in range(4):
		var start_angle := -PI * 0.5 + segment * TAU / 4.0 + 0.16
		_draw_ability_arc(center, ring_radius, start_angle + progress * 0.3, start_angle + TAU / 4.0 - 0.32, BELL_COLOR, alpha * alpha, 6.5 * alpha)
	var lift := 1.0 - pow(1.0 - progress, 2.0)
	for index in range(4):
		var direction := Vector2.from_angle(index * TAU / 4.0 + PI * 0.25)
		var point := center + direction * radius * lerpf(0.22, 0.82, lift) + Vector2(0, -sin(progress * PI) * 17.0)
		var tangent := direction.orthogonal()
		var feather := PackedVector2Array([point + direction * 9.0, point + tangent * 4.0, point - direction * 7.0, point - tangent * 2.0])
		draw_colored_polygon(feather, Color(ABILITY_LIGHT, alpha * 0.92))
		draw_polyline(PackedVector2Array([feather[0], feather[1], feather[2], feather[3], feather[0]]), Color(ABILITY_INK, alpha * 0.78), 1.6, true)
	draw_circle(center, radius * maxf(0.0, 0.16 - progress * 0.5), Color(ABILITY_LIGHT, alpha * 0.88))


func _draw_zouwu_dash_trail(center: Vector2, radius: float, progress: float, alpha: float, data: Dictionary) -> void:
	var direction := Vector2(data.get("direction", Vector2.RIGHT))
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var back := -direction
	var tangent := direction.orthogonal()
	var length := radius * lerpf(0.65, 3.2, smoothstep(0.0, 0.22, progress))
	for band in range(3):
		var side := float(band - 1)
		var points := PackedVector2Array([
			center + back * radius + tangent * side * radius * 0.2,
			center + back * length * 0.38 + tangent * side * radius * 0.36,
			center + back * length * 0.7 + tangent * (side * radius * 0.18 + sin(progress * TAU * 2.0 + band) * 3.0),
			center + back * length + tangent * side * radius * 0.3,
		])
		draw_polyline(points, Color(ABILITY_INK, alpha * 0.58), 6.0, true)
		draw_polyline(points, Color("dff8ed", alpha * (0.88 - band * 0.1)), 2.4, true)
	for index in range(ZOUWU_COLORS.size()):
		var start := center + back * length * (0.32 + index * 0.115) + tangent * (float(index) - 2.0) * 4.0
		var color: Color = ZOUWU_COLORS[index]
		draw_line(start, start + direction * radius * 0.72, Color(ABILITY_INK, alpha * 0.62), 6.0, true)
		draw_line(start, start + direction * radius * 0.68, Color(color, alpha * 0.9), 2.5, true)


func _draw_zouwu_tail_sweep(center: Vector2, radius: float, progress: float, alpha: float, data: Dictionary) -> void:
	var direction := Vector2(data.get("direction", Vector2.RIGHT))
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var span := deg_to_rad(float(data.get("arc_degrees", 270.0)))
	var base_angle := direction.angle() - span * 0.5
	var inner_radius := float(data.get("inner_radius", 70.0))
	var peak_alpha := alpha * (1.0 - smoothstep(0.08, 0.24, progress))
	for edge in [inner_radius, radius]:
		_draw_ability_arc(center, edge, base_angle, base_angle + span, ABILITY_LIGHT, peak_alpha, 6.0)
	var sweep := smoothstep(0.0, 0.34, progress)
	var head_angle := base_angle + 0.12 + (span - 0.24) * sweep
	var trail_span := span * 0.42
	var tail_start := maxf(base_angle, head_angle - trail_span)
	draw_arc(center, radius * 0.92, tail_start, head_angle, 48, Color(ABILITY_INK, alpha * 0.72), 14.0, true)
	draw_arc(center, radius * 0.92, tail_start, head_angle, 48, Color(ABILITY_LIGHT, alpha * 0.9), 5.5, true)
	_draw_ability_arc(center, radius * 0.78, maxf(base_angle, tail_start + 0.16), head_angle - 0.12, ABILITY_LIGHT, alpha * alpha * 0.34, 2.4)
	for index in range(ZOUWU_COLORS.size()):
		var start_angle := lerpf(tail_start, head_angle, float(index) / ZOUWU_COLORS.size())
		var end_angle := lerpf(tail_start, head_angle, float(index + 1) / ZOUWU_COLORS.size()) - 0.025
		var color: Color = ZOUWU_COLORS[index]
		_draw_ability_arc(center, radius * 0.92, start_angle, end_angle, color, alpha, 4.2)
	var head := center + Vector2.from_angle(head_angle) * radius * 0.92
	var radial := Vector2.from_angle(head_angle)
	var tangent := radial.orthogonal()
	var blade := PackedVector2Array([head + tangent * 22.0, head + radial * 10.0, head - tangent * 13.0, head - radial * 8.0])
	draw_colored_polygon(blade, Color(ABILITY_LIGHT, alpha * 0.94))
	draw_polyline(PackedVector2Array([blade[0], blade[1], blade[2], blade[3], blade[0]]), Color(ABILITY_INK, alpha * 0.76), 2.4, true)


func _draw_zouwu_mark_impact(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var burst := 1.0 - pow(1.0 - progress, 3.0)
	for index in range(ZOUWU_COLORS.size()):
		var angle := -PI * 0.5 + index * TAU / ZOUWU_COLORS.size()
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal()
		var point := center + direction * radius * lerpf(0.2, 0.86, burst) + tangent * sin(progress * PI) * 6.0
		var ribbon := PackedVector2Array([point + direction * 13.0, point + tangent * 6.0, point - direction * 9.0, point - tangent * 3.0])
		var color: Color = ZOUWU_COLORS[index]
		draw_colored_polygon(ribbon, Color(color, alpha * 0.9))
		draw_polyline(PackedVector2Array([ribbon[0], ribbon[1], ribbon[2], ribbon[3], ribbon[0]]), Color(ABILITY_INK, alpha * 0.76), 2.0, true)
		_draw_ability_arc(center, radius, angle - 0.42 + progress * 0.36, angle + 0.42, color, alpha * alpha * 0.82, 5.5 * alpha)
	draw_circle(center, radius * maxf(0.0, 0.14 - progress * 0.38), Color(ABILITY_LIGHT, alpha))


func _draw_ability_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, alpha: float, width: float) -> void:
	if end_angle <= start_angle:
		return
	draw_arc(center, radius, start_angle, end_angle, 36, Color(ABILITY_INK, alpha * 0.68), width, true)
	draw_arc(center, radius, start_angle, end_angle, 36, Color(color, alpha), maxf(1.8, width * 0.54), true)
