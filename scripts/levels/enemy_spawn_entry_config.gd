class_name EnemySpawnEntryConfig
extends Resource

@export var enemy_id := ""
@export_range(0.001, 1.0, 0.001) var weight := 1.0
@export_range(0, 100, 1) var max_active := 0
@export var ability_variant_id := ""


func validation_errors(valid_enemy_ids: PackedStringArray, valid_ability_ids: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	if enemy_id.is_empty():
		errors.append("怪物 ID 不能为空")
	elif not valid_enemy_ids.has(enemy_id):
		errors.append("未知怪物：%s" % enemy_id)
	if weight <= 0.0:
		errors.append("怪物权重必须大于 0：%s" % enemy_id)
	if not ability_variant_id.is_empty() and not valid_ability_ids.has(ability_variant_id):
		errors.append("未知怪物技能变体：%s" % ability_variant_id)
	return errors
