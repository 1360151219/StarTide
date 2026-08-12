extends RefCounted

var level: LevelConfig
var stage_index := 0
var spawn_rest_until := 0.0
var elite_triggered := false
var boss_triggered := false


func configure(level_config: LevelConfig) -> void:
	level = level_config
	stage_index = 0
	spawn_rest_until = 0.0
	elite_triggered = false
	boss_triggered = false


func advance(elapsed: float) -> Dictionary:
	var transitions: Array[StageConfig] = []
	while stage_index + 1 < level.stages.size() and elapsed >= level.stages[stage_index + 1].start_time:
		stage_index += 1
		transitions.append(level.stages[stage_index])
	if not transitions.is_empty():
		spawn_rest_until = elapsed + current_stage().transition_rest_duration
	var elite_due := false
	if level.elite != null and level.elite.enabled and not elite_triggered and elapsed >= level.elite.spawn_time:
		elite_triggered = true
		elite_due = true
	var boss_due := false
	if level.boss != null and level.boss.enabled and not boss_triggered and elapsed >= level.boss.spawn_time(level.duration):
		boss_triggered = true
		boss_due = true
	return {"transitions": transitions, "elite_due": elite_due, "boss_due": boss_due}


func current_stage() -> StageConfig:
	return level.stages[stage_index]


func current_stage_end() -> float:
	return level.stage_end_time(stage_index)


func is_spawn_resting(elapsed: float) -> bool:
	return elapsed < spawn_rest_until
