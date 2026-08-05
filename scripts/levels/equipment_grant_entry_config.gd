class_name EquipmentGrantEntryConfig
extends Resource

@export var instance_id := ""
@export var definition_id := ""
@export_enum("common", "rare", "top") var rarity_id := "common"
@export_range(1, 99, 1) var level := 1


func validation_errors(valid_equipment_ids: PackedStringArray, valid_rarity_ids: PackedStringArray, rarity_max_levels: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if instance_id.is_empty():
		errors.append("固定装备实例 ID 不能为空")
	if not valid_equipment_ids.has(definition_id):
		errors.append("固定奖励引用了未知装备：%s" % definition_id)
	if not valid_rarity_ids.has(rarity_id):
		errors.append("固定奖励品质无效：%s" % rarity_id)
	elif level < 1 or level > int(rarity_max_levels.get(rarity_id, 0)):
		errors.append("固定奖励等级超出 %s 品质上限" % rarity_id)
	return errors


func to_dictionary() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"rarity": rarity_id,
		"level": level,
	}
