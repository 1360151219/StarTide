extends RefCounted

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const MANIFEST: ContentManifestConfig = preload("res://content/heroes.tres")

static var HEROES: Dictionary = MANIFEST.as_dictionary()
static var SKILLS := SkillCatalog.SKILLS


static func ids() -> PackedStringArray:
	return PackedStringArray(HEROES.keys())


static func hero(hero_id: String) -> Dictionary:
	var data: Dictionary = HEROES[hero_id].duplicate(true)
	data["skills"] = Array(SkillCatalog.skills_for_hero(hero_id))
	return data


static func skill(skill_id: String) -> Dictionary:
	return SkillCatalog.skill(skill_id)
