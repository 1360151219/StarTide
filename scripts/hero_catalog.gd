extends RefCounted

const HEROES := {
	"star_warden": {
		"name": "星潮守望者",
		"title": "星象术士",
		"description": "均衡的远程法师\n星枪、日轮与霜潮控场",
		"max_health": 100.0,
		"speed": 230.0,
		"skills": ["star_lance", "sun_orbit", "frost_tide"],
	},
	"ember_ranger": {
		"name": "烬羽",
		"title": "赤曜游侠",
		"description": "高速爆发型射手\n爆裂箭、陨星雨与自愈火环",
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
	},
}


static func hero(hero_id: String) -> Dictionary:
	return HEROES[hero_id]


static func skill(skill_id: String) -> Dictionary:
	return SKILLS[skill_id]
