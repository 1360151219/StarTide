extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const HeroProgression = preload("res://scripts/profile/hero_progression.gd")
const ProfileSchema = preload("res://scripts/profile/profile_schema.gd")


static func build(hero_ids: PackedStringArray, level_ids: PackedStringArray) -> Dictionary:
	var profile := {
		"schema_version": ProfileSchema.VERSION,
		"profile_id": "",
		"revision": 0,
		"last_hero_id": hero_ids[0],
		"active_hero_id": hero_ids[0],
		"last_level_id": level_ids[0],
		"records": {},
		"level_records": {},
		"unlocked_levels": {},
		"hero_progressions": {},
		"discovered_content": empty_discovered_content(),
		"equipment_inventory": {},
		"equipment_loadouts": {},
		"granted_reward_ids": {},
		"next_equipment_sequence": 1,
	}
	for hero_id in hero_ids:
		profile["records"][hero_id] = empty_record()
		profile["hero_progressions"][hero_id] = HeroProgression.default_progress(hero_id)
		profile["equipment_loadouts"][hero_id] = empty_loadout()
	for level_id in level_ids:
		profile["level_records"][level_id] = empty_record()
		profile["unlocked_levels"][level_id] = level_id == level_ids[0]
	return profile


static func empty_record() -> Dictionary:
	return {"runs": 0, "wins": 0, "elite_kills": 0, "best_kills": 0, "best_level": 0, "best_survival_ms": 0}


static func empty_loadout() -> Dictionary:
	var result := {}
	for slot_id in EquipmentCatalog.SLOTS:
		result[slot_id] = ""
	return result


static func empty_discovered_content() -> Dictionary:
	var result := {}
	for category in ProfileSchema.DISCOVERY_CATEGORIES:
		result[category] = {}
	return result
