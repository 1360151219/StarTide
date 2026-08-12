extends RefCounted

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")


static func stage_pressure(level: LevelConfig, stage_index: int) -> float:
	var stage := level.stages[stage_index]
	var end_time := level.stage_end_time(stage_index)
	var midpoint := (stage.start_time + end_time) * 0.5
	var interval := (stage.spawn_interval_start + stage.spawn_interval_end) * 0.5
	var spawn_rate := (1.0 + stage.extra_spawn_chance) / interval
	var scaling := level.difficulty.multipliers_at(midpoint, level.duration)
	var reference_speed: float = EnemyCatalog.enemy("slime")["speed"]
	var weighted_threat := 0.0
	for entry in stage.enemy_entries:
		var enemy := EnemyCatalog.enemy(entry.enemy_id)
		var weight := entry.weight
		var health: float = enemy["health"] * scaling["health"]
		var damage: float = enemy["damage"] * scaling["damage"]
		var speed_ratio: float = enemy["speed"] * scaling["speed"] / reference_speed
		var ability_ratio := _ability_active_ratio(level, stage_index, entry)
		var ability_threat := lerpf(1.0, EnemyAbilityCatalog.threat_multiplier(entry.ability_variant_id), ability_ratio)
		weighted_threat += weight * health * damage * speed_ratio * ability_threat
	return spawn_rate * weighted_threat


static func level_pressure(level: LevelConfig) -> float:
	var weighted_total := 0.0
	for index in range(level.stages.size()):
		var stage := level.stages[index]
		var stage_duration := level.stage_end_time(index) - stage.start_time
		var active_duration := maxf(0.0, stage_duration - stage.transition_rest_duration)
		weighted_total += stage_pressure(level, index) * active_duration
	return weighted_total / level.duration


static func expected_spawn_budget(level: LevelConfig) -> float:
	var total := float(level.initial_enemy_count)
	for index in range(level.stages.size()):
		var stage := level.stages[index]
		var stage_duration := level.stage_end_time(index) - stage.start_time
		var active_duration := maxf(0.0, stage_duration - stage.transition_rest_duration)
		var average_interval := (stage.spawn_interval_start + stage.spawn_interval_end) * 0.5
		total += active_duration * (1.0 + stage.extra_spawn_chance) / average_interval
	return total


static func expected_experience_budget(level: LevelConfig) -> float:
	if level.stages.is_empty():
		return 0.0
	var total := float(level.initial_enemy_count) * _weighted_experience(level, level.stages[0])
	for index in range(level.stages.size()):
		var stage := level.stages[index]
		var stage_duration := level.stage_end_time(index) - stage.start_time
		var active_duration := maxf(0.0, stage_duration - stage.transition_rest_duration)
		var average_interval := (stage.spawn_interval_start + stage.spawn_interval_end) * 0.5
		var spawn_budget := active_duration * (1.0 + stage.extra_spawn_chance) / average_interval
		total += spawn_budget * _weighted_experience(level, stage)
	return total


static func _ability_active_ratio(level: LevelConfig, stage_index: int, entry: EnemySpawnEntryConfig) -> float:
	var stage := level.stages[stage_index]
	if entry.ability_variant_id.is_empty():
		return 0.0
	if level.enemy_ability_budget == null:
		return 1.0
	var stage_end := level.stage_end_time(stage_index)
	var duration := maxf(stage_end - stage.start_time, 0.001)
	var active_start := maxf(stage.start_time, level.enemy_ability_budget.opening_protection_time)
	return clampf((stage_end - active_start) / duration, 0.0, 1.0)


static func _weighted_experience(level: LevelConfig, stage: StageConfig) -> float:
	var result := 0.0
	for entry in stage.enemy_entries:
		var base_experience := float(EnemyCatalog.enemy(entry.enemy_id)["experience"])
		var dropped_experience := maxi(1, roundi(base_experience * level.loot.experience_multiplier))
		result += entry.weight * dropped_experience
	return result
