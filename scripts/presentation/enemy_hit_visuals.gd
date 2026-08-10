extends RefCounted


static func draw_fragments(enemy: Node2D, metrics: Dictionary, progress: float, direction: Vector2, offset: Vector2) -> void:
	var fade := 1.0 - progress
	var fragment_count := 4 if enemy.kind in ["green_grub", "brute"] else 3
	var size: Vector2 = metrics["size"]
	var base_y := float(metrics["y"]) + size.y * 0.55
	for index in range(fragment_count):
		var spread := (index - (fragment_count - 1) * 0.5) * 0.46
		var fragment_direction := direction.rotated(spread) if not direction.is_zero_approx() else Vector2.from_angle(index * TAU / fragment_count + enemy.spawn_serial * 0.37)
		var position: Vector2 = Vector2(0.0, base_y) + fragment_direction * (enemy.radius * 0.42 + progress * (12.0 + index * 2.0))
		position += offset
		_draw_fragment(enemy, position, fragment_direction, index, fade)


static func _draw_fragment(enemy: Node2D, at: Vector2, direction: Vector2, index: int, alpha: float) -> void:
	var tangent := direction.orthogonal()
	if enemy.kind == "green_grub":
		var leaf := PackedVector2Array([
			at + direction * 5.0,
			at + tangent * 3.0,
			at - direction * 4.0,
			at - tangent * 3.0,
		])
		enemy.draw_colored_polygon(leaf, Color(0.48, 0.78, 0.27, alpha))
		enemy.draw_polyline(PackedVector2Array([leaf[0], leaf[1], leaf[2], leaf[3], leaf[0]]), Color(0.12, 0.3, 0.2, alpha), 1.2, true)
	elif enemy.kind == "bat":
		var feather := PackedVector2Array([
			at + direction * 6.0,
			at + tangent * (2.0 + index),
			at - direction * 4.0,
		])
		enemy.draw_colored_polygon(feather, Color(0.48, 0.34, 0.68, alpha))
	elif enemy.kind == "brute":
		var chip_size := 3.0 + index % 2
		var chip := PackedVector2Array([
			at + direction * chip_size,
			at + tangent * chip_size,
			at - direction * chip_size,
			at - tangent * chip_size,
		])
		enemy.draw_colored_polygon(chip, Color(0.48, 0.59, 0.62, alpha))
		enemy.draw_polyline(PackedVector2Array([chip[0], chip[1], chip[2], chip[3], chip[0]]), Color(0.12, 0.22, 0.25, alpha), 1.2, true)
	else:
		enemy.draw_circle(at, 3.2 + index * 0.35, Color(0.78, 0.43, 0.62, alpha))
		enemy.draw_circle(at - direction * 1.0, 1.4, Color(1.0, 0.84, 0.9, alpha))
