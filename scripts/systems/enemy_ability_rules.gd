extends RefCounted

const AbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")


static func segment_hits_circle(start: Vector2, finish: Vector2, center: Vector2, radius: float) -> bool:
	var segment := finish - start
	var divisor := maxf(segment.length_squared(), 0.0001)
	var progress := clampf((center - start).dot(segment) / divisor, 0.0, 1.0)
	return (start + segment * progress).distance_squared_to(center) <= radius * radius


static func is_visible(position: Vector2, focus: Vector2, viewport_size: Vector2) -> bool:
	return Rect2(focus - viewport_size * 0.5, viewport_size).grow(36.0).has_point(position)


static func update_visibility(state: Dictionary, position: Vector2, focus: Vector2, viewport_size: Vector2, elapsed: float) -> void:
	if is_visible(position, focus, viewport_size):
		if float(state["visible_since"]) < 0.0:
			state["visible_since"] = elapsed
	else:
		state["visible_since"] = -1.0


static func phase_count(states: Dictionary, include_executing: bool) -> int:
	var count := 0
	for state in states.values():
		count += int(state["phase"] == "warning" or include_executing and state["phase"] == "executing")
	return count


static func warning_covers_player(enemy: Node, player: Node2D, config: Dictionary) -> bool:
	var direction: Vector2 = enemy.position.direction_to(player.position)
	return telegraph_covers_point(enemy.position, direction, player.position, config, player.position)


static func player_danger_count(states: Dictionary, player_position: Vector2) -> int:
	var count := 0
	for state in states.values():
		if state["phase"] not in ["warning", "executing"] or not is_instance_valid(state["enemy"]):
			continue
		if state["phase"] == "executing" and state.get("hit_done", false):
			continue
		var config: Dictionary = AbilityCatalog.ability(state["ability_id"]).duplicate()
		if state["phase"] == "executing" and str(config.get("runtime_kind", "")) == "roll":
			config["distance"] = state["remaining"]
		count += int(telegraph_covers_point(state["enemy"].position, state["direction"], player_position, config, state.get("target", Vector2.INF)))
	return count


static func telegraph_covers_point(source: Vector2, direction: Vector2, point: Vector2, config: Dictionary, target := Vector2.INF, point_radius := 21.0) -> bool:
	match config["shape"]:
		"lane":
			return segment_hits_circle(source, source + direction * float(config["distance"]), point, float(config["lane_width"]) * 0.5 + point_radius)
		"dashed_line":
			return segment_hits_circle(source, source + direction * float(config["projectile_distance"]), point, 11.0 + point_radius)
		"circle":
			var center: Vector2 = target if target.is_finite() else source
			return center.distance_squared_to(point) <= pow(float(config["radius"]) + point_radius, 2.0)
		"sector":
			return _inside_sector(source, direction, point, 0.0, float(config["radius"]), float(config["arc_degrees"]), point_radius)
		"annular_sector":
			return _inside_sector(source, direction, point, float(config["inner_radius"]), float(config["outer_radius"]), float(config["arc_degrees"]), point_radius)
	return false


static func _inside_sector(source: Vector2, direction: Vector2, point: Vector2, inner_radius: float, outer_radius: float, arc_degrees: float, point_radius: float) -> bool:
	const BOUNDARY_EPSILON := 0.001
	var offset := point - source
	var distance := offset.length()
	if distance < maxf(0.0, inner_radius - point_radius) - BOUNDARY_EPSILON or distance > outer_radius + point_radius + BOUNDARY_EPSILON:
		return false
	if distance <= point_radius:
		return inner_radius <= point_radius
	return absf(direction.normalized().angle_to(offset.normalized())) <= deg_to_rad(arc_degrees * 0.5) + BOUNDARY_EPSILON


static func clamp_to_bounds(enemy: Node, bounds: Rect2) -> void:
	var margin: Vector2 = Vector2.ONE * enemy.radius
	enemy.position = enemy.position.clamp(bounds.position + margin, bounds.end - margin)


static func ordered_enemies(enemies: Array[Node]) -> Array[Node]:
	var ordered: Array[Node] = []
	for enemy in enemies:
		if enemy.is_boss:
			continue
		if enemy.is_elite:
			ordered.append(enemy)
	for enemy in enemies:
		if not enemy.is_elite and not enemy.is_boss:
			ordered.append(enemy)
	return ordered


static func cleanup_states(states: Dictionary) -> void:
	for key in states.keys():
		if not is_instance_valid(states[key]["enemy"]):
			states.erase(key)


static func elite_slot_reserved(enemy_system: Node, states: Dictionary, level: LevelConfig, elapsed: float, warning_count: int, viewport_size: Vector2) -> bool:
	if warning_count < level.enemy_ability_budget.max_telegraphs - 1:
		return false
	for enemy in enemy_system.snapshot():
		if not enemy.is_elite or not is_visible(enemy.position, enemy_system.player.position, viewport_size):
			continue
		if enemy.ability_id.is_empty():
			continue
		var state: Dictionary = states.get(enemy.get_instance_id(), {"phase": "idle", "cooldown_until": 0.0})
		if state["phase"] == "idle" and elapsed >= float(state["cooldown_until"]):
			return true
	return false


static func movement_direction(enemy: Node, player_position: Vector2) -> Vector2:
	var direction: Vector2 = enemy.position.direction_to(player_position)
	if not EnemyCatalog.is_ranged(enemy.kind):
		return direction
	var distance: float = enemy.position.distance_to(player_position)
	if distance < 180.0:
		return player_position.direction_to(enemy.position)
	if distance > 330.0:
		return direction
	var tangent: Vector2 = direction.orthogonal() * (-1.0 if enemy.spawn_serial % 2 == 0 else 1.0)
	return (tangent + direction * (distance - 280.0) / 80.0).normalized()
