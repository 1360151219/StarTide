extends RefCounted

const ItemIconAtlas = preload("res://scripts/presentation/item_icon_atlas.gd")
const EXPERIENCE_TEXTURE := preload("res://assets/art/pickups/experience_shard.png")
const HEART_TEXTURE := preload("res://assets/art/pickups/healing_heart.png")
const MAGNET_TEXTURE := preload("res://assets/art/pickups/magnet_charm.png")

const PICKUPS := {
	"xp": {
		"name": "星辉碎片", "subtitle": "经验道具",
		"description": "怪物被击败后掉落，积满经验即可获得三选一强化。",
		"effect": "experience", "amount": 0.0, "duration": 0.0, "radius": 8.0,
		"size": Vector2(30.0, 32.0), "accent": Color("70e8ff"),
	},
	"heart": {
		"name": "治愈星心", "subtitle": "恢复道具",
		"description": "恢复 20 点生命，每关拥有独立的掉落数量预算。",
		"effect": "heal", "amount": 20.0, "duration": 0.0, "radius": 13.0,
		"size": Vector2(35.4, 42.0), "accent": Color("f0647d"),
	},
	"magnet": {
		"name": "星引护符", "subtitle": "功能道具",
		"description": "5 秒内大范围吸取战场上的所有道具。",
		"effect": "magnet", "amount": 0.0, "duration": 5.0, "radius": 13.0,
		"size": Vector2(37.9, 50.0), "accent": Color("f6d782"),
	},
	"haste_leaf": {
		"name": "疾风叶", "subtitle": "限次增益道具",
		"description": "移动速度提高 20%，持续 6 秒；第二关首次出现。",
		"effect": "speed_boost", "amount": 0.20, "duration": 6.0, "radius": 13.0,
		"size": Vector2(43.0, 48.0), "accent": Color("83df45"),
	},
	"star_bomb": {
		"name": "星爆糖", "subtitle": "限次攻击道具",
		"description": "拾取后对 180 范围内的怪物造成 35 点伤害；第三关首次出现。",
		"effect": "area_damage", "amount": 35.0, "duration": 0.0, "effect_radius": 180.0,
		"radius": 13.0, "size": Vector2(45.0, 48.0), "accent": Color("ff8c4c"),
	},
}


static func ids() -> PackedStringArray:
	return PackedStringArray(PICKUPS.keys())


static func pickup(pickup_id: String) -> Dictionary:
	return PICKUPS.get(pickup_id, {})


static func texture(pickup_id: String) -> Texture2D:
	match pickup_id:
		"xp":
			return EXPERIENCE_TEXTURE
		"heart":
			return HEART_TEXTURE
		"magnet":
			return MAGNET_TEXTURE
		_:
			return ItemIconAtlas.texture(pickup_id)
