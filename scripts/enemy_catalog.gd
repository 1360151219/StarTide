extends RefCounted

const ROLE_MELEE := "melee"
const ROLE_RANGED := "ranged"
const IDS := ["green_grub", "slime", "bat", "brute"]

const ENEMIES := {
	"green_grub": {
		"name": "张姐蛆", "subtitle": "翠绒毛虫 · 一级魔物",
		"description": "看起来软绵绵，最喜欢把自己团起来冲出去。\n威胁很低，留意它滚动前的直线预警。",
		"role": ROLE_MELEE,
		"health": 30.0, "speed": 72.0, "damage": 6.0, "radius": 15.0, "experience": 5,
		"color": Color("78d84b"), "accent": Color("65c743"),
		"front": preload("res://assets/art/enemies/green_grub.png"),
		"side": preload("res://assets/art/enemies/green_grub_side.png"),
	},
	"slime": {
		"name": "星蚀史莱姆", "subtitle": "基础魔物",
		"description": "缓慢逼近的星蚀凝胶。\n生命与威胁均衡，最为常见。",
		"role": ROLE_MELEE,
		"health": 36.0, "speed": 78.5, "damage": 9.0, "radius": 18.0, "experience": 8,
		"color": Color("ef718d"), "accent": Color("ef718d"),
		"front": preload("res://assets/art/enemies/starblight_slime.png"),
		"side": preload("res://assets/art/enemies/starblight_slime_side.png"),
	},
	"bat": {
		"name": "暮翼蝠", "subtitle": "远程魔物",
		"description": "在远处盘旋并发射暮翼光弹。\n观察虚线预警，横向移动即可躲开。",
		"role": ROLE_RANGED,
		"health": 22.0, "speed": 116.0, "damage": 7.0, "radius": 14.0, "experience": 6,
		"color": Color("b889ff"), "accent": Color("b889ff"),
		"front": preload("res://assets/art/enemies/duskwing_bat.png"),
		"side": preload("res://assets/art/enemies/duskwing_bat_side.png"),
	},
	"brute": {
		"name": "陨岩巨怪", "subtitle": "重型魔物",
		"description": "披着陨岩外壳的重型魔物。\n生命和接触伤害都很高。",
		"role": ROLE_MELEE,
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


static func is_ranged(enemy_id: String) -> bool:
	return str(enemy(enemy_id).get("role", ROLE_MELEE)) == ROLE_RANGED
