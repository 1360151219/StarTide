extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const STARTER_REWARD_ID := "starter_equipment_v1"
const FIRST_CLEAR_REWARDS := {
	"level_01": "first_clear_level_01_equipment_v1",
	"level_02": "first_clear_level_02_equipment_v1",
	"level_03": "first_clear_level_03_equipment_v1",
}
const REWARDS := {
	"starter_equipment_v1": [
		{"instance_id": "starter-weapon", "definition_id": "apprentice_starwand", "rarity": "common", "level": 1},
		{"instance_id": "starter-armor", "definition_id": "meadow_guard", "rarity": "common", "level": 1},
		{"instance_id": "starter-charm", "definition_id": "windbell_charm", "rarity": "common", "level": 1},
	],
	"first_clear_level_01_equipment_v1": [
		{"instance_id": "clear-level-01-weapon", "definition_id": "windstring_bow", "rarity": "rare", "level": 1},
	],
	"first_clear_level_02_equipment_v1": [
		{"instance_id": "clear-level-02-armor", "definition_id": "crystal_vest", "rarity": "rare", "level": 1},
	],
	"first_clear_level_03_equipment_v1": [
		{"instance_id": "clear-level-03-charm", "definition_id": "timeglass_charm", "rarity": "rare", "level": 1},
	],
}


static func reward(reward_id: String) -> Array:
	return Array(REWARDS.get(reward_id, [])).duplicate(true)


static func first_clear_reward_id(level_id: String) -> String:
	return str(FIRST_CLEAR_REWARDS.get(level_id, ""))


static func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var instance_ids := {}
	for reward_id in REWARDS:
		for entry in REWARDS[reward_id]:
			var instance_id := str(entry.get("instance_id", ""))
			var definition_id := str(entry.get("definition_id", ""))
			var rarity_id := str(entry.get("rarity", ""))
			if instance_id.is_empty() or instance_ids.has(instance_id):
				errors.append("%s 装备实例 ID 无效或重复" % reward_id)
			instance_ids[instance_id] = true
			if not EquipmentCatalog.has(definition_id):
				errors.append("%s 引用了未知装备" % reward_id)
			if not EquipmentCatalog.RARITIES.has(rarity_id) or int(entry.get("level", 0)) < 1 or int(entry.get("level", 0)) > EquipmentCatalog.max_level(rarity_id):
				errors.append("%s 装备品质或等级无效" % reward_id)
	for level_id in FIRST_CLEAR_REWARDS:
		if not REWARDS.has(FIRST_CLEAR_REWARDS[level_id]):
			errors.append("%s 首通装备奖励不存在" % level_id)
	return errors
