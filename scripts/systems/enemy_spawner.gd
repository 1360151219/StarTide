extends RefCounted

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")

var level: LevelConfig
var stage_director: RefCounted
var rng: RandomNumberGenerator
var spawn_timer := 0.3


func configure(level_config: LevelConfig, director: RefCounted, random: RandomNumberGenerator) -> void:
	level = level_config
	stage_director = director
	rng = random
	spawn_timer = 0.3


func next_spawn_count(delta: float, elapsed: float, current_count: int) -> int:
	if stage_director.is_spawn_resting(elapsed) or current_count >= level.max_enemies:
		return 0
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return 0
	var stage: StageConfig = stage_director.current_stage()
	spawn_timer = stage.spawn_interval_at(elapsed, stage_director.current_stage_end())
	return mini(1 + int(rng.randf() < stage.extra_spawn_chance), level.max_enemies - current_count)


func roll_enemy_id(current_ranged_count := 0) -> String:
	var weights: Dictionary = stage_director.current_stage().enemy_weights
	var allowed_ids := PackedStringArray()
	var total_weight := 0.0
	for enemy_id in EnemyCatalog.ids():
		if current_ranged_count >= level.max_ranged_enemies and EnemyCatalog.is_ranged(enemy_id):
			continue
		var weight := float(weights.get(enemy_id, 0.0))
		if weight <= 0.0:
			continue
		allowed_ids.append(enemy_id)
		total_weight += weight
	if allowed_ids.is_empty() or total_weight <= 0.0:
		return ""
	var roll := rng.randf() * total_weight
	var cumulative := 0.0
	for enemy_id in allowed_ids:
		cumulative += float(weights.get(enemy_id, 0.0))
		if roll < cumulative:
			return enemy_id
	return allowed_ids[-1]


func spawn_position(player_position: Vector2, elite := false, viewport_size := Vector2.ZERO) -> Vector2:
	var map := level.map
	var minimum: float = map.elite_spawn_distance_min if elite else map.spawn_distance_min
	var maximum: float = map.elite_spawn_distance_max if elite else map.spawn_distance_max
	if viewport_size != Vector2.ZERO:
		minimum = maxf(minimum, viewport_size.length() * 0.5 + 48.0)
		maximum = maxf(maximum, minimum + 80.0)
	var valid_bounds := map.world_bounds.grow(-30.0)
	var first_angle := rng.randf_range(0.0, TAU)
	for attempt in range(16):
		var angle := first_angle + attempt * TAU / 16.0
		var candidate := player_position + Vector2.from_angle(angle) * rng.randf_range(minimum, maximum)
		if valid_bounds.has_point(candidate):
			return candidate
	return _farthest_valid_position(player_position, valid_bounds, minimum, maximum)


func _farthest_valid_position(player_position: Vector2, bounds: Rect2, minimum: float, maximum: float) -> Vector2:
	var end := bounds.end - Vector2.ONE
	var corners := [
		bounds.position,
		Vector2(end.x, bounds.position.y),
		end,
		Vector2(bounds.position.x, end.y),
	]
	var farthest: Vector2 = corners[0]
	for corner in corners:
		if player_position.distance_squared_to(corner) > player_position.distance_squared_to(farthest):
			farthest = corner
	var available_distance := player_position.distance_to(farthest)
	var distance := clampf(available_distance, minimum, maximum)
	if available_distance <= minimum:
		return farthest
	return player_position + player_position.direction_to(farthest) * distance
