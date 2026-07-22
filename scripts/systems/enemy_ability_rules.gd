extends RefCounted

const AbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")


static func ability_target(enemy: Node, player: Node2D, direction: Vector2, config: Dictionary) -> Vector2:
	if config["shape"] == "circle":
		return enemy.position + direction * minf(enemy.position.distance_to(player.position), float(config["jump_distance"]))
	return player.position


static func player_in_sector(origin: Vector2, direction: Vector2, player_position: Vector2, config: Dictionary) -> bool:
	var to_player := origin.direction_to(player_position)
	return origin.distance_to(player_position) <= float(config["length"]) + 21.0 and absf(direction.angle_to(to_player)) <= float(config["half_angle"])


static func segment_hits_circle(start: Vector2, finish: Vector2, center: Vector2, radius: float) -> bool:
	var segment := finish - start
	var divisor := maxf(segment.length_squared(), 0.0001)
	var progress := clampf((center - start).dot(segment) / divisor, 0.0, 1.0)
	return (start + segment * progress).distance_squared_to(center) <= radius * radius


static func is_visible(position: Vector2, focus: Vector2, viewport_size: Vector2) -> bool:
	return Rect2(focus - viewport_size * 0.5, viewport_size).grow(36.0).has_point(position)


static func phase_count(states: Dictionary, include_executing: bool) -> int:
	var count := 0
	for state in states.values():
		count += int(state["phase"] == "warning" or include_executing and state["phase"] == "executing")
	return count


static func warning_covers_player(enemy: Node, player: Node2D, config: Dictionary) -> bool:
	var direction: Vector2 = enemy.position.direction_to(player.position)
	var target := ability_target(enemy, player, direction, config)
	return telegraph_covers_point(enemy.position, direction, target, player.position, config)


static func player_danger_count(states: Dictionary, player_position: Vector2) -> int:
	var count := 0
	for state in states.values():
		if state["phase"] not in ["warning", "executing"] or not is_instance_valid(state["enemy"]):
			continue
		if state["phase"] == "executing" and state.get("hit_done", false):
			continue
		var config: Dictionary = AbilityCatalog.ability(state["ability_id"]).duplicate()
		if state["phase"] == "executing" and state["ability_id"] == "green_grub_roll":
			config["distance"] = state["remaining"]
		count += int(telegraph_covers_point(state["enemy"].position, state["direction"], state["target"], player_position, config))
	return count


static func telegraph_covers_point(source: Vector2, direction: Vector2, target: Vector2, point: Vector2, config: Dictionary) -> bool:
	match config["shape"]:
		"lane":
			return segment_hits_circle(source, source + direction * float(config["distance"]), point, float(config["lane_width"]) * 0.5 + 21.0)
		"circle":
			return target.distance_to(point) <= float(config["radius"]) + 21.0
		"dashed_line":
			return segment_hits_circle(source, source + direction * float(config["projectile_distance"]), point, 32.0)
		"sector":
			return player_in_sector(source, direction, point, config)
	return false


static func clamp_to_bounds(enemy: Node, bounds: Rect2) -> void:
	var margin: Vector2 = Vector2.ONE * enemy.radius
	enemy.position = enemy.position.clamp(bounds.position + margin, bounds.end - margin)


static func ordered_enemies(enemies: Array[Node]) -> Array[Node]:
	var ordered: Array[Node] = []
	for enemy in enemies:
		if enemy.is_elite:
			ordered.append(enemy)
	for enemy in enemies:
		if not enemy.is_elite:
			ordered.append(enemy)
	return ordered


static func movement_direction(enemy: Node, player_position: Vector2) -> Vector2:
	var direction: Vector2 = enemy.position.direction_to(player_position)
	if enemy.kind != "bat":
		return direction
	var distance: float = enemy.position.distance_to(player_position)
	if distance < 180.0:
		return player_position.direction_to(enemy.position)
	if distance > 330.0:
		return direction
	var tangent: Vector2 = direction.orthogonal() * (-1.0 if enemy.spawn_serial % 2 == 0 else 1.0)
	return (tangent + direction * (distance - 280.0) / 80.0).normalized()
