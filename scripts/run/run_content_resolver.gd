extends RefCounted

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")


static func resolve(level_id: String, hero_id: String, records: RefCounted) -> Dictionary:
	var level_pool := LevelCatalog.resolved_content_pool(level_id)
	var skill_ids := PackedStringArray()
	for skill_id in level_pool["skill_ids"]:
		if _skill_matches_hero(skill_id, hero_id):
			_append_unique(skill_ids, skill_id)
	for skill_id in records.discovered_content_ids("skills"):
		if _skill_matches_hero(skill_id, hero_id):
			_append_unique(skill_ids, skill_id)
	_append_unique(skill_ids, SkillCatalog.signature_for_hero(hero_id))
	var relic_ids := PackedStringArray(level_pool["relic_ids"])
	for relic_id in records.discovered_content_ids("relics"):
		if RelicCatalog.has(relic_id):
			_append_unique(relic_ids, relic_id)
	return {"skill_ids": skill_ids, "relic_ids": relic_ids}


static func _skill_matches_hero(skill_id: String, hero_id: String) -> bool:
	return SkillCatalog.has(skill_id) and str(SkillCatalog.skill(skill_id)["owner_hero_id"]) == hero_id


static func _append_unique(target: PackedStringArray, content_id: String) -> void:
	if not content_id.is_empty() and not target.has(content_id):
		target.append(content_id)
