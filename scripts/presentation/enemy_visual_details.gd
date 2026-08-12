extends RefCounted


static func body_scale(enemy: Node) -> Vector2:
	if enemy.ability_visual_id != "green_grub_roll":
		return Vector2.ONE
	match enemy.ability_visual_phase:
		"warning":
			var anticipation: float = sin(enemy.ability_visual_progress * PI * 0.5)
			return Vector2(1.0 + anticipation * 0.17, 1.0 - anticipation * 0.2)
		"executing":
			return Vector2(1.1, 0.9 + sin(enemy.animation_time * 22.0) * 0.05)
		"recovery":
			return Vector2(1.0 + (1.0 - enemy.ability_visual_progress) * 0.1, 0.9 + enemy.ability_visual_progress * 0.1)
	return Vector2.ONE


static func draw_slow_fragments(enemy: Node2D) -> void:
	for index in range(7):
		var angle: float = index * TAU / 7.0 + enemy.animation_time * 0.18
		var center: Vector2 = Vector2.from_angle(angle) * (enemy.radius + 7.0)
		var tangent: Vector2 = Vector2.from_angle(angle + PI * 0.5)
		enemy.draw_line(center - tangent * 4.0, center + tangent * 4.0, Color(0.03, 0.27, 0.38, 0.7), 4.0, true)
		enemy.draw_line(center - tangent * 3.0, center + tangent * 3.0, Color(0.62, 0.94, 1.0, 0.72), 1.8, true)


static func draw_ability_overlay(enemy: Node2D, metrics: Dictionary) -> void:
	if enemy.ability_visual_id.is_empty():
		return
	if enemy.ability_visual_id == "green_grub_roll":
		if enemy.ability_visual_phase == "warning":
			var charge_radius: float = enemy.radius + 10.0 + sin(enemy.animation_time * 12.0) * 2.0
			enemy.draw_arc(Vector2(0, 8), charge_radius, PI * 0.08, PI * 0.92, 24, Color(0.05, 0.28, 0.2, 0.72), 5.0)
			enemy.draw_arc(Vector2(0, 8), charge_radius, PI * 0.08, PI * 0.92, 24, Color(0.76, 0.94, 0.42, 0.86), 2.2)
		elif enemy.ability_visual_phase == "executing" and not enemy.ability_visual_direction.is_zero_approx():
			var backward: Vector2 = -enemy.ability_visual_direction.normalized()
			for index in range(3):
				var side: Vector2 = enemy.ability_visual_direction.orthogonal() * (index - 1) * 8.0
				enemy.draw_line(side + backward * 18.0, side + backward * (34.0 + index * 8.0), Color(0.86, 0.97, 0.58, 0.62), 2.5, true)
	elif enemy.ability_visual_id == "bat_bolt" and enemy.ability_visual_phase == "warning":
		var size: Vector2 = metrics["size"]
		var charge_center := Vector2(0, float(metrics["y"]) + size.y * 0.58)
		var charge_radius: float = 4.0 + enemy.ability_visual_progress * 9.0
		enemy.draw_circle(charge_center, charge_radius + 5.0, Color(0.17, 0.06, 0.24, 0.72))
		enemy.draw_circle(charge_center, charge_radius, Color(0.58, 0.32, 0.86, 0.72 + enemy.ability_visual_progress * 0.22))
		enemy.draw_arc(charge_center, charge_radius + 3.0, 0.0, TAU, 24, Color(1.0, 0.67, 0.34, 0.86), 2.0)
		if enemy.ability_visual_progress >= 0.66:
			enemy.draw_circle(charge_center - Vector2(2, 2), 2.5, Color.WHITE)
