extends RefCounted

const IDS := ["slime", "bat", "brute"]

const ENEMIES := {
	"slime": {
		"name": "星蚀史莱姆", "subtitle": "基础魔物",
		"description": "缓慢逼近的星蚀凝胶。\n生命与威胁均衡，最为常见。",
		"health": 36.0, "speed": 78.5, "damage": 9.0, "radius": 18.0, "experience": 8,
		"color": Color("ef718d"), "accent": Color("ef718d"),
		"front": preload("res://assets/art/enemies/starblight_slime.png"),
		"side": preload("res://assets/art/enemies/starblight_slime_side.png"),
	},
	"bat": {
		"name": "暮翼蝠", "subtitle": "高速魔物",
		"description": "轻盈却危险的高速飞行魔物。\n生命较低，擅长穿过技能空隙。",
		"health": 22.0, "speed": 128.0, "damage": 7.0, "radius": 14.0, "experience": 6,
		"color": Color("b889ff"), "accent": Color("b889ff"),
		"front": preload("res://assets/art/enemies/duskwing_bat.png"),
		"side": preload("res://assets/art/enemies/duskwing_bat_side.png"),
	},
	"brute": {
		"name": "陨岩巨怪", "subtitle": "重型魔物",
		"description": "披着陨岩外壳的重型魔物。\n生命和接触伤害都很高。",
		"health": 105.0, "speed": 50.0, "damage": 16.0, "radius": 28.0, "experience": 16,
		"color": Color("ff9f5a"), "accent": Color("ff9f5a"),
		"front": preload("res://assets/art/enemies/meteor_brute.png"),
		"side": preload("res://assets/art/enemies/meteor_brute_side.png"),
	},
}


static func enemy(enemy_id: String) -> Dictionary:
	return ENEMIES[enemy_id]


static func ids() -> PackedStringArray:
	return PackedStringArray(IDS)
