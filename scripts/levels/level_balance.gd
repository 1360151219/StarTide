extends RefCounted

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")


static func stage_pressure(level: LevelConfig, stage_index: int) -> float:
	var stage := level.stages[stage_index]
	var end_time := level.stage_end_time(stage_index)
	var midpoint := (stage.start_time + end_time) * 0.5
	var interval := (stage.spawn_interval_start + stage.spawn_interval_end) * 0.5
	var spawn_rate := (1.0 + stage.extra_spawn_chance) / interval
	var scaling := level.difficulty.multipliers_at(midpoint, level.duration)
	var reference_speed: float = EnemyCatalog.enemy("slime")["speed"]
	var weighted_threat := 0.0
	for enemy_id in stage.enemy_weights:
		var enemy := EnemyCatalog.enemy(enemy_id)
		var weight := float(stage.enemy_weights[enemy_id])
		var health: float = enemy["health"] * scaling["health"]
		var damage: float = enemy["damage"] * scaling["damage"]
		var speed_ratio: float = enemy["speed"] * scaling["speed"] / reference_speed
		weighted_threat += weight * health * damage * speed_ratio
	return spawn_rate * weighted_threat


static func level_pressure(level: LevelConfig) -> float:
	var weighted_total := 0.0
	for index in range(level.stages.size()):
		var stage := level.stages[index]
		var stage_duration := level.stage_end_time(index) - stage.start_time
		var active_duration := maxf(0.0, stage_duration - stage.transition_rest_duration)
		weighted_total += stage_pressure(level, index) * active_duration
	return weighted_total / level.duration
