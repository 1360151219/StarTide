class_name LevelConfig
extends Resource

@export var level_id := ""
@export var order := 1
@export_range(1, 10, 1) var difficulty_rating := 1
@export_range(1, 100000, 1) var recommended_power := 1000
@export var display_name := ""
@export var subtitle := ""
@export_multiline var description := ""
@export var map: MapConfig
@export var duration := 90.0
@export var initial_enemy_count := 5
@export var max_enemies := 80
@export_range(0, 100, 1) var max_ranged_enemies := 8
@export_range(0.0, 15.0, 0.5) var opening_tutorial_grace := 0.0
@export var difficulty: DifficultyConfig
@export var loot: LootConfig
@export var content_pool: LevelContentPoolConfig
@export var enemy_ability_budget: EnemyAbilityBudgetConfig
@export var stages: Array[StageConfig] = []
@export var elite: EliteConfig
@export var victory: VictoryConfig
@export var reward: RewardConfig


func stage_index_at(elapsed: float) -> int:
	for index in range(stages.size() - 1, -1, -1):
		if elapsed >= stages[index].start_time:
			return index
	return 0


func stage_end_time(index: int) -> float:
	if index + 1 < stages.size() and stages[index + 1] != null:
		return stages[index + 1].start_time
	return duration


func validation_errors(valid_enemy_ids: PackedStringArray, valid_ability_ids := PackedStringArray()) -> PackedStringArray:
	var errors := PackedStringArray()
	if level_id.is_empty():
		errors.append("level_id 不能为空")
	if order <= 0:
		errors.append("关卡顺序必须大于 0")
	if difficulty_rating <= 0:
		errors.append("难度评级必须大于 0")
	if recommended_power <= 0:
		errors.append("推荐战力必须大于 0")
	if display_name.is_empty():
		errors.append("关卡名称不能为空")
	if duration <= 0.0:
		errors.append("关卡时长必须大于 0")
	if initial_enemy_count < 0 or max_enemies <= 0 or initial_enemy_count > max_enemies:
		errors.append("初始怪物数或场上上限无效")
	if max_ranged_enemies < 0 or max_ranged_enemies > max_enemies:
		errors.append("远程怪物场上上限无效")
	if map == null:
		errors.append("地图配置不能为空")
	else:
		_append_prefixed(errors, "地图", map.validation_errors())
	if difficulty == null:
		errors.append("难度曲线不能为空")
	else:
		_append_prefixed(errors, "难度", difficulty.validation_errors())
	if loot == null:
		errors.append("掉落配置不能为空")
	else:
		_append_prefixed(errors, "掉落", loot.validation_errors())
	if content_pool == null:
		errors.append("内容池配置不能为空")
	else:
		_append_prefixed(errors, "内容池", content_pool.validation_errors())
	if enemy_ability_budget == null:
		errors.append("怪物技能预算不能为空")
	else:
		_append_prefixed(errors, "怪物技能预算", enemy_ability_budget.validation_errors())
	_validate_stages(errors, valid_enemy_ids, valid_ability_ids)
	if elite == null:
		errors.append("精英配置不能为空")
	else:
		_append_prefixed(errors, "精英", elite.validation_errors(duration, valid_enemy_ids))
	if victory == null:
		errors.append("胜利条件不能为空")
	else:
		_append_prefixed(errors, "胜利", victory.validation_errors(elite != null and elite.enabled))
	if reward == null:
		errors.append("奖励配置不能为空")
	else:
		_append_prefixed(errors, "奖励", reward.validation_errors())
	return errors


func _validate_stages(errors: PackedStringArray, valid_enemy_ids: PackedStringArray, valid_ability_ids: PackedStringArray) -> void:
	if stages.is_empty():
		errors.append("至少需要一个阶段")
		return
	var previous_start := -1.0
	var seen_stage_ids: Dictionary = {}
	for index in range(stages.size()):
		var stage := stages[index]
		if stage == null:
			errors.append("阶段 %d 不能为空" % (index + 1))
			continue
		if seen_stage_ids.has(stage.stage_id):
			errors.append("阶段 ID 重复：%s" % stage.stage_id)
		seen_stage_ids[stage.stage_id] = true
		if index == 0 and not is_zero_approx(stage.start_time):
			errors.append("首个阶段必须从 0 秒开始")
		if stage.start_time <= previous_start or stage.start_time >= duration:
			errors.append("阶段 %d 的开始时间必须递增且小于关卡时长" % (index + 1))
		_append_prefixed(errors, "阶段 %d" % (index + 1), stage.validation_errors(valid_enemy_ids, valid_ability_ids))
		if stage.transition_rest_duration >= stage_end_time(index) - stage.start_time:
			errors.append("阶段 %d 的喘息时间不能覆盖整个阶段" % (index + 1))
		previous_start = stage.start_time


func _append_prefixed(target: PackedStringArray, prefix: String, source: PackedStringArray) -> void:
	for message in source:
		target.append("%s：%s" % [prefix, message])
