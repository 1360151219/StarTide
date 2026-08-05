class_name EquipmentRewardConfig
extends Resource

@export var reward_id := ""
@export var entries: Array[EquipmentGrantEntryConfig] = []


func validation_errors(valid_equipment_ids: PackedStringArray, valid_rarity_ids: PackedStringArray, rarity_max_levels: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if reward_id.is_empty():
		errors.append("固定装备奖励 ID 不能为空")
	if entries.is_empty():
		errors.append("固定装备奖励至少需要一个条目")
	var seen_instance_ids: Dictionary = {}
	for entry in entries:
		if entry == null:
			errors.append("固定装备奖励条目不能为空")
			continue
		for message in entry.validation_errors(valid_equipment_ids, valid_rarity_ids, rarity_max_levels):
			errors.append(message)
		if seen_instance_ids.has(entry.instance_id):
			errors.append("固定装备实例 ID 重复：%s" % entry.instance_id)
		seen_instance_ids[entry.instance_id] = true
	return errors


func dictionaries() -> Array:
	var result: Array = []
	for entry in entries:
		if entry != null:
			result.append(entry.to_dictionary())
	return result
