extends RefCounted

const IDS := ["green_grub_roll", "bat_bolt"]

const ABILITIES := {
	"green_grub_roll": {
		"enemy_id": "green_grub", "hit_type": "grub_roll", "name": "团团滚",
		"warning": 0.65, "cooldown": 5.0, "min_range": 100.0, "max_range": 260.0,
		"speed": 185.0, "distance": 100.0, "damage": 7.0, "recovery": 0.45,
		"shape": "lane", "lane_width": 38.0,
	},
	"bat_bolt": {
		"enemy_id": "bat", "hit_type": "bat_bolt", "name": "暮翼光弹",
		"warning": 0.9, "lock_time": 0.3, "cooldown": 4.5,
		"min_range": 140.0, "max_range": 480.0, "projectile_speed": 260.0,
		"projectile_radius": 11.0, "projectile_distance": 520.0,
		"damage": 6.0, "recovery": 0.4, "shape": "dashed_line",
	},
}

const ENEMY_ABILITIES := {
	"green_grub": "green_grub_roll",
	"bat": "bat_bolt",
}

const THREAT_MULTIPLIERS := {
	"green_grub": 1.10,
	"bat": 1.25,
}


static func ability(ability_id: String) -> Dictionary:
	return ABILITIES[ability_id]


static func ability_for_enemy(enemy_id: String) -> String:
	return ENEMY_ABILITIES.get(enemy_id, "")


static func threat_multiplier(enemy_id: String) -> float:
	return float(THREAT_MULTIPLIERS.get(enemy_id, 1.0))


static func ids() -> PackedStringArray:
	return PackedStringArray(IDS)
