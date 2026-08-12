extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const Config = preload("res://scripts/profile/power_rating_config.gd")


static func rate(hero_id: String, progression: Dictionary, equipment_stats: Dictionary) -> Dictionary:
	var level_power := _level_power(progression)
	var training_power := _training_power(progression)
	var equipment_power := _equipment_power(hero_id, equipment_stats)
	return {
		"formula_version": Config.FORMULA_VERSION,
		"purpose": "progression_score",
		"calibrated": false,
		"total": Config.BASE_POWER + level_power + training_power + equipment_power,
		"base": Config.BASE_POWER,
		"level": level_power,
		"training": training_power,
		"equipment": equipment_power,
	}


static func _level_power(progression: Dictionary) -> int:
	var damage_percent := Config.bonus_percent(float(progression.get("damage_multiplier", 1.0)))
	var health_percent := Config.bonus_percent(float(progression.get("health_multiplier", 1.0)))
	return roundi(damage_percent * Config.LEVEL_DAMAGE_WEIGHT + health_percent * Config.LEVEL_HEALTH_WEIGHT)


static func _training_power(progression: Dictionary) -> int:
	var score := 0.0
	var level_damage := maxf(0.001, float(progression.get("damage_multiplier", 1.0)))
	var modifiers: Dictionary = progression.get("skill_modifiers", {})
	for skill_id in modifiers:
		if not SkillCatalog.has(skill_id):
			continue
		var runtime: Dictionary = SkillCatalog.skill(skill_id).get("runtime", {})
		var skill_modifiers: Dictionary = modifiers[skill_id]
		var training_damage := float(skill_modifiers.get("damage_multiplier", level_damage)) / level_damage
		score += Config.bonus_percent(training_damage) * Config.SKILL_DAMAGE_WEIGHT
		if runtime.has("healing"):
			score += Config.bonus_percent(float(skill_modifiers.get("healing_multiplier", 1.0))) * Config.SKILL_HEALING_WEIGHT
		if runtime.has("radius") or runtime.has("orbit_radius"):
			score += Config.bonus_percent(float(skill_modifiers.get("range_multiplier", 1.0))) * Config.SKILL_RANGE_WEIGHT
		if runtime.has("speed"):
			score += Config.bonus_percent(float(skill_modifiers.get("projectile_speed_multiplier", 1.0))) * Config.SKILL_PROJECTILE_SPEED_WEIGHT
		var cadence_field := "hit_interval_multiplier" if runtime.has("hit_interval") else "cooldown_multiplier"
		score += Config.frequency_gain_percent(float(skill_modifiers.get(cadence_field, 1.0))) * Config.SKILL_FREQUENCY_WEIGHT
	return roundi(score)


static func _equipment_power(hero_id: String, stats: Dictionary) -> int:
	var base_health := float(HeroCatalog.hero(hero_id).get("max_health", 100.0))
	var health_percent := float(stats.get("max_health_percent", 0.0)) * 100.0
	health_percent += float(stats.get("max_health_flat", 0.0)) / maxf(1.0, base_health) * 100.0
	var interval_multiplier := 1.0 - float(stats.get("cooldown_reduction", 0.0))
	var score := float(stats.get("damage_percent", 0.0)) * 100.0 * Config.EQUIPMENT_DAMAGE_WEIGHT
	score += health_percent * Config.EQUIPMENT_HEALTH_WEIGHT
	score += Config.frequency_gain_percent(interval_multiplier) * Config.EQUIPMENT_FREQUENCY_WEIGHT
	score += float(stats.get("move_speed_percent", 0.0)) * 100.0 * Config.EQUIPMENT_MOVE_SPEED_WEIGHT
	score += float(stats.get("range_percent", 0.0)) * 100.0 * Config.EQUIPMENT_RANGE_WEIGHT
	score += float(stats.get("projectile_speed_percent", 0.0)) * 100.0 * Config.EQUIPMENT_PROJECTILE_SPEED_WEIGHT
	score += float(stats.get("pickup_radius_percent", 0.0)) * 100.0 * Config.EQUIPMENT_PICKUP_RADIUS_WEIGHT
	return roundi(score)
