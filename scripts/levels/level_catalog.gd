extends RefCounted

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const LEVELS: Array[LevelConfig] = [
	preload("res://levels/level_01_star_courtyard.tres"),
	preload("res://levels/level_02_dusk_corridor.tres"),
	preload("res://levels/level_03_meteor_core.tres"),
]


static func all() -> Array[LevelConfig]:
	return LEVELS.duplicate()


static func ids() -> PackedStringArray:
	var result := PackedStringArray()
	for level in LEVELS:
		result.append(level.level_id)
	return result


static func by_id(level_id: String) -> LevelConfig:
	for level in LEVELS:
		if level.level_id == level_id:
			return level
	return null


static func first() -> LevelConfig:
	return LEVELS[0]


static func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}
	var seen_orders: Dictionary = {}
	var seen_map_ids: Dictionary = {}
	var seen_reward_ids: Dictionary = {}
	for level in LEVELS:
		for message in level.validation_errors(EnemyCatalog.ids(), EnemyAbilityCatalog.ids()):
			errors.append("%s：%s" % [level.resource_path, message])
		if seen_ids.has(level.level_id):
			errors.append("关卡 ID 重复：%s" % level.level_id)
		if seen_orders.has(level.order):
			errors.append("关卡顺序重复：%d" % level.order)
		seen_ids[level.level_id] = true
		seen_orders[level.order] = true
		if level.map != null:
			if seen_map_ids.has(level.map.map_id):
				errors.append("地图 ID 重复：%s" % level.map.map_id)
			seen_map_ids[level.map.map_id] = true
		if level.reward != null:
			if seen_reward_ids.has(level.reward.reward_id):
				errors.append("奖励 ID 重复：%s" % level.reward.reward_id)
			seen_reward_ids[level.reward.reward_id] = true
	for level in LEVELS:
		if level.reward == null:
			continue
		var unlock_id: String = level.reward.unlock_level_id
		if not unlock_id.is_empty() and not seen_ids.has(unlock_id):
			errors.append("%s 解锁了不存在的关卡：%s" % [level.level_id, unlock_id])
	return errors
