extends Node2D

var source: Node
var velocity := Vector2.ZERO
var damage := 0.0
var hit_type := "enemy_projectile"
var hit_cue := ""
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
	var pulse := 1.0 + sin(age * 16.0) * 0.08
	draw_line(Vector2(-30, 0), Vector2(-5, 0), Color(0.13, 0.06, 0.2, 0.58), radius * 1.65, true)
	draw_line(Vector2(-30, 0), Vector2(-5, 0), Color(0.55, 0.25, 0.85, 0.46), radius * 1.0, true)
	draw_circle(Vector2.ZERO, radius * 1.58 * pulse, Color(0.13, 0.06, 0.2, 0.86))
	draw_circle(Vector2.ZERO, radius * 1.35 * pulse, Color(1.0, 0.5, 0.24, 0.42))
	draw_circle(Vector2.ZERO, radius * pulse, Color("8d55d9"))
	draw_arc(Vector2.ZERO, radius * 1.08, 0.0, TAU, 24, Color("fff3cf"), 2.4)
	draw_circle(Vector2(-2, -3), radius * 0.28, Color.WHITE)
