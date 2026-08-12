extends Node2D

const AbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const WARNING_FILL := Color(0.941, 0.361, 0.361, 0.22)
const WARNING_INNER := Color(1.0, 0.96, 0.84, 0.94)
const WARNING_OUTER := Color(0.25, 0.09, 0.14, 0.9)

var warnings: Array[Dictionary] = []
var animation_time := 0.0


func advance(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func set_warnings(next_warnings: Array[Dictionary]) -> void:
	warnings = next_warnings
	queue_redraw()


func clear_warnings() -> void:
	warnings.clear()
	queue_redraw()


func set_locked_warning(source: Vector2, config: Dictionary, state: Dictionary) -> void:
	var next_warnings: Array[Dictionary] = [{
		"shape": config["shape"], "source": source, "direction": state["direction"],
		"target": state["target"], "length": config.get("distance", 0.0),
		"width": config.get("lane_width", 0.0), "radius": config.get("radius", 0.0),
		"inner_radius": config.get("inner_radius", 0.0), "outer_radius": config.get("outer_radius", 0.0),
		"arc_degrees": config.get("arc_degrees", 0.0),
		"progress": clampf(1.0 - float(state["phase_left"]) / maxf(float(config["warning"]), 0.001), 0.0, 1.0),
		"locked": true,
	}]
	set_warnings(next_warnings)


func set_states(states: Dictionary) -> void:
	var next_warnings: Array[Dictionary] = []
	for state in states.values():
		if state["phase"] != "warning" or not is_instance_valid(state["enemy"]):
			continue
		var config := AbilityCatalog.ability(state["ability_id"])
		var warning_duration := maxf(float(config["warning"]), 0.001)
		var progress := clampf(1.0 - float(state["phase_left"]) / warning_duration, 0.0, 1.0)
		var lock_time := float(config.get("lock_time", 0.2))
		next_warnings.append({
			"shape": config["shape"], "source": state["enemy"].position,
			"direction": state["direction"],
			"target": state.get("target", Vector2.INF),
			"length": config.get("distance", config.get("projectile_distance", config.get("length", 0.0))),
			"width": config.get("lane_width", 0.0), "radius": config.get("radius", 0.0),
			"inner_radius": config.get("inner_radius", 0.0), "outer_radius": config.get("outer_radius", 0.0),
			"arc_degrees": config.get("arc_degrees", 0.0),
			"progress": progress,
			"locked": float(state["phase_left"]) <= lock_time,
		})
	set_warnings(next_warnings)


func _draw() -> void:
	for warning in warnings:
		match warning["shape"]:
			"lane":
				_draw_lane(warning)
			"dashed_line":
				_draw_dashed_line(warning)
			"circle":
				_draw_circle_warning(warning)
			"sector":
				_draw_sector(warning, false)
			"annular_sector":
				_draw_sector(warning, true)


func _draw_lane(warning: Dictionary) -> void:
	var start: Vector2 = warning["source"]
	var direction: Vector2 = warning["direction"]
	var length: float = warning["length"]
	var half_width: float = float(warning["width"]) * 0.5
	var normal := direction.orthogonal() * half_width
	var finish := start + direction * length
	var points := PackedVector2Array([start + normal, finish + normal, finish - normal, start - normal])
	var fill := WARNING_FILL
	var progress: float = warning.get("progress", 0.0)
	fill.a = clampf(0.18 + progress * 0.06 + sin(animation_time * lerpf(7.0, 13.0, progress)) * 0.015, 0.18, 0.26)
	draw_colored_polygon(points, fill)
	var outline := PackedVector2Array([points[0], points[1], points[2], points[3], points[0]])
	draw_polyline(outline, WARNING_OUTER, 7.0, true)
	draw_polyline(outline, WARNING_INNER, 2.8, true)
	var sweep_speed := lerpf(58.0, 154.0, progress * progress)
	var sweep := start + direction * fposmod(animation_time * sweep_speed, maxf(length, 1.0))
	draw_line(sweep - normal, sweep + normal, WARNING_OUTER, 6.0, true)
	draw_line(sweep - normal, sweep + normal, WARNING_INNER, 2.4, true)
	if bool(warning.get("locked", false)):
		draw_circle(finish, 8.0 + sin(animation_time * 18.0) * 1.5, WARNING_OUTER)
		draw_circle(finish, 4.2, WARNING_INNER)


func _draw_dashed_line(warning: Dictionary) -> void:
	var start: Vector2 = warning["source"]
	var direction: Vector2 = warning["direction"]
	var progress: float = warning.get("progress", 0.0)
	var offset := fmod(animation_time * lerpf(34.0, 88.0, progress * progress), 38.0)
	var finish: Vector2 = start + direction * float(warning["length"])
	draw_line(start, finish, Color(WARNING_OUTER, 0.44), 6.0, true)
	for index in range(12):
		var from := start + direction * (index * 38.0 + offset)
		var to := from + direction * 22.0
		draw_line(from, to, WARNING_OUTER, 7.0, true)
		draw_line(from, to, WARNING_INNER, 2.8, true)
	if bool(warning.get("locked", false)):
		draw_circle(finish, 9.0 + sin(animation_time * 18.0) * 1.8, WARNING_OUTER)
		draw_circle(finish, 4.5, WARNING_INNER)


func _draw_circle_warning(warning: Dictionary) -> void:
	var center: Vector2 = warning.get("target", warning["source"])
	var radius: float = warning["radius"]
	var progress: float = warning.get("progress", 0.0)
	var fill := WARNING_FILL
	fill.a = 0.18 + progress * 0.07
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 64, WARNING_OUTER, 7.0, true)
	draw_arc(center, radius, 0.0, TAU, 64, WARNING_INNER, 2.8, true)
	var sweep_radius := radius * fposmod(animation_time * lerpf(0.42, 0.85, progress), 1.0)
	draw_arc(center, sweep_radius, 0.0, TAU, 48, Color(WARNING_INNER, 0.76), 2.0, true)


func _draw_sector(warning: Dictionary, annular: bool) -> void:
	var source: Vector2 = warning["source"]
	var direction: Vector2 = warning["direction"]
	var outer_radius: float = warning["outer_radius"] if annular else warning["radius"]
	var inner_radius: float = warning["inner_radius"] if annular else 0.0
	var half_angle := deg_to_rad(float(warning["arc_degrees"]) * 0.5)
	var center_angle := direction.angle()
	var segments := maxi(18, ceili(float(warning["arc_degrees"]) / 6.0))
	var points := PackedVector2Array()
	for index in range(segments + 1):
		var angle := center_angle - half_angle + half_angle * 2.0 * index / segments
		points.append(source + Vector2.from_angle(angle) * outer_radius)
	if annular:
		for index in range(segments, -1, -1):
			var angle := center_angle - half_angle + half_angle * 2.0 * index / segments
			points.append(source + Vector2.from_angle(angle) * inner_radius)
	else:
		points.append(source)
	var fill := WARNING_FILL
	fill.a = 0.18 + float(warning.get("progress", 0.0)) * 0.07
	draw_colored_polygon(points, fill)
	_draw_sector_edge(source, center_angle, half_angle, inner_radius, outer_radius, segments)


func _draw_sector_edge(source: Vector2, center_angle: float, half_angle: float, inner_radius: float, outer_radius: float, segments: int) -> void:
	for color_width in [[WARNING_OUTER, 7.0], [WARNING_INNER, 2.8]]:
		var color: Color = color_width[0]
		var width: float = color_width[1]
		draw_arc(source, outer_radius, center_angle - half_angle, center_angle + half_angle, segments, color, width, true)
		if inner_radius > 0.0:
			draw_arc(source, inner_radius, center_angle - half_angle, center_angle + half_angle, segments, color, width, true)
		for angle in [center_angle - half_angle, center_angle + half_angle]:
			draw_line(source + Vector2.from_angle(angle) * inner_radius, source + Vector2.from_angle(angle) * outer_radius, color, width, true)
