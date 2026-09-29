extends Node2D

const AbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const WARNING_FILL := Color(0.894, 0.357, 0.357, 0.14)
const WARNING_INNER := Color(1.0, 0.96, 0.84, 0.94)
const WARNING_OUTER := Color(0.25, 0.09, 0.14, 0.9)
const WARNING_DANGER := Color(0.894, 0.357, 0.357, 0.96)

var warnings: Array[Dictionary] = []
var animation_time := 0.0


func _init() -> void:
	z_as_relative = false
	z_index = 3920


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
			"locked": str(config["runtime_kind"]) != "bolt" or float(state["phase_left"]) <= lock_time,
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
	fill.a = 0.1 + progress * 0.08
	draw_colored_polygon(points, fill)
	var outline := PackedVector2Array([points[0], points[1], points[2], points[3], points[0]])
	draw_polyline(outline, WARNING_OUTER, 6.0, true)
	draw_polyline(outline, WARNING_DANGER, 2.2, true)
	for index in range(3):
		var sweep := start + direction * length * (0.2 + index * 0.3)
		var chevron := PackedVector2Array([sweep - direction * 9.0 + normal * 0.58, sweep + direction * 5.0, sweep - direction * 9.0 - normal * 0.58])
		draw_polyline(chevron, WARNING_OUTER, 5.0, true)
		draw_polyline(chevron, Color(WARNING_INNER, 0.3 + smoothstep(index * 0.28, index * 0.28 + 0.3, progress) * 0.65), 2.0, true)
	var countdown := start + direction * length * progress
	draw_line(countdown - normal * 0.9, countdown + normal * 0.9, WARNING_OUTER, 5.0, true)
	draw_line(countdown - normal * 0.9, countdown + normal * 0.9, WARNING_INNER, 2.0, true)
	if bool(warning.get("locked", false)):
		_draw_lock_notch(finish, direction, 8.0)


func _draw_dashed_line(warning: Dictionary) -> void:
	var start: Vector2 = warning["source"]
	var direction: Vector2 = warning["direction"]
	var progress: float = warning.get("progress", 0.0)
	var length: float = warning["length"]
	var offset := fposmod(progress * 76.0, 38.0) if not bool(warning.get("locked", false)) else 0.0
	var finish: Vector2 = start + direction * length
	draw_line(start, finish, Color(WARNING_DANGER, 0.34), 3.0, true)
	for segment in warning_dash_segments(length, offset):
		var from := start + direction * segment.x
		var to := start + direction * segment.y
		draw_line(from, to, WARNING_OUTER, 7.0, true)
		draw_line(from, to, WARNING_DANGER, 3.4, true)
		draw_line(from, to, WARNING_INNER, 1.2, true)
	if bool(warning.get("locked", false)):
		_draw_lock_notch(finish, direction, 8.0)
	_draw_lock_notch(start + direction * length * progress, direction, 5.0)


static func warning_dash_segments(length: float, offset: float) -> Array[Vector2]:
	var segments: Array[Vector2] = []
	for index in range(-1, ceili(length / 38.0)):
		var from := maxf(0.0, index * 38.0 + offset)
		var to := minf(length, index * 38.0 + offset + 22.0)
		if to > from: segments.append(Vector2(from, to))
	return segments


func _draw_circle_warning(warning: Dictionary) -> void:
	var center: Vector2 = warning.get("target", warning["source"])
	var radius: float = warning["radius"]
	var progress: float = warning.get("progress", 0.0)
	var fill := WARNING_FILL
	fill.a = 0.1 + progress * 0.08
	draw_circle(center, radius, fill)
	for segment in range(4):
		var start_angle := segment * TAU / 4.0 + 0.14
		draw_arc(center, radius, start_angle, start_angle + TAU / 4.0 - 0.28, 15, WARNING_OUTER, 6.0, true)
		draw_arc(center, radius, start_angle, start_angle + TAU / 4.0 - 0.28, 15, WARNING_DANGER, 2.2, true)
		var direction := Vector2.from_angle(start_angle + TAU / 8.0 - 0.14)
		draw_line(center + direction * radius, center + direction * (radius - 12.0), WARNING_INNER, 2.3, true)
	var lock_radius := radius * lerpf(0.72, 0.16, smoothstep(0.0, 1.0, progress))
	draw_arc(center, lock_radius, 0.0, TAU, 32, Color(WARNING_INNER, 0.72), 2.0, true)
	if progress > 0.0:
		draw_arc(center, radius - 4.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, WARNING_INNER, 1.6, true)
	if bool(warning.get("locked", false)):
		_draw_lock_notch(center, Vector2.UP, 5.0)


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
	var progress: float = warning.get("progress", 0.0)
	fill.a = 0.1 + progress * 0.08
	draw_colored_polygon(points, fill)
	_draw_sector_edge(source, center_angle, half_angle, inner_radius, outer_radius, segments)
	var sweep_radius := lerpf(outer_radius, inner_radius + 6.0, progress)
	draw_arc(source, sweep_radius, center_angle - half_angle, center_angle + half_angle, segments, Color(WARNING_INNER, 0.66), 2.0, true)
	for side in [-1.0, 1.0]:
		var radial := Vector2.from_angle(center_angle + side * half_angle)
		var point := source + radial * lerpf(inner_radius, outer_radius, progress)
		draw_line(point - radial.orthogonal() * 4.0, point + radial.orthogonal() * 4.0, WARNING_INNER, 2.0, true)


func _draw_sector_edge(source: Vector2, center_angle: float, half_angle: float, inner_radius: float, outer_radius: float, segments: int) -> void:
	for color_width in [[WARNING_OUTER, 7.0], [WARNING_DANGER, 2.8]]:
		var color: Color = color_width[0]
		var width: float = color_width[1]
		draw_arc(source, outer_radius, center_angle - half_angle, center_angle + half_angle, segments, color, width, true)
		if inner_radius > 0.0:
			draw_arc(source, inner_radius, center_angle - half_angle, center_angle + half_angle, segments, color, width, true)
		for angle in [center_angle - half_angle, center_angle + half_angle]:
			draw_line(source + Vector2.from_angle(angle) * inner_radius, source + Vector2.from_angle(angle) * outer_radius, color, width, true)


func _draw_lock_notch(center: Vector2, direction: Vector2, size: float) -> void:
	var tangent := direction.orthogonal()
	var points := PackedVector2Array([center + direction * size, center + tangent * size * 0.62, center - direction * size, center - tangent * size * 0.62, center + direction * size])
	draw_polyline(points, WARNING_OUTER, 5.0, true)
	draw_polyline(points, WARNING_INNER, 2.0, true)
