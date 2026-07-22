extends Node2D

const AbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const WARNING_FILL := Color(1.0, 0.39, 0.24, 0.22)
const WARNING_LINE := Color(1.0, 0.95, 0.82, 0.78)

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
		next_warnings.append({
			"shape": config["shape"], "source": state["enemy"].position,
			"direction": state["direction"], "target": state["target"],
			"length": config.get("distance", config.get("projectile_distance", config.get("length", 0.0))),
			"width": config.get("lane_width", 0.0), "radius": config.get("radius", 0.0),
			"half_angle": config.get("half_angle", 0.0),
		})
	set_warnings(next_warnings)


func _draw() -> void:
	for warning in warnings:
		match warning["shape"]:
			"lane":
				_draw_lane(warning)
			"circle":
				_draw_circle_warning(warning)
			"dashed_line":
				_draw_dashed_line(warning)
			"sector":
				_draw_sector(warning)


func _draw_lane(warning: Dictionary) -> void:
	var start: Vector2 = warning["source"]
	var direction: Vector2 = warning["direction"]
	var length: float = warning["length"]
	var half_width: float = float(warning["width"]) * 0.5
	var normal := direction.orthogonal() * half_width
	var finish := start + direction * length
	var points := PackedVector2Array([start + normal, finish + normal, finish - normal, start - normal])
	var fill := WARNING_FILL
	fill.a *= 0.82 + sin(animation_time * 9.0) * 0.18
	draw_colored_polygon(points, fill)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), WARNING_LINE, 2.0)
	var sweep := start + direction * fposmod(animation_time * 74.0, maxf(length, 1.0))
	draw_line(sweep - normal, sweep + normal, WARNING_LINE, 2.4)


func _draw_circle_warning(warning: Dictionary) -> void:
	var center: Vector2 = warning["target"]
	var radius: float = warning["radius"] * (0.97 + sin(animation_time * 9.0) * 0.03)
	draw_circle(center, radius, WARNING_FILL)
	draw_arc(center, radius, 0.0, TAU, 42, WARNING_LINE, 2.5)
	draw_circle(center, 4.0, WARNING_LINE)


func _draw_dashed_line(warning: Dictionary) -> void:
	var start: Vector2 = warning["source"]
	var direction: Vector2 = warning["direction"]
	var offset := fmod(animation_time * 42.0, 38.0)
	for index in range(12):
		var from := start + direction * (index * 38.0 + offset)
		var to := from + direction * 22.0
		draw_line(from, to, WARNING_LINE, 3.0, true)


func _draw_sector(warning: Dictionary) -> void:
	var center: Vector2 = warning["source"]
	var direction: Vector2 = warning["direction"]
	var length: float = warning["length"] * (0.97 + sin(animation_time * 8.0) * 0.03)
	var half_angle: float = warning["half_angle"]
	var points := PackedVector2Array([center])
	for index in range(13):
		var angle := direction.angle() - half_angle + half_angle * 2.0 * index / 12.0
		points.append(center + Vector2.from_angle(angle) * length)
	draw_colored_polygon(points, WARNING_FILL)
	var outline := points.duplicate()
	outline.append(center)
	draw_polyline(outline, WARNING_LINE, 2.5)
