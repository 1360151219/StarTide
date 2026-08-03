extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const PowerRatingService = preload("res://scripts/profile/power_rating_service.gd")

const STAT_CAPS := {
	"damage_percent": 0.40,
	"max_health_percent": 0.55,
	"max_health_flat": 70.0,
	"cooldown_reduction": 0.25,
	"move_speed_percent": 0.35,
	"range_percent": 0.30,
	"projectile_speed_percent": 0.30,
	"pickup_radius_percent": 0.75,
}


static func resolve(hero_id: String, progression: Dictionary, equipment_inventory: RefCounted) -> Dictionary:
	var result := progression.duplicate(true)
	var equipment_stats := _equipment_stats(hero_id, equipment_inventory)
	var hero: Dictionary = HeroCatalog.hero(hero_id)
	var level_health := float(progression.get("health_multiplier", 1.0))
	var health_multiplier := level_health * (1.0 + float(equipment_stats["max_health_percent"]))
	health_multiplier += float(equipment_stats["max_health_flat"]) / maxf(1.0, float(hero["max_health"]))
	var damage_multiplier := float(progression.get("damage_multiplier", 1.0)) * (1.0 + float(equipment_stats["damage_percent"]))
	var cooldown_multiplier := 1.0 - float(equipment_stats["cooldown_reduction"])
	var range_multiplier := 1.0 + float(equipment_stats["range_percent"])
	var projectile_speed_multiplier := 1.0 + float(equipment_stats["projectile_speed_percent"])
	result["damage_multiplier"] = damage_multiplier
	result["health_multiplier"] = health_multiplier
	result["move_speed_multiplier"] = 1.0 + float(equipment_stats["move_speed_percent"])
	result["pickup_radius_multiplier"] = 1.0 + float(equipment_stats["pickup_radius_percent"])
	result["skill_modifiers"] = _skill_modifiers(
		progression.get("skill_modifiers", {}), 1.0 + float(equipment_stats["damage_percent"]),
		cooldown_multiplier, range_multiplier, projectile_speed_multiplier
	)
	result["base_stats"] = {"max_health": hero["max_health"], "speed": hero["speed"]}
	result["resolved_stats"] = {
		"max_health": float(hero["max_health"]) * health_multiplier,
		"speed": float(hero["speed"]) * float(result["move_speed_multiplier"]),
		"damage_multiplier": damage_multiplier,
		"cooldown_multiplier": cooldown_multiplier,
		"range_multiplier": range_multiplier,
		"projectile_speed_multiplier": projectile_speed_multiplier,
		"pickup_radius_multiplier": result["pickup_radius_multiplier"],
	}
	result["equipment"] = {
		"slots": EquipmentCatalog.SLOTS.duplicate(),
		"loadout": equipment_inventory.loadout_snapshot(hero_id),
		"equipped_items": equipment_inventory.equipped_items(hero_id),
		"inventory": equipment_inventory.inventory_rows(),
	}
	result["power"] = PowerRatingService.rate(hero_id, progression, equipment_stats)
	return result


static func _equipment_stats(hero_id: String, equipment_inventory: RefCounted) -> Dictionary:
	var result := {}
	for stat_id in EquipmentCatalog.STAT_IDS:
		result[stat_id] = 0.0
	for item in equipment_inventory.equipped_items(hero_id):
		for stat_id in item["stats"]:
			result[stat_id] = float(result.get(stat_id, 0.0)) + float(item["stats"][stat_id])
	for stat_id in STAT_CAPS:
		result[stat_id] = minf(float(result.get(stat_id, 0.0)), float(STAT_CAPS[stat_id]))
	return result


static func _skill_modifiers(raw_modifiers, damage_multiplier: float, cooldown_multiplier: float, range_multiplier: float, projectile_speed_multiplier: float) -> Dictionary:
	var result: Dictionary = raw_modifiers.duplicate(true) if raw_modifiers is Dictionary else {}
	for skill_id in result:
		var modifiers: Dictionary = result[skill_id]
		modifiers["damage_multiplier"] = float(modifiers.get("damage_multiplier", 1.0)) * damage_multiplier
		modifiers["cooldown_multiplier"] = float(modifiers.get("cooldown_multiplier", 1.0)) * cooldown_multiplier
		modifiers["hit_interval_multiplier"] = float(modifiers.get("hit_interval_multiplier", 1.0)) * cooldown_multiplier
		modifiers["range_multiplier"] = float(modifiers.get("range_multiplier", 1.0)) * range_multiplier
		modifiers["projectile_speed_multiplier"] = float(modifiers.get("projectile_speed_multiplier", 1.0)) * projectile_speed_multiplier
	return result
