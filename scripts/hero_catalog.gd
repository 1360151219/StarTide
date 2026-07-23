extends RefCounted

const SkillCatalog = preload("res://scripts/skill_catalog.gd")

const HEROES := {
	"star_warden": {
		"name": "星潮守望者",
		"title": "星象术士",
		"description": "均衡的远程法师\n星枪、日轮与霜潮控场",
		"passive_name": "星潮结界",
		"passive_description": "抵挡下一次伤害，24 秒重新充能",
		"max_health": 100.0,
		"speed": 230.0,
	},
	"ember_ranger": {
		"name": "烬羽",
		"title": "赤曜游侠",
		"description": "高速爆发型射手\n爆裂箭、陨星雨与自愈火环",
		"passive_name": "燎原步",
		"passive_description": "持续移动进入疾行，技能冷却加快 18%",
		"max_health": 88.0,
		"speed": 258.0,
	},
}

const SKILLS := SkillCatalog.SKILLS


static func ids() -> PackedStringArray:
	return PackedStringArray(HEROES.keys())


static func hero(hero_id: String) -> Dictionary:
	var data: Dictionary = HEROES[hero_id].duplicate(true)
	data["skills"] = Array(SkillCatalog.skills_for_hero(hero_id))
	return data


static func skill(skill_id: String) -> Dictionary:
	return SkillCatalog.skill(skill_id)
