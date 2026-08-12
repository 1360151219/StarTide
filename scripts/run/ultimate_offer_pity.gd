extends RefCounted

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const OFFER_LIMIT := 2

var misses: Dictionary = {}


func reset() -> void:
	misses.clear()


func track_upgrade(skill_id: String, next_level: int, max_level: int) -> void:
	if next_level == max_level - 1:
		misses[skill_id] = 0
	elif next_level >= max_level:
		misses.erase(skill_id)


func due_skill_ids(skill_levels: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	for raw_skill_id in misses:
		var skill_id := str(raw_skill_id)
		if _is_ultimate_ready(skill_id, skill_levels) and int(misses[skill_id]) >= OFFER_LIMIT - 1:
			result.append(skill_id)
	result.sort()
	return result


func record_offer(choices: Array, skill_levels: Dictionary) -> void:
	for raw_skill_id in misses.keys():
		var skill_id := str(raw_skill_id)
		if not _is_ultimate_ready(skill_id, skill_levels):
			misses.erase(skill_id)
			continue
		var max_level := int(SkillCatalog.skill(skill_id)["max_level"])
		var offered := false
		for raw_choice in choices:
			var choice: Dictionary = raw_choice
			if str(choice.get("kind", "")) == "skill_upgrade" and str(choice.get("content_id", "")) == skill_id and int(choice.get("target_level", 0)) == max_level:
				offered = true
				break
		if offered:
			misses.erase(skill_id)
		else:
			misses[skill_id] = int(misses[skill_id]) + 1


func _is_ultimate_ready(skill_id: String, skill_levels: Dictionary) -> bool:
	return skill_levels.has(skill_id) and SkillCatalog.has(skill_id) and int(skill_levels[skill_id]) == int(SkillCatalog.skill(skill_id)["max_level"]) - 1
