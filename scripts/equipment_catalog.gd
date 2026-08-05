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
const MANIFEST: ContentManifestConfig = preload("res://content/equipment.tres")
static var EQUIPMENT: Dictionary = MANIFEST.as_dictionary()


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


static func content_tier(equipment_id: String) -> int:
	return int(equipment(equipment_id).get("content_tier", 1))


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
	var errors := MANIFEST.validation_errors(PackedStringArray([
		"name", "description", "icon", "slot", "content_tier", "default_rarity",
		"base_stats", "stats_per_enhance",
	]))
	for rarity_id in RARITIES:
		var rarity: Dictionary = RARITY_META.get(rarity_id, {})
		if float(rarity.get("stat_multiplier", 0.0)) <= 0.0 or int(rarity.get("max_level", 0)) < 1:
			errors.append("%s 品质配置无效" % rarity_id)
	for equipment_id in EQUIPMENT:
		var data: Dictionary = EQUIPMENT[equipment_id]
		if not SLOTS.has(str(data.get("slot", ""))):
			errors.append("%s 装备槽无效" % equipment_id)
		if int(data.get("content_tier", 0)) <= 0:
			errors.append("%s 内容阶级无效" % equipment_id)
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
