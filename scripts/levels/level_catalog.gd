extends RefCounted

const CampaignValidator = preload("res://scripts/levels/campaign_validator.gd")
const MANIFEST: CampaignManifest = preload("res://levels/campaign_main.tres")


static func manifest() -> CampaignManifest:
	return MANIFEST


static func all() -> Array[LevelConfig]:
	return MANIFEST.levels.duplicate()


static func ids() -> PackedStringArray:
	var result := PackedStringArray()
	for level in MANIFEST.levels:
		if level != null:
			result.append(level.level_id)
	return result


static func by_id(level_id: String) -> LevelConfig:
	for level in MANIFEST.levels:
		if level != null and level.level_id == level_id:
			return level
	return null


static func first() -> LevelConfig:
	return MANIFEST.levels[0] if not MANIFEST.levels.is_empty() else null


static func starter_equipment_reward() -> EquipmentRewardConfig:
	return MANIFEST.starter_equipment_reward


static func route_map_texture() -> Texture2D:
	return MANIFEST.route_map_texture


static func resolved_content_pool(level_id: String) -> Dictionary:
	var lineage := _content_lineage(level_id)
	var introduced_skills := PackedStringArray()
	var introduced_relics := PackedStringArray()
	var skill_entries: Dictionary = {}
	var relic_entries: Dictionary = {}
	for level in lineage:
		_append_unique(introduced_skills, level.content_pool.introduced_skill_ids)
		_append_unique(introduced_relics, level.content_pool.introduced_relic_ids)
		_merge_entries(skill_entries, level.content_pool.skill_entries)
		_merge_entries(relic_entries, level.content_pool.relic_entries)
	var current := by_id(level_id)
	if current == null or current.content_pool == null:
		return _empty_pool()
	return {
		"introduced_skill_ids": introduced_skills,
		"introduced_relic_ids": introduced_relics,
		"skill_ids": PackedStringArray(skill_entries.keys()),
		"relic_ids": PackedStringArray(relic_entries.keys()),
		"skill_entries": skill_entries.values(),
		"relic_entries": relic_entries.values(),
		"skill_pool_limit": current.content_pool.skill_pool_limit,
		"relic_pool_limit": current.content_pool.relic_pool_limit,
		"discovered_skill_slots": current.content_pool.discovered_skill_slots,
		"discovered_relic_slots": current.content_pool.discovered_relic_slots,
		"discovered_content_weight": current.content_pool.discovered_content_weight,
	}


static func debut_level_id(category: String, content_id: String) -> String:
	for level in MANIFEST.levels:
		if level != null and _level_introduces(level, category, content_id):
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
				_append_unique(result, stage.enemy_ids())
			if level.elite != null and level.elite.enabled:
				_append_unique(result, PackedStringArray([level.elite.enemy_id]))
			if level.boss != null and level.boss.enabled:
				_append_unique(result, PackedStringArray([level.boss.boss_id]))
		"pickups":
			result.append("xp")
			for entry in level.loot.bonus_entries:
				_append_unique(result, PackedStringArray([entry.pickup_id]))
		"skills":
			return resolved_content_pool(level_id)["introduced_skill_ids"]
		"relics":
			return resolved_content_pool(level_id)["introduced_relic_ids"]
	return result


static func validation_errors() -> PackedStringArray:
	return CampaignValidator.validation_errors(MANIFEST)


static func _content_lineage(level_id: String) -> Array[LevelConfig]:
	var lineage: Array[LevelConfig] = []
	var visited: Dictionary = {}
	var current := by_id(level_id)
	while current != null and not visited.has(current.level_id):
		lineage.push_front(current)
		visited[current.level_id] = true
		var parent_id: String = current.content_pool.inherit_from_level_id if current.content_pool != null else ""
		current = by_id(parent_id) if not parent_id.is_empty() else null
	return lineage


static func _merge_entries(target: Dictionary, entries: Array[WeightedContentEntryConfig]) -> void:
	for entry in entries:
		if entry == null or entry.content_id.is_empty():
			continue
		target[entry.content_id] = {
			"content_id": entry.content_id,
			"weight": entry.weight,
			"guaranteed": entry.guaranteed,
		}


static func _level_introduces(level: LevelConfig, category: String, content_id: String) -> bool:
	match category:
		"enemies", "pickups":
			return level_content_ids(level.level_id, category).has(content_id)
		"skills":
			return level.content_pool != null and level.content_pool.introduced_skill_ids.has(content_id)
		"relics":
			return level.content_pool != null and level.content_pool.introduced_relic_ids.has(content_id)
	return false


static func _append_unique(target: PackedStringArray, source: PackedStringArray) -> void:
	for content_id in source:
		if not target.has(content_id):
			target.append(content_id)


static func _empty_pool() -> Dictionary:
	return {
		"introduced_skill_ids": PackedStringArray(), "introduced_relic_ids": PackedStringArray(),
		"skill_ids": PackedStringArray(), "relic_ids": PackedStringArray(),
		"skill_entries": [], "relic_entries": [], "skill_pool_limit": 0, "relic_pool_limit": 0,
		"discovered_skill_slots": 0, "discovered_relic_slots": 0, "discovered_content_weight": 1.0,
	}
