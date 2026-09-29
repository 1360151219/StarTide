extends Node2D

var source: Node
var velocity := Vector2.ZERO
var damage := 0.0
var hit_type := "enemy_projectile"
var radius := 11.0
var max_distance := 520.0
var traveled := 0.0
var previous_position := Vector2.ZERO
var age := 0.0


func advance(delta: float) -> bool:
	previous_position = position
	age += delta
	var movement := velocity * delta
	position += movement
	traveled += movement.length()
	rotation = velocity.angle()
	queue_redraw()
	return traveled >= max_distance


func intersects_circle(center: Vector2, combined_radius: float) -> bool:
	var segment := position - previous_position
	var length_squared := segment.length_squared()
	var progress := 0.0
	if length_squared > 0.0001:
		progress = clampf((center - previous_position).dot(segment) / length_squared, 0.0, 1.0)
	var nearest := previous_position + segment * progress
	return nearest.distance_squared_to(center) <= combined_radius * combined_radius


func _draw() -> void:
	var flutter := sin(age * 22.0) * 2.0
	var wake := clampf(traveled / 42.0, 0.0, 1.0)
	for index in range(3):
		var y := (float(index) - 1.0) * 5.0 + flutter * (1.0 - index * 0.25)
		draw_line(Vector2((-34.0 - index * 5.0) * wake, y), Vector2(-8.0, y * 0.25), Color(0.18, 0.06, 0.24, (0.54 - index * 0.1) * wake), 5.0 - index, true)
		draw_line(Vector2((-32.0 - index * 5.0) * wake, y), Vector2(-8.0, y * 0.25), Color(0.57, 0.32, 0.82, (0.58 - index * 0.1) * wake), 2.0, true)
	var spread := radius * (1.05 + sin(age * 22.0) * 0.2)
	var wings := PackedVector2Array([Vector2(-4, 0), Vector2(-16, -spread), Vector2(2, -radius * 0.56), Vector2(10, 0), Vector2(2, radius * 0.56), Vector2(-16, spread)])
	draw_colored_polygon(wings, Color("733fa9"))
	draw_polyline(PackedVector2Array([wings[0], wings[1], wings[2], wings[3], wings[4], wings[5], wings[0]]), Color("32143d"), 2.6, true)
	var core := PackedVector2Array([Vector2(radius * 1.45, 0), Vector2(0, -radius * 0.55), Vector2(-radius * 0.72, 0), Vector2(0, radius * 0.55)])
	draw_colored_polygon(core, Color("f08a48"))
	draw_polyline(PackedVector2Array([core[0], core[1], core[2], core[3], core[0]]), Color("32143d"), 2.4, true)
	draw_line(Vector2(-2, 0), Vector2(radius * 0.94, 0), Color("fff3cf"), 2.0, true)
