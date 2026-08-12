class_name EnemyAbilityBudgetConfig
extends Resource

@export var opening_protection_time := 0.0
@export_range(1, 12, 1) var max_telegraphs := 3
@export_range(0, 12, 1) var max_projectiles := 2
@export var min_start_interval := 0.35
@export_range(1, 6, 1) var max_player_danger_areas := 2
@export var disabled_ability_ids := PackedStringArray()


func allows_ability(ability_id: String) -> bool:
	return not disabled_ability_ids.has(ability_id)


func validation_errors(valid_ability_ids := PackedStringArray()) -> PackedStringArray:
	var errors := PackedStringArray()
	if opening_protection_time < 0.0:
		errors.append("开场技能保护时间不能小于 0")
	if max_telegraphs <= 0:
		errors.append("同时预警数量必须大于 0")
	if max_projectiles < 0:
		errors.append("敌方弹体数量不能小于 0")
	if min_start_interval < 0.0:
		errors.append("预警启动间隔不能小于 0")
	if max_player_danger_areas <= 0 or max_player_danger_areas > max_telegraphs:
		errors.append("玩家危险区域上限必须位于 1 到预警上限之间")
	var seen_ids: Dictionary = {}
	for ability_id in disabled_ability_ids:
		if ability_id.is_empty() or not valid_ability_ids.is_empty() and not valid_ability_ids.has(ability_id):
			errors.append("禁用了未知怪物技能：%s" % ability_id)
		if seen_ids.has(ability_id):
			errors.append("重复禁用怪物技能：%s" % ability_id)
		seen_ids[ability_id] = true
	return errors
