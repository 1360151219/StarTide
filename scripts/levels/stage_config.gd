class_name StageConfig
extends Resource

@export var stage_id := ""
@export var display_name := ""
@export_multiline var subtitle := ""
@export var start_time := 0.0
@export var spawn_interval_start := 0.9
@export var spawn_interval_end := 0.74
@export_range(0.0, 1.0, 0.01) var extra_spawn_chance := 0.0
@export var enemy_weights: Dictionary = {"slime": 1.0}
@export var transition_rest_duration := 3.0


func spawn_interval_at(elapsed: float, end_time: float) -> float:
	var duration := maxf(end_time - start_time, 0.001)
	var progress := clampf((elapsed - start_time) / duration, 0.0, 1.0)
	return lerpf(spawn_interval_start, spawn_interval_end, progress)


func validation_errors(valid_enemy_ids: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	if stage_id.is_empty():
		errors.append("stage_id 不能为空")
	if display_name.is_empty():
		errors.append("阶段名称不能为空")
	if start_time < 0.0:
		errors.append("阶段开始时间不能小于 0")
	if spawn_interval_start <= 0.0 or spawn_interval_end <= 0.0:
		errors.append("刷怪间隔必须大于 0")
	if transition_rest_duration < 0.0:
		errors.append("阶段喘息时间不能小于 0")
	var total_weight := 0.0
	for enemy_id in enemy_weights:
		if not valid_enemy_ids.has(enemy_id):
			errors.append("未知怪物：%s" % enemy_id)
		var weight := float(enemy_weights[enemy_id])
		if weight < 0.0:
			errors.append("怪物权重不能为负数：%s" % enemy_id)
		total_weight += weight
	if not is_equal_approx(total_weight, 1.0):
		errors.append("怪物权重总和必须为 1，当前为 %.3f" % total_weight)
	return errors
