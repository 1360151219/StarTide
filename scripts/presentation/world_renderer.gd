extends Node2D

var map: MapConfig


func configure(map_config: MapConfig) -> void:
	map = map_config
	queue_redraw()


func _draw() -> void:
	if map == null:
		return
	draw_rect(map.world_bounds.grow(32.0), map.background_color)
	draw_texture_rect(map.floor_texture, map.world_bounds, true, map.floor_tint)
	for index in range(14):
		var glow_position := Vector2(
			map.world_bounds.position.x + fposmod(float(index * 617 + 180), map.world_bounds.size.x),
			map.world_bounds.position.y + fposmod(float(index * 953 + 320), map.world_bounds.size.y)
		)
		draw_circle(glow_position, 105.0 + index % 4 * 24.0, map.glow_color)
	draw_rect(map.world_bounds, map.border_color, false, 8.0)
