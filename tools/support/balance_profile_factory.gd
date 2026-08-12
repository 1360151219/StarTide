extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")

const PROFILE_IDS := ["base", "early", "mid", "late", "max"]
const PROFILES := {
	"base": {"hero_xp": 0, "training": [0, 0, 0], "rarity": "", "equipment_level": 0},
	"early": {"hero_xp": 200, "training": [1, 0, 0], "rarity": "common", "equipment_level": 1},
	"mid": {"hero_xp": 400, "training": [2, 1, 0], "rarity": "rare", "equipment_level": 5},
	"late": {"hero_xp": 700, "training": [3, 1, 0], "rarity": "rare", "equipment_level": 10},
	"max": {"hero_xp": 900, "training": [3, 2, 0], "rarity": "top", "equipment_level": 15},
}
const EQUIPMENT_BY_SLOT := {
	"weapon": "windstring_bow",
	"armor": "crystal_vest",
	"charm": "timeglass_charm",
}


static func ids() -> PackedStringArray:
	return PackedStringArray(PROFILE_IDS)


static func create(hero_id: String, profile_id: String) -> RefCounted:
	var records := RunRecords.new("")
	var profile: Dictionary = PROFILES.get(profile_id, PROFILES["base"])
	var skill_ids := SkillCatalog.skills_for_hero(hero_id)
	var training := {}
	for index in range(skill_ids.size()):
		training[skill_ids[index]] = int(profile["training"][index])
	records.hero_progressions[hero_id] = {"hero_xp": int(profile["hero_xp"]), "training": training}
	_discover_complete_pool(records, skill_ids)
	_equip_profile(records, hero_id, profile_id, profile)
	return records


static func _discover_complete_pool(records: RefCounted, hero_skill_ids: PackedStringArray) -> void:
	for skill_id in hero_skill_ids:
		records.discovery.discover("skills", skill_id)
	for relic_id in RelicCatalog.ids():
		records.discovery.discover("relics", relic_id)
	records.discovery.clear_new_discoveries()


static func _equip_profile(records: RefCounted, hero_id: String, profile_id: String, profile: Dictionary) -> void:
	var rarity_id := str(profile["rarity"])
	if rarity_id.is_empty():
		return
	for slot_id in EquipmentCatalog.SLOTS:
		var instance_id := "benchmark_%s_%s" % [profile_id, slot_id]
		var definition_id := str(EQUIPMENT_BY_SLOT[slot_id])
		var grant: Dictionary = records.equipment.grant(instance_id, definition_id, rarity_id, int(profile["equipment_level"]))
		if bool(grant.get("success", false)):
			records.equipment.equip(hero_id, instance_id)
