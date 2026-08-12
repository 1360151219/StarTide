extends RefCounted


static func metrics(enemy: Node) -> Dictionary:
	var texture_size := Vector2(82.0, 69.0)
	var texture_y := -35.0
	var shadow_width := 29.0
	var bar_y := -48.0
	match enemy.kind:
		"green_grub":
			texture_size = Vector2(88.0, 65.0)
			texture_y = -34.0
			shadow_width = 28.0
			bar_y = -47.0
		"bat":
			texture_size = Vector2(105.0, 67.0)
			texture_y = -38.0
			bar_y = -50.0
		"brute":
			texture_size = Vector2(126.0, 109.0)
			texture_y = -65.0
			shadow_width = 46.0
			bar_y = -75.0
		"cloud_hart":
			texture_size = Vector2(112.0, 96.0)
			texture_y = -57.0
			shadow_width = 38.0
			bar_y = -67.0
		"bellfeather_kite":
			texture_size = Vector2(116.0, 82.0)
			texture_y = -51.0
			shadow_width = 35.0
			bar_y = -61.0
		"zouwu":
			texture_size = Vector2(96.0, 76.0)
			texture_y = -46.0
			shadow_width = 34.0
			bar_y = -58.0
	return {
		"size": texture_size * enemy.visual_scale,
		"y": texture_y * enemy.visual_scale,
		"shadow": shadow_width * enemy.visual_scale,
		"bar_y": bar_y * enemy.visual_scale,
	}


static func draw_ground(enemy: Node2D, visual_metrics: Dictionary) -> void:
	enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.38))
	enemy.draw_circle(Vector2(3, 42), visual_metrics["shadow"], Color(0.08, 0.15, 0.15, 0.38))
	enemy.draw_set_transform(Vector2.ZERO)


static func draw_health_bar(enemy: Node2D, visual_metrics: Dictionary) -> void:
	var bar_width := maxf(38.0, enemy.radius * 2.0)
	var alpha := clampf(enemy.health_bar_time / 0.18, 0.0, 1.0)
	enemy.draw_rect(Rect2(-bar_width * 0.5, visual_metrics["bar_y"], bar_width, 5.0), Color(0.03, 0.04, 0.1, 0.82 * alpha), true)
	enemy.draw_rect(Rect2(-bar_width * 0.5, visual_metrics["bar_y"], bar_width * maxf(enemy.health, 0.0) / enemy.max_health, 5.0), Color(0.95, 0.72, 0.29, alpha), true)
