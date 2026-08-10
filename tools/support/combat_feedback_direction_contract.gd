extends RefCounted


static func watch(session: Node, projectile: Node) -> Dictionary:
	var hits: Array[PlayerHit] = []
	var directions: Array[Vector2] = []
	session.enemy_projectiles.player_hit_requested.connect(func(hit: PlayerHit) -> void: hits.append(hit))
	session.player_hit_feedback_requested.connect(func(_damage: float, direction: Vector2) -> void: directions.append(direction))
	return {
		"health": session.player.health,
		"hits": hits,
		"directions": directions,
		"incoming": projectile.velocity.normalized(),
	}


static func swept_hit_stays_on_incoming_side(player_position: Vector2, captured: Dictionary) -> bool:
	var hits: Array = captured["hits"]
	var directions: Array = captured["directions"]
	if hits.size() != 1 or directions.size() != 1:
		return false
	var incoming: Vector2 = captured["incoming"]
	var origin_direction: Vector2 = player_position.direction_to(hits[0].origin)
	var feedback_direction: Vector2 = directions[0]
	return origin_direction.dot(incoming) < -0.999 and feedback_direction.dot(incoming) < -0.999 and feedback_direction.is_equal_approx(origin_direction)


static func enemy_uses_local_source_position(enemy: Node2D) -> bool:
	var parent := enemy.get_parent() as Node2D
	if parent == null:
		return false
	var original_parent_position := parent.position
	parent.position += Vector2(320.0, 180.0)
	enemy.take_damage(0.0, enemy.position - Vector2(24.0, 0.0))
	var result: bool = enemy.hit_impulse_direction.is_equal_approx(Vector2.RIGHT) and enemy.hit_offset.is_equal_approx(Vector2.RIGHT * enemy.HIT_OFFSET_DISTANCE)
	parent.position = original_parent_position
	return result
