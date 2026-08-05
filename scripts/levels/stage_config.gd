class_name StageConfig
extends Resource

@export var stage_id := ""
@export var display_name := ""
@export_multiline var subtitle := ""
@export var start_time := 0.0
@export var spawn_interval_start := 0.9
@export var spawn_interval_end := 0.74
@export_range(0.0, 1.0, 0.01) var extra_spawn_chance := 0.0
@export var enemy_entries: Array[EnemySpawnEntryConfig] = []
@export var transition_rest_duration := 3.0


func spawn_interval_at(elapsed: float, end_time: float) -> float:
	var duration := maxf(end_time - start_time, 0.001)
	var progress := clampf((elapsed - start_time) / duration, 0.0, 1.0)
	return lerpf(spawn_interval_start, spawn_interval_end, progress)


func entry_for(enemy_id: String) -> EnemySpawnEntryConfig:
	for entry in enemy_entries:
		if entry != null and entry.enemy_id == enemy_id:
			return entry
	return null


func enemy_weight(enemy_id: String) -> float:
	var entry := entry_for(enemy_id)
	return entry.weight if entry != null else 0.0


func enemy_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for entry in enemy_entries:
		if entry != null:
			result.append(entry.enemy_id)
	return result


func validation_errors(valid_enemy_ids: PackedStringArray, valid_ability_ids := PackedStringArray()) -> PackedStringArray:
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
	if enemy_entries.is_empty():
		errors.append("怪物编成不能为空")
	var total_weight := 0.0
	var seen_enemy_ids: Dictionary = {}
	for entry in enemy_entries:
		if entry == null:
			errors.append("怪物编成条目不能为空")
			continue
		for message in entry.validation_errors(valid_enemy_ids, valid_ability_ids):
			errors.append(message)
		if seen_enemy_ids.has(entry.enemy_id):
			errors.append("怪物编成重复：%s" % entry.enemy_id)
		seen_enemy_ids[entry.enemy_id] = true
		total_weight += entry.weight
	if not is_equal_approx(total_weight, 1.0):
		errors.append("怪物权重总和必须为 1，当前为 %.3f" % total_weight)
	return errors
