extends RefCounted

const SKILLS := {
	"star_lance": {
		"name": "星芒枪",
		"ultimate_name": "星陨万华",
		"owner_hero_id": "star_warden",
		"is_signature": true,
		"max_level": 3,
		"branch_level": 2,
		"runtime_key": "star_lance",
		"icon": preload("res://assets/art/skills/star_lance.png"),
		"descriptions": ["", "自动锁定最近的敌人发射星枪", "同时发射两枚，伤害与频率提升", "三枚高速星枪形成密集星芒扇面"],
		"runtime": {
			"cooldown": [0.0, 0.92, 0.9, 0.88], "damage": [0.0, 22.0, 27.0, 31.0],
			"count": [0, 1, 2, 3], "speed": [0.0, 520.0, 560.0, 610.0],
			"radius": [0.0, 7.0, 7.0, 9.0], "pierce": [0, 0, 0, 0],
			"spread": [0.0, 0.13, 0.13, 0.19],
		},
		"branches": {
			"star_lance_fan": {
				"name": "星雨齐射", "description": "增加弹体与扇面宽度，强化群体覆盖。",
				"level_overrides": {
					2: {"count": 3, "damage_multiplier": 0.78, "spread": 0.18},
					3: {"count": 4, "damage_multiplier": 0.74, "spread": 0.22},
				},
			},
			"star_lance_pierce": {
				"name": "贯星长枪", "description": "减少散射，换取更高伤害与贯穿能力。",
				"level_overrides": {
					2: {"count": 1, "damage_multiplier": 1.35, "pierce": 1},
					3: {"count": 1, "damage_multiplier": 1.45, "pierce": 1},
				},
			},
		},
	},
	"sun_orbit": {
		"name": "日轮守卫",
		"ultimate_name": "日冕圣环",
		"owner_hero_id": "star_warden",
		"is_signature": false,
		"max_level": 3,
		"branch_level": 2,
		"runtime_key": "sun_orbit",
		"icon": preload("res://assets/art/skills/sun_orbit.png"),
		"descriptions": ["", "召唤一颗绕身旋转的灼热日轮", "增加为两颗日轮，并提高接触伤害", "四颗巨大日轮高速环绕，持续绞杀"],
		"runtime": {
			"hit_interval": [0.0, 0.38, 0.38, 0.34], "count": [0, 1, 2, 4],
			"orbit_radius": [0.0, 68.0, 78.0, 92.0], "orb_radius": [0.0, 13.0, 13.0, 18.0],
			"damage": [0.0, 12.0, 12.0, 12.0], "spin_speed": [0.0, 2.2, 2.2, 3.0],
		},
		"branches": {
			"sun_orbit_swarm": {
				"name": "群星环列", "description": "召唤更多小型日轮，提高覆盖密度。",
				"level_overrides": {
					2: {"count": 3, "damage_multiplier": 0.86, "spin_speed_multiplier": 1.08},
					3: {"count": 5, "damage_multiplier": 0.78, "spin_speed_multiplier": 1.18},
				},
			},
			"sun_orbit_giant": {
				"name": "巨日守御", "description": "凝聚少量巨型日轮，强化单次接触伤害。",
				"level_overrides": {
					2: {"count": 1, "orb_radius_multiplier": 1.42, "damage_multiplier": 1.55},
					3: {"count": 2, "orb_radius_multiplier": 1.58, "damage_multiplier": 1.72},
				},
			},
		},
	},
	"frost_tide": {
		"name": "霜潮脉冲",
		"ultimate_name": "时凝星海",
		"owner_hero_id": "star_warden",
		"is_signature": false,
		"max_level": 3,
		"branch_level": 2,
		"runtime_key": "frost_tide",
		"icon": preload("res://assets/art/skills/frost_tide.png"),
		"descriptions": ["", "周期释放寒潮，伤害并减速身边敌人", "扩大冲击范围，提升伤害并缩短间隔", "超大范围冻结，造成重击并大幅减速"],
		"runtime": {
			"cooldown": [0.0, 2.45, 1.95, 1.35], "radius": [0.0, 125.0, 165.0, 245.0],
			"damage": [0.0, 20.0, 32.0, 49.0], "slow_factor": [1.0, 0.58, 0.58, 0.28],
			"slow_duration": [0.0, 1.6, 1.6, 2.3],
		},
		"branches": {
			"frost_tide_field": {
				"name": "永冻冰原", "description": "扩大霜潮范围并延长减速时间。",
				"level_overrides": {
					2: {"radius_multiplier": 1.22, "slow_duration_multiplier": 1.22},
					3: {"radius_multiplier": 1.35, "slow_duration_multiplier": 1.38},
				},
			},
			"frost_tide_shatter": {
				"name": "碎星寒潮", "description": "牺牲单次伤害和范围，换取高频寒潮。",
				"level_overrides": {
					2: {"radius_multiplier": 0.84, "damage_multiplier": 0.86, "cooldown_multiplier": 0.86},
					3: {"radius_multiplier": 0.82, "damage_multiplier": 0.82, "cooldown_multiplier": 0.82},
				},
			},
		},
	},
	"ember_volley": {
		"name": "烬羽连矢",
		"ultimate_name": "百鸟朝阳",
		"owner_hero_id": "ember_ranger",
		"is_signature": true,
		"max_level": 3,
		"branch_level": 2,
		"runtime_key": "ember_volley",
		"icon": preload("res://assets/art/skills/ember_volley.png"),
		"descriptions": ["", "发射一枚命中后爆炸的火焰箭", "同时发射两枚，爆炸范围和伤害提升", "三枚大型爆裂箭形成持续火力扇面"],
		"runtime": {
			"cooldown": [0.0, 0.86, 0.78, 0.76], "damage": [0.0, 19.0, 23.0, 25.0],
			"count": [0, 1, 2, 3], "blast_radius": [0.0, 44.0, 57.0, 74.0],
			"speed": [0.0, 590.0, 590.0, 590.0], "radius": [0.0, 7.0, 7.0, 9.0],
			"pierce": [0, 0, 0, 0], "spread": [0.0, 0.16, 0.16, 0.22],
		},
		"branches": {
			"ember_volley_flock": {
				"name": "群羽纷飞", "description": "增加箭矢数量与扇面，清理成群敌人。",
				"level_overrides": {
					2: {"count": 3, "damage_multiplier": 0.72, "spread": 0.2},
					3: {"count": 5, "damage_multiplier": 0.58, "spread": 0.24},
				},
			},
			"ember_volley_blast": {
				"name": "爆心炽矢", "description": "集中火力，强化箭矢伤害与爆炸范围。",
				"level_overrides": {
					2: {"count": 1, "damage_multiplier": 1.38, "blast_radius_multiplier": 1.28},
					3: {"count": 2, "damage_multiplier": 1.45, "blast_radius_multiplier": 1.42},
				},
			},
		},
	},
	"meteor_rain": {
		"name": "陨星雨",
		"ultimate_name": "天火坠世",
		"owner_hero_id": "ember_ranger",
		"is_signature": false,
		"max_level": 3,
		"branch_level": 2,
		"runtime_key": "meteor_rain",
		"icon": preload("res://assets/art/skills/meteor_rain.png"),
		"descriptions": ["", "周期轰击一处敌群，造成范围伤害", "同时轰击两处目标，范围和伤害提升", "连续锁定三处敌群降下大型陨星"],
		"runtime": {
			"cooldown": [0.0, 2.55, 2.3, 2.05], "count": [0, 1, 2, 3],
			"damage": [0.0, 32.0, 33.0, 34.0], "radius": [0.0, 62.0, 74.0, 96.0],
		},
		"branches": {
			"meteor_rain_scatter": {
				"name": "流星群落", "description": "增加落点数量，分散轰击更多敌群。",
				"level_overrides": {
					2: {"count": 3, "damage_multiplier": 0.72, "radius_multiplier": 0.92},
					3: {"count": 5, "damage_multiplier": 0.64, "radius_multiplier": 0.88},
				},
			},
			"meteor_rain_focus": {
				"name": "天罚坠击", "description": "集中陨星轰击高威胁目标，强化单点爆发。",
				"level_overrides": {
					2: {"count": 1, "damage_multiplier": 1.72, "targeting": "elite_first"},
					3: {"count": 2, "damage_multiplier": 1.65, "targeting": "elite_first"},
				},
			},
		},
	},
	"phoenix_heart": {
		"name": "凤凰之心",
		"ultimate_name": "不灭炎翼",
		"owner_hero_id": "ember_ranger",
		"is_signature": false,
		"max_level": 3,
		"branch_level": 2,
		"runtime_key": "phoenix_heart",
		"icon": preload("res://assets/art/skills/phoenix_heart.png"),
		"descriptions": ["", "周期释放火焰脉冲，并恢复少量生命", "扩大火环，提升伤害和治疗效果", "高速释放巨型凤凰火环并持续自愈"],
		"runtime": {
			"cooldown": [0.0, 3.1, 2.35, 1.55], "damage": [0.0, 17.0, 26.0, 38.0],
			"radius": [0.0, 105.0, 145.0, 205.0], "healing": [0.0, 1.5, 2.0, 2.5],
		},
		"branches": {
			"phoenix_heart_rebirth": {
				"name": "涅槃余烬", "description": "降低单次治疗与伤害，换取更高释放频率。",
				"level_overrides": {
					2: {"healing_multiplier": 0.92, "damage_multiplier": 0.8, "cooldown_multiplier": 0.92},
					3: {"healing_multiplier": 0.9, "damage_multiplier": 0.75, "cooldown_multiplier": 0.88},
				},
			},
			"phoenix_heart_inferno": {
				"name": "焚天炎翼", "description": "牺牲部分治疗，扩大火环并提高伤害。",
				"level_overrides": {
					2: {"healing_multiplier": 0.72, "damage_multiplier": 1.05, "radius_multiplier": 1.18},
					3: {"healing_multiplier": 0.68, "damage_multiplier": 1.0, "radius_multiplier": 1.32},
				},
			},
		},
	},
}


static func ids() -> PackedStringArray:
	return PackedStringArray(SKILLS.keys())


static func has(skill_id: String) -> bool:
	return SKILLS.has(skill_id)


static func skill(skill_id: String) -> Dictionary:
	return SKILLS.get(skill_id, {})


static func skills_for_hero(hero_id: String) -> PackedStringArray:
	var result := PackedStringArray()
	for skill_id in SKILLS:
		if str(SKILLS[skill_id]["owner_hero_id"]) == hero_id:
			result.append(skill_id)
	return result


static func signature_for_hero(hero_id: String) -> String:
	for skill_id in SKILLS:
		var data: Dictionary = SKILLS[skill_id]
		if str(data["owner_hero_id"]) == hero_id and bool(data["is_signature"]):
			return skill_id
	return ""


static func branch(skill_id: String, branch_id: String) -> Dictionary:
	var data := skill(skill_id)
	if data.is_empty():
		return {}
	return data["branches"].get(branch_id, {})


static func branch_ids(skill_id: String) -> PackedStringArray:
	var data := skill(skill_id)
	if data.is_empty():
		return PackedStringArray()
	return PackedStringArray(data["branches"].keys())
