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
			"length": config.get("distance", config.get("projectile_distance", config.get("length", 0.0))),
			"width": config.get("lane_width", 0.0), "radius": config.get("radius", 0.0),
			"half_angle": config.get("half_angle", 0.0),
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
