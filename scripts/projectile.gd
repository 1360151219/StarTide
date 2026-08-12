extends Node2D

const UNLIMITED_PIERCE := -1

var velocity := Vector2.ZERO
var damage := 20.0
var radius := 7.0
var lifetime := 2.0
var pierce := 0
var blast_radius := 0.0
var trail_color := Color("56d9ef")
var core_color := Color("dffcff")
var outline_color := Color("07506a")
var visual_kind := "star_lance"
var source_id := "unknown"
var age := 0.0
var previous_position := Vector2.ZERO
var hit_ids: Dictionary = {}


func advance(delta: float) -> bool:
	previous_position = position
	age += delta
	position += velocity * delta
	rotation = velocity.angle()
	lifetime -= delta
	queue_redraw()
	return lifetime <= 0.0


func intersects_circle(center: Vector2, combined_radius: float) -> bool:
	var segment := position - previous_position
	var length_squared := segment.length_squared()
	var progress := 0.0
	if length_squared > 0.0001:
		progress = clampf((center - previous_position).dot(segment) / length_squared, 0.0, 1.0)
	var nearest_point := previous_position + segment * progress
	return nearest_point.distance_squared_to(center) <= combined_radius * combined_radius


func can_hit(enemy: Node) -> bool:
	return not hit_ids.has(enemy.get_instance_id())


func register_hit(enemy: Node) -> bool:
	hit_ids[enemy.get_instance_id()] = true
	if pierce == UNLIMITED_PIERCE:
		return false
	if pierce > 0:
		pierce -= 1
		return false
	return true


func _draw() -> void:
	if visual_kind == "ember_arrow":
		_draw_ember_arrow()
	else:
		_draw_star_lance()


func _draw_star_lance() -> void:
	var faint_trail := trail_color
	faint_trail.a = 0.12
	var bright_trail := trail_color
	bright_trail.a = 0.68
	draw_line(Vector2(-32, 0), Vector2(4, 0), Color(0.02, 0.2, 0.3, 0.72), radius * 1.18, true)
	for trail_index in range(3):
		var wave := sin(age * 24.0 + trail_index * TAU / 3.0) * (3.0 + trail_index)
		draw_line(Vector2(-38, wave), Vector2(-4, wave * 0.2), faint_trail, radius * (1.5 - trail_index * 0.22), true)
	draw_line(Vector2(-30, 0), Vector2(3, 0), bright_trail, radius * 0.8, true)
	var lance := PackedVector2Array([
		Vector2(15, 0), Vector2(1, -radius), Vector2(-10, 0), Vector2(1, radius)
	])
	draw_colored_polygon(lance, core_color)
	draw_polyline(PackedVector2Array([lance[0], lance[1], lance[2], lance[3], lance[0]]), outline_color, 2.0)
	for index in range(4):
		var angle := age * 5.0 + index * TAU / 4.0
		var rune := Vector2(-4, 0) + Vector2.from_angle(angle) * (radius + 4.0)
		draw_circle(rune, 1.8, Color(0.78, 0.96, 1.0, 0.8))
	draw_circle(Vector2(2, -2), radius * 0.28, Color.WHITE)


func _draw_ember_arrow() -> void:
	var flicker := 0.78 + sin(age * 31.0) * 0.18
	for index in range(4):
		var flame_length := 24.0 + index * 7.0
		var flame_offset := sin(age * 26.0 + index * 1.7) * (2.5 + index)
		var flame_color := trail_color
		flame_color.a = (0.48 - index * 0.07) * flicker
		draw_line(Vector2(-flame_length - 2.0, flame_offset), Vector2(-3, 0), Color(0.18, 0.07, 0.13, flame_color.a * 0.86), maxf(4.0, radius * (1.48 - index * 0.16)), true)
		draw_line(Vector2(-flame_length, flame_offset), Vector2(-3, 0), flame_color, maxf(2.0, radius * (1.15 - index * 0.18)), true)
	var arrow := PackedVector2Array([
		Vector2(17, 0), Vector2(3, -radius * 0.78), Vector2(6, -2),
		Vector2(-11, -2), Vector2(-11, 2), Vector2(6, 2), Vector2(3, radius * 0.78),
	])
	draw_colored_polygon(arrow, core_color)
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[3], arrow[4], arrow[5], arrow[6], arrow[0]]), outline_color, 2.0)
	draw_circle(Vector2(-5, 0), radius * 0.34, Color(1.0, 0.46, 0.13, 0.85))
