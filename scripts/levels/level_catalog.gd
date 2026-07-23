extends RefCounted

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const LevelPresentationCatalog = preload("res://scripts/levels/level_presentation_catalog.gd")
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


static func resolved_content_pool(level_id: String) -> Dictionary:
	var lineage: Array[LevelConfig] = []
	var visited: Dictionary = {}
	var current := by_id(level_id)
	while current != null and not visited.has(current.level_id):
		lineage.push_front(current)
		visited[current.level_id] = true
		var parent_id: String = current.content_pool.inherit_from_level_id if current.content_pool != null else ""
		current = by_id(parent_id) if not parent_id.is_empty() else null
	var result := {"skill_ids": PackedStringArray(), "relic_ids": PackedStringArray()}
	for level in lineage:
		_append_unique(result["skill_ids"], level.content_pool.added_skill_ids)
		_append_unique(result["relic_ids"], level.content_pool.added_relic_ids)
	return result


static func debut_level_id(category: String, content_id: String) -> String:
	for level in LEVELS:
		if _level_introduces(level, category, content_id):
			return level.level_id
	return ""


static func level_content_ids(level_id: String, category: String) -> PackedStringArray:
	var level := by_id(level_id)
	if level == null:
		return PackedStringArray()
	var result := PackedStringArray()
	match category:
		"enemies":
			for stage in level.stages:
				for enemy_id in stage.enemy_weights:
					if float(stage.enemy_weights[enemy_id]) > 0.0 and not result.has(enemy_id):
						result.append(enemy_id)
			if level.elite.enabled and not result.has(level.elite.enemy_id):
				result.append(level.elite.enemy_id)
		"pickups":
			result.append("xp")
			for entry in level.loot.bonus_entries:
				if not result.has(entry.pickup_id):
					result.append(entry.pickup_id)
		"skills":
			return resolved_content_pool(level_id)["skill_ids"]
		"relics":
			return resolved_content_pool(level_id)["relic_ids"]
	return result


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
	for message in LevelPresentationCatalog.validation_errors(ids()):
		errors.append("关卡展示：%s" % message)
	for level in LEVELS:
		var presentation := LevelPresentationCatalog.by_id(level.level_id)
		if presentation == null:
			continue
		var level_enemy_ids := level_content_ids(level.level_id, "enemies")
		for enemy_id in presentation.featured_enemy_ids:
			if not level_enemy_ids.has(enemy_id):
				errors.append("关卡展示：%s 预览了池外怪物 %s" % [level.level_id, enemy_id])
	_validate_content_pools(errors, seen_ids)
	return errors


static func _validate_content_pools(errors: PackedStringArray, valid_level_ids: Dictionary) -> void:
	var introduced_skills: Dictionary = {}
	var introduced_relics: Dictionary = {}
	for level in LEVELS:
		if level.content_pool == null:
			continue
		var parent_id: String = level.content_pool.inherit_from_level_id
		if not parent_id.is_empty():
			if not valid_level_ids.has(parent_id):
				errors.append("%s 继承了不存在的内容池：%s" % [level.level_id, parent_id])
			elif by_id(parent_id).order >= level.order:
				errors.append("%s 的内容池只能继承更早关卡" % level.level_id)
		for skill_id in level.content_pool.added_skill_ids:
			if introduced_skills.has(skill_id):
				errors.append("技能重复声明首次出现：%s" % skill_id)
			if not SkillCatalog.has(skill_id):
				errors.append("内容池引用了未知技能：%s" % skill_id)
			introduced_skills[skill_id] = level.level_id
		for relic_id in level.content_pool.added_relic_ids:
			if introduced_relics.has(relic_id):
				errors.append("遗物重复声明首次出现：%s" % relic_id)
			if not RelicCatalog.has(relic_id):
				errors.append("内容池引用了未知遗物：%s" % relic_id)
			introduced_relics[relic_id] = level.level_id


static func _level_introduces(level: LevelConfig, category: String, content_id: String) -> bool:
	match category:
		"enemies", "pickups":
			return level_content_ids(level.level_id, category).has(content_id)
		"skills":
			return level.content_pool != null and level.content_pool.added_skill_ids.has(content_id)
		"relics":
			return level.content_pool != null and level.content_pool.added_relic_ids.has(content_id)
	return false


static func _append_unique(target: PackedStringArray, source: PackedStringArray) -> void:
	for content_id in source:
		if not target.has(content_id):
			target.append(content_id)
