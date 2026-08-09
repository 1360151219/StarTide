extends Node2D

var map: MapConfig
var tracked_player: Node2D
var phase := 0.0
var redraw_elapsed := 0.0


func configure(map_config: MapConfig) -> void:
	map = map_config
	queue_redraw()


func track_player(player: Node2D) -> void:
	tracked_player = player


func _process(delta: float) -> void:
	if map == null:
		return
	phase = fposmod(phase + delta, 12.0)
	redraw_elapsed += delta
	if redraw_elapsed >= 0.08:
		redraw_elapsed = 0.0
		queue_redraw()


func _draw() -> void:
	if map == null:
		return
	for index in range(28):
		var speed := 4.0 + float(index % 5) * 1.7
		var position := Vector2(
			map.world_bounds.position.x + fposmod(float(index * 613 + 91) + phase * speed * 0.35, map.world_bounds.size.x),
			map.world_bounds.position.y + fposmod(float(index * 887 + 251) - phase * speed, map.world_bounds.size.y)
		)
		var alpha := 0.34 + sin(phase * 1.8 + index) * 0.14
		if is_instance_valid(tracked_player) and position.distance_to(tracked_player.position) < 180.0:
			alpha *= 0.22
		var color := map.environment_particle_color
		color.a *= alpha
		match map.biome_id:
			"golden_oasis":
				draw_line(position + Vector2(-3, 0), position + Vector2(3, 0), color, 2.0)
				draw_line(position + Vector2(0, -3), position + Vector2(0, 3), color, 2.0)
			"crystal_volcano":
				draw_circle(position, 2.0 + index % 2, color)
				draw_line(position, position + Vector2(2, -6), color, 1.5)
			_:
				draw_circle(position, 2.0, color)
				draw_line(position, position + Vector2(4, 1), color, 1.2)
