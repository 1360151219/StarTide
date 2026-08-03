extends RefCounted

const SLOTS := ["weapon", "armor", "charm"]
const RARITIES := ["common", "rare", "top"]
const SLOT_META := {
	"weapon": {"name": "武器", "order": 0},
	"armor": {"name": "护甲", "order": 1},
	"charm": {"name": "饰品", "order": 2},
}
const RARITY_META := {
	"common": {"name": "普通", "order": 0, "stat_multiplier": 1.0, "max_level": 5, "drop_weight": 75},
	"rare": {"name": "稀有", "order": 1, "stat_multiplier": 1.35, "max_level": 10, "drop_weight": 20},
	"top": {"name": "顶级", "order": 2, "stat_multiplier": 1.75, "max_level": 15, "drop_weight": 5},
}
const STAT_IDS := [
	"damage_percent", "max_health_percent", "max_health_flat",
	"cooldown_reduction", "move_speed_percent", "range_percent",
	"projectile_speed_percent", "pickup_radius_percent",
]

const EQUIPMENT := {
	"apprentice_starwand": {
		"name": "启程星杖",
		"description": "稳定放大英雄技能的基础威力。",
		"icon": preload("res://assets/generated/equipment/apprentice_starwand.png"),
		"slot": "weapon",
		"default_rarity": "common",
		"base_stats": {"damage_percent": 0.05},
		"stats_per_enhance": {"damage_percent": 0.01},
	},
	"windstring_bow": {
		"name": "风弦短弓",
		"description": "提高技能威力与投射物飞行速度。",
		"icon": preload("res://assets/generated/equipment/windstring_bow.png"),
		"slot": "weapon",
		"default_rarity": "rare",
		"base_stats": {"damage_percent": 0.04, "projectile_speed_percent": 0.04},
		"stats_per_enhance": {"damage_percent": 0.008, "projectile_speed_percent": 0.006},
	},
	"meadow_guard": {
		"name": "风铃护衣",
		"description": "以柔韧叶纤维提升最大生命。",
		"icon": preload("res://assets/generated/equipment/meadow_guard.png"),
		"slot": "armor",
		"default_rarity": "common",
		"base_stats": {"max_health_percent": 0.08},
		"stats_per_enhance": {"max_health_percent": 0.015},
	},
	"crystal_vest": {
		"name": "彩晶背心",
		"description": "直接增加最大生命，并提供少量移速。",
		"icon": preload("res://assets/generated/equipment/crystal_vest.png"),
		"slot": "armor",
		"default_rarity": "rare",
		"base_stats": {"max_health_flat": 10.0, "move_speed_percent": 0.02},
		"stats_per_enhance": {"max_health_flat": 2.0},
	},
	"windbell_charm": {
		"name": "风铃叶坠",
		"description": "提高移动速度与拾取范围。",
		"icon": preload("res://assets/generated/equipment/windbell_charm.png"),
		"slot": "charm",
		"default_rarity": "common",
		"base_stats": {"move_speed_percent": 0.06, "pickup_radius_percent": 0.10},
		"stats_per_enhance": {"move_speed_percent": 0.006, "pickup_radius_percent": 0.015},
	},
	"timeglass_charm": {
		"name": "时砂棱镜",
		"description": "缩短技能间隔并扩大作用范围。",
		"icon": preload("res://assets/generated/equipment/timeglass_charm.png"),
		"slot": "charm",
		"default_rarity": "rare",
		"base_stats": {"cooldown_reduction": 0.04, "range_percent": 0.04},
		"stats_per_enhance": {"cooldown_reduction": 0.006, "range_percent": 0.006},
	},
}


static func ids() -> PackedStringArray:
	return PackedStringArray(EQUIPMENT.keys())


static func has(equipment_id: String) -> bool:
	return EQUIPMENT.has(equipment_id)


static func equipment(equipment_id: String) -> Dictionary:
	return EQUIPMENT.get(equipment_id, {})


static func slot(equipment_id: String) -> String:
	return str(equipment(equipment_id).get("slot", ""))


static func slot_name(slot_id: String) -> String:
	return str(SLOT_META.get(slot_id, {}).get("name", slot_id))


static func slot_order(slot_id: String) -> int:
	return int(SLOT_META.get(slot_id, {}).get("order", 99))


static func rarity_name(rarity_id: String) -> String:
	return str(RARITY_META.get(rarity_id, {}).get("name", rarity_id))


static func rarity_order(rarity_id: String) -> int:
	return int(RARITY_META.get(rarity_id, {}).get("order", -1))


static func default_rarity(equipment_id: String) -> String:
	return str(equipment(equipment_id).get("default_rarity", "common"))


static func rarity_multiplier(rarity_id: String) -> float:
	return float(RARITY_META.get(rarity_id, RARITY_META["common"])["stat_multiplier"])


static func max_level(rarity_id: String) -> int:
	return int(RARITY_META.get(rarity_id, RARITY_META["common"])["max_level"])


static func drop_weight(rarity_id: String) -> int:
	return int(RARITY_META.get(rarity_id, {}).get("drop_weight", 0))


static func resolved_stats(equipment_id: String, rarity_id: String, equipment_level: int) -> Dictionary:
	if not has(equipment_id):
		return {}
	var data: Dictionary = equipment(equipment_id)
	var safe_rarity := rarity_id if RARITIES.has(rarity_id) else default_rarity(equipment_id)
	var level := clampi(equipment_level, 1, max_level(safe_rarity))
	var result: Dictionary = data["base_stats"].duplicate(true)
	for stat_id in data["stats_per_enhance"]:
		result[stat_id] = float(result.get(stat_id, 0.0)) + float(data["stats_per_enhance"][stat_id]) * (level - 1)
	for stat_id in result:
		result[stat_id] = float(result[stat_id]) * rarity_multiplier(safe_rarity)
	return result


static func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	for rarity_id in RARITIES:
		var rarity: Dictionary = RARITY_META.get(rarity_id, {})
		if float(rarity.get("stat_multiplier", 0.0)) <= 0.0 or int(rarity.get("max_level", 0)) < 1 or int(rarity.get("drop_weight", 0)) < 1:
			errors.append("%s 品质配置无效" % rarity_id)
	for equipment_id in EQUIPMENT:
		var data: Dictionary = EQUIPMENT[equipment_id]
		if str(data.get("name", "")).is_empty():
			errors.append("%s 缺少名称" % equipment_id)
		if not SLOTS.has(str(data.get("slot", ""))):
			errors.append("%s 装备槽无效" % equipment_id)
		if not RARITIES.has(str(data.get("default_rarity", ""))):
			errors.append("%s 默认品质无效" % equipment_id)
		_validate_stats(errors, equipment_id, data.get("base_stats", {}))
		_validate_stats(errors, equipment_id, data.get("stats_per_enhance", {}))
	return errors


static func _validate_stats(errors: PackedStringArray, equipment_id: String, stats) -> void:
	if not stats is Dictionary:
		errors.append("%s 属性必须是字典" % equipment_id)
		return
	for stat_id in stats:
		if not STAT_IDS.has(str(stat_id)) or float(stats[stat_id]) < 0.0:
			errors.append("%s 属性无效：%s" % [equipment_id, stat_id])
