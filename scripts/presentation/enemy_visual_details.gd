extends RefCounted


static func body_scale(enemy: Node) -> Vector2:
	if enemy.ability_visual_id.is_empty():
		return Vector2.ONE
	match enemy.ability_visual_phase:
		"warning":
			var anticipation: float = sin(enemy.ability_visual_progress * PI * 0.5)
			match enemy.ability_visual_id:
				"green_grub_roll":
					return Vector2(1.0 + anticipation * 0.17, 1.0 - anticipation * 0.2)
				"bat_bolt", "bellfeather_circle":
					return Vector2(1.0 - anticipation * 0.06, 1.0 + anticipation * 0.11)
				"zouwu_dash":
					return Vector2(1.0 + anticipation * 0.16, 1.0 - anticipation * 0.12)
			return Vector2(1.0 + anticipation * 0.07, 1.0 - anticipation * 0.06)
		"executing":
			return Vector2(1.22, 0.84) if enemy.ability_visual_id == "zouwu_dash" else Vector2(1.1, 0.9 + sin(enemy.animation_time * 22.0) * 0.05)
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
		_draw_grub_roll(enemy)
	elif enemy.ability_visual_id == "bat_bolt" and enemy.ability_visual_phase == "warning":
		_draw_bat_charge(enemy, metrics)
	elif enemy.ability_visual_id == "cloud_hart_sector" and enemy.ability_visual_phase == "warning":
		_draw_hart_charge(enemy, metrics)
	elif enemy.ability_visual_id == "bellfeather_circle" and enemy.ability_visual_phase == "warning":
		_draw_bell_charge(enemy, metrics)
	elif enemy.ability_visual_id.begins_with("zouwu_"):
		_draw_zouwu_cast(enemy)


static func _draw_grub_roll(enemy: Node2D) -> void:
	if enemy.ability_visual_phase == "warning":
		var charge_radius: float = enemy.radius + 10.0 + sin(enemy.animation_time * 12.0) * 2.0
		enemy.draw_arc(Vector2(0, 8), charge_radius, PI * 0.08, PI * 0.92, 24, Color(0.05, 0.28, 0.2, 0.72), 5.0)
		enemy.draw_arc(Vector2(0, 8), charge_radius, PI * 0.08, PI * 0.92, 24, Color(0.76, 0.94, 0.42, 0.86), 2.2)
	elif enemy.ability_visual_phase == "executing" and not enemy.ability_visual_direction.is_zero_approx():
		var backward: Vector2 = -enemy.ability_visual_direction.normalized()
		for index in range(3):
			var side: Vector2 = enemy.ability_visual_direction.orthogonal() * (index - 1) * 8.0
			enemy.draw_line(side + backward * 18.0, side + backward * (34.0 + index * 8.0), Color(0.86, 0.97, 0.58, 0.62), 2.5, true)


static func _draw_bat_charge(enemy: Node2D, metrics: Dictionary) -> void:
	var size: Vector2 = metrics["size"]
	var charge_center := Vector2(0, float(metrics["y"]) + size.y * 0.58)
	var charge_radius: float = 4.0 + enemy.ability_visual_progress * 9.0
	enemy.draw_circle(charge_center, charge_radius + 5.0, Color(0.17, 0.06, 0.24, 0.72))
	enemy.draw_circle(charge_center, charge_radius, Color(0.58, 0.32, 0.86, 0.72 + enemy.ability_visual_progress * 0.22))
	enemy.draw_arc(charge_center, charge_radius + 3.0, 0.0, TAU, 24, Color(1.0, 0.67, 0.34, 0.86), 2.0)
	if enemy.ability_visual_progress >= 0.66:
		enemy.draw_circle(charge_center - Vector2(2, 2), 2.5, Color.WHITE)


static func _draw_hart_charge(enemy: Node2D, metrics: Dictionary) -> void:
	var size: Vector2 = metrics["size"]
	var horn_center := Vector2(0, float(metrics["y"]) + size.y * 0.2)
	var direction: Vector2 = enemy.ability_visual_direction.normalized()
	var tangent: Vector2 = direction.orthogonal()
	var gather: float = sin(enemy.ability_visual_progress * PI * 0.5)
	for side in [-1.0, 1.0]:
		var start: Vector2 = horn_center + tangent * side * (22.0 - gather * 6.0) - direction * 8.0
		var finish: Vector2 = horn_center + direction * (12.0 + gather * 18.0) + tangent * side * 4.0
		enemy.draw_line(start, finish, Color(0.05, 0.3, 0.29, 0.82), 5.0, true)
		enemy.draw_line(start, finish, Color(0.58, 0.91, 0.8, 0.94), 2.1, true)


static func _draw_bell_charge(enemy: Node2D, metrics: Dictionary) -> void:
	var size: Vector2 = metrics["size"]
	var center := Vector2(0, float(metrics["y"]) + size.y * 0.42)
	for index in range(3):
		var angle: float = enemy.animation_time * 0.8 + index * TAU / 3.0
		var point: Vector2 = center + Vector2.from_angle(angle) * lerpf(24.0, 10.0, enemy.ability_visual_progress)
		enemy.draw_line(point, center, Color(0.25, 0.13, 0.12, 0.6), 2.2, true)
		enemy.draw_circle(point, 3.4, Color(0.98, 0.78, 0.34, 0.92))


static func _draw_zouwu_cast(enemy: Node2D) -> void:
	var direction: Vector2 = enemy.ability_visual_direction.normalized()
	var tangent: Vector2 = direction.orthogonal()
	var colors: Array[Color] = [Color("69c8c1"), Color("f1c45b"), Color("e98272"), Color("75b779"), Color("667bbb")]
	if enemy.ability_visual_id == "zouwu_dash":
		if enemy.ability_visual_phase == "executing":
			return
		var reach: float = lerpf(24.0, 48.0, enemy.ability_visual_progress)
		for side in [-1.0, 1.0]:
			enemy.draw_line(-direction * reach + tangent * side * 12.0, direction * 20.0 + tangent * side * 5.0, Color("e7fbef"), 3.0, true)
		return
	var radius: float = enemy.radius + 15.0
	for index in range(colors.size()):
		var angle: float = direction.angle() - PI * 0.75 + index * PI * 0.375
		var start: Vector2 = Vector2.from_angle(angle) * radius
		var end: Vector2 = Vector2.from_angle(angle) * lerpf(radius + 14.0, radius - 7.0, enemy.ability_visual_progress)
		enemy.draw_line(start, end, Color(0.08, 0.24, 0.28, 0.72), 5.0, true)
		enemy.draw_line(start, end, colors[index], 2.2, true)
