extends RefCounted

const FORMULA_VERSION := 1
const BASE_POWER := 1000
const LEVEL_DAMAGE_WEIGHT := 20.0
const LEVEL_HEALTH_WEIGHT := 10.0
const SKILL_DAMAGE_WEIGHT := 8.0
const SKILL_HEALING_WEIGHT := 4.0
const SKILL_RANGE_WEIGHT := 3.0
const SKILL_PROJECTILE_SPEED_WEIGHT := 3.0
const SKILL_FREQUENCY_WEIGHT := 8.0
const EQUIPMENT_DAMAGE_WEIGHT := 20.0
const EQUIPMENT_HEALTH_WEIGHT := 10.0
const EQUIPMENT_FREQUENCY_WEIGHT := 18.0
const EQUIPMENT_MOVE_SPEED_WEIGHT := 6.0
const EQUIPMENT_RANGE_WEIGHT := 4.0
const EQUIPMENT_PROJECTILE_SPEED_WEIGHT := 2.0
const EQUIPMENT_PICKUP_RADIUS_WEIGHT := 1.0


static func bonus_percent(multiplier: float) -> float:
	return maxf(0.0, multiplier - 1.0) * 100.0


static func frequency_gain_percent(interval_multiplier: float) -> float:
	if interval_multiplier <= 0.0:
		return 0.0
	return maxf(0.0, 1.0 / interval_multiplier - 1.0) * 100.0
