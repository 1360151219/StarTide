extends RefCounted

const ItemIconAtlas = preload("res://scripts/presentation/item_icon_atlas.gd")
const ITEM_ATLAS := ItemIconAtlas.ATLAS

const RELICS := {
	"star_core": {
		"name": "星核扩容",
		"description": "最大生命 +15；获得时恢复 15 点生命。",
		"max_level": 3,
		"modifiers_per_level": {"max_health_flat": 15.0},
		"acquire_effects": {"heal": 15.0},
	},
	"flow_feather": {
		"name": "流光羽",
		"description": "移动速度 +8%。",
		"max_level": 3,
		"modifiers_per_level": {"move_speed_multiplier": 0.08},
		"acquire_effects": {},
	},
	"energy_prism": {
		"name": "聚能棱晶",
		"description": "全部技能伤害 +7%。",
		"max_level": 3,
		"modifiers_per_level": {"damage_multiplier": 0.07},
		"acquire_effects": {},
	},
	"time_gear": {
		"name": "时砂齿轮",
		"description": "技能冷却与命中间隔 -5%。",
		"max_level": 3,
		"modifiers_per_level": {"cooldown_multiplier": -0.05, "hit_interval_multiplier": -0.05},
		"acquire_effects": {},
	},
	"echo_lens": {
		"name": "回响透镜",
		"description": "技能范围与爆炸半径 +8%。",
		"max_level": 3,
		"modifiers_per_level": {"range_multiplier": 0.08},
		"acquire_effects": {},
	},
	"star_bell": {
		"name": "星引铃",
		"description": "普通拾取范围 +25%。",
		"max_level": 3,
		"modifiers_per_level": {"pickup_radius_multiplier": 0.25},
		"acquire_effects": {},
	},
}


static func ids() -> PackedStringArray:
	return PackedStringArray(RELICS.keys())


static func has(relic_id: String) -> bool:
	return RELICS.has(relic_id)


static func relic(relic_id: String) -> Dictionary:
	return RELICS.get(relic_id, {})


static func icon(relic_id: String) -> AtlasTexture:
	return ItemIconAtlas.texture(relic_id)
