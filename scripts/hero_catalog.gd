extends RefCounted

const HEROES := {
	"star_warden": {
		"name": "星潮守望者",
		"title": "星象术士",
		"description": "均衡的远程法师\n星枪、日轮与霜潮控场",
		"passive_name": "星潮结界",
		"passive_description": "抵挡下一次接触伤害，24 秒重新充能",
		"max_health": 100.0,
		"speed": 230.0,
		"skills": ["star_lance", "sun_orbit", "frost_tide"],
	},
	"ember_ranger": {
		"name": "烬羽",
		"title": "赤曜游侠",
		"description": "高速爆发型射手\n爆裂箭、陨星雨与自愈火环",
		"passive_name": "燎原步",
		"passive_description": "持续移动进入疾行，技能冷却加快 18%",
		"max_health": 88.0,
		"speed": 258.0,
		"skills": ["ember_volley", "meteor_rain", "phoenix_heart"],
	},
}

const SKILLS := {
	"star_lance": {
		"name": "星芒枪",
		"ultimate_name": "星陨万华",
		"descriptions": [
			"",
			"自动锁定最近的敌人发射星枪",
			"同时发射两枚，伤害与频率提升",
			"五枚高速星枪，可连续贯穿敌群",
		],
		"runtime": {
			"cooldown": [0.0, 0.92, 0.72, 0.48], "damage": [0.0, 22.0, 29.0, 36.0],
			"count": [0, 1, 2, 5], "speed": [0.0, 520.0, 520.0, 610.0],
			"radius": [0.0, 7.0, 7.0, 9.0], "pierce": [0, 0, 0, 2],
			"spread": [0.0, 0.13, 0.13, 0.19],
		},
	},
	"sun_orbit": {
		"name": "日轮守卫",
		"ultimate_name": "日冕圣环",
		"descriptions": [
			"",
			"召唤一颗绕身旋转的灼热日轮",
			"增加为两颗日轮，并提高接触伤害",
			"四颗巨大日轮高速环绕，持续绞杀",
		],
		"runtime": {
			"hit_interval": [0.0, 0.38, 0.38, 0.25], "count": [0, 1, 2, 4],
			"orbit_radius": [0.0, 68.0, 78.0, 92.0], "orb_radius": [0.0, 13.0, 13.0, 18.0],
			"damage": [0.0, 13.0, 19.0, 28.0], "spin_speed": [0.0, 2.2, 2.2, 3.0],
		},
	},
	"frost_tide": {
		"name": "霜潮脉冲",
		"ultimate_name": "时凝星海",
		"descriptions": [
			"",
			"周期释放寒潮，伤害并减速身边敌人",
			"扩大冲击范围，提升伤害并缩短间隔",
			"超大范围冻结，造成重击并大幅减速",
		],
		"runtime": {
			"cooldown": [0.0, 2.45, 1.95, 1.35], "radius": [0.0, 125.0, 165.0, 245.0],
			"damage": [0.0, 20.0, 32.0, 50.0], "slow_factor": [1.0, 0.58, 0.58, 0.28],
			"slow_duration": [0.0, 1.6, 1.6, 2.3],
		},
	},
	"ember_volley": {
		"name": "烬羽连矢",
		"ultimate_name": "百鸟朝阳",
		"descriptions": [
			"",
			"发射一枚命中后爆炸的火焰箭",
			"同时发射两枚，爆炸范围和伤害提升",
			"四枚贯穿爆裂箭形成持续火力扇面",
		],
		"runtime": {
			"cooldown": [0.0, 0.86, 0.66, 0.42], "damage": [0.0, 19.0, 26.0, 34.0],
			"count": [0, 1, 2, 4], "blast_radius": [0.0, 44.0, 57.0, 74.0],
			"speed": [0.0, 590.0, 590.0, 590.0], "radius": [0.0, 7.0, 7.0, 9.0],
			"pierce": [0, 0, 0, 1], "spread": [0.0, 0.16, 0.16, 0.22],
		},
	},
	"meteor_rain": {
		"name": "陨星雨",
		"ultimate_name": "天火坠世",
		"descriptions": [
			"",
			"周期轰击一处敌群，造成范围伤害",
			"同时轰击两处目标，范围和伤害提升",
			"连续锁定四处敌群降下大型陨星",
		],
		"runtime": {
			"cooldown": [0.0, 2.55, 1.9, 1.2], "count": [0, 1, 2, 4],
			"damage": [0.0, 32.0, 43.0, 62.0], "radius": [0.0, 62.0, 74.0, 96.0],
		},
	},
	"phoenix_heart": {
		"name": "凤凰之心",
		"ultimate_name": "不灭炎翼",
		"descriptions": [
			"",
			"周期释放火焰脉冲，并恢复少量生命",
			"扩大火环，提升伤害和治疗效果",
			"高速释放巨型凤凰火环并持续自愈",
		],
		"runtime": {
			"cooldown": [0.0, 3.1, 2.35, 1.55], "damage": [0.0, 17.0, 28.0, 45.0],
			"radius": [0.0, 105.0, 145.0, 205.0], "healing": [0.0, 2.0, 4.0, 7.0],
		},
	},
}


static func ids() -> PackedStringArray:
	return PackedStringArray(HEROES.keys())


static func hero(hero_id: String) -> Dictionary:
	return HEROES[hero_id]


static func skill(skill_id: String) -> Dictionary:
	return SKILLS[skill_id]
