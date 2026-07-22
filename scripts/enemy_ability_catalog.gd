extends RefCounted

const IDS := ["green_grub_roll", "slime_jump", "bat_bolt", "brute_slam"]

const ABILITIES := {
	"green_grub_roll": {
		"enemy_id": "green_grub", "hit_type": "grub_roll", "name": "团团滚",
		"warning": 0.65, "cooldown": 5.0, "min_range": 100.0, "max_range": 260.0,
		"speed": 185.0, "distance": 100.0, "damage": 7.0, "recovery": 0.45,
		"shape": "lane", "lane_width": 38.0,
	},
	"slime_jump": {
		"enemy_id": "slime", "hit_type": "slime_jump", "name": "果冻弹跳",
		"warning": 0.8, "cooldown": 6.0, "min_range": 70.0, "max_range": 230.0,
		"jump_distance": 120.0, "execute_time": 0.28, "radius": 56.0,
		"damage": 9.0, "recovery": 0.55, "shape": "circle",
	},
	"bat_bolt": {
		"enemy_id": "bat", "hit_type": "bat_bolt", "name": "暮翼光弹",
		"warning": 0.9, "lock_time": 0.3, "cooldown": 4.5,
		"min_range": 140.0, "max_range": 480.0, "projectile_speed": 260.0,
		"projectile_radius": 11.0, "projectile_distance": 520.0,
		"damage": 6.0, "recovery": 0.4, "shape": "dashed_line",
	},
	"brute_slam": {
		"enemy_id": "brute", "hit_type": "brute_slam", "name": "陨岩拍击",
		"warning": 1.15, "cooldown": 7.0, "min_range": 0.0, "max_range": 150.0,
		"length": 112.0, "half_angle": PI * 0.25, "damage": 14.0,
		"knockback": 60.0, "recovery": 0.8, "shape": "sector",
	},
}

const ENEMY_ABILITIES := {
	"green_grub": "green_grub_roll",
	"slime": "slime_jump",
	"bat": "bat_bolt",
	"brute": "brute_slam",
}

const THREAT_MULTIPLIERS := {
	"green_grub": 1.10,
	"slime": 1.15,
	"bat": 1.25,
	"brute": 1.20,
}


static func ability(ability_id: String) -> Dictionary:
	return ABILITIES[ability_id]


static func ability_for_enemy(enemy_id: String) -> String:
	return ENEMY_ABILITIES.get(enemy_id, "")


static func threat_multiplier(enemy_id: String) -> float:
	return float(THREAT_MULTIPLIERS.get(enemy_id, 1.0))


static func ids() -> PackedStringArray:
	return PackedStringArray(IDS)
