extends RefCounted

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")

const SKILL_UNLOCK := "skill_unlock"
const SKILL_UPGRADE := "skill_upgrade"
const SKILL_BRANCH := "skill_branch"
const RELIC_UPGRADE := "relic_upgrade"
const UTILITY_RECOVERY := "utility_recovery"
const ROMAN_LEVELS := ["", "I", "II", "III", "IV", "V"]


static func skill_unlock(skill_id: String) -> Dictionary:
	var data := SkillCatalog.skill(skill_id)
	return {
		"choice_key": "skill:%s:unlock" % skill_id,
		"kind": SKILL_UNLOCK,
		"content_id": skill_id,
		"target_level": 1,
		"branch_id": "",
		"title": "%s I" % data["name"],
		"description": data["descriptions"][1],
	}


static func skill_upgrade(skill_id: String, target_level: int) -> Dictionary:
	var data := SkillCatalog.skill(skill_id)
	var display_name: String = data["ultimate_name"] if target_level == int(data["max_level"]) else data["name"]
	return {
		"choice_key": "skill:%s:level:%d" % [skill_id, target_level],
		"kind": SKILL_UPGRADE,
		"content_id": skill_id,
		"target_level": target_level,
		"branch_id": "",
		"title": "%s%s" % ["终极 · " if target_level == int(data["max_level"]) else "", display_name],
		"description": data["descriptions"][target_level],
	}


static func skill_branch(skill_id: String, branch_id: String, target_level: int) -> Dictionary:
	var data := SkillCatalog.skill(skill_id)
	var branch := SkillCatalog.branch(skill_id, branch_id)
	return {
		"choice_key": "skill:%s:branch:%s" % [skill_id, branch_id],
		"kind": SKILL_BRANCH,
		"content_id": skill_id,
		"target_level": target_level,
		"branch_id": branch_id,
		"title": "%s · %s" % [data["name"], branch["name"]],
		"description": branch["description"],
	}


static func relic_upgrade(relic_id: String, target_level: int) -> Dictionary:
	var data := RelicCatalog.relic(relic_id)
	return {
		"choice_key": "relic:%s:level:%d" % [relic_id, target_level],
		"kind": RELIC_UPGRADE,
		"content_id": relic_id,
		"target_level": target_level,
		"branch_id": "",
		"title": "%s %s" % [data["name"], level_mark(target_level, int(data["max_level"]), true)],
		"description": data["description"],
	}


static func recovery() -> Dictionary:
	return {
		"choice_key": "utility:recovery",
		"kind": UTILITY_RECOVERY,
		"content_id": "recovery",
		"target_level": 0,
		"branch_id": "",
		"title": "应急修复",
		"description": "恢复 45 点生命；满生命时最大生命 +10。",
	}


static func roman(value: int) -> String:
	if value >= 0 and value < ROMAN_LEVELS.size():
		return ROMAN_LEVELS[value]
	return str(value)


static func level_mark(value: int, maximum: int, use_max_label := false) -> String:
	if use_max_label and maximum > 0 and value >= maximum:
		return "MAX"
	return roman(value)
