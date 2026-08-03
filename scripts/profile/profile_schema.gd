extends RefCounted

const VERSION := 6
const HERO_PROGRESSION_VERSION := 3
const CONTENT_DISCOVERY_VERSION := 4
const HERO_XP_VERSION := 5
const EQUIPMENT_VERSION := 6
const DISCOVERY_CATEGORIES := ["enemies", "pickups", "skills", "skill_branches", "relics"]
const LEGACY_PUBLIC_CONTENT_V3 := {
	"enemies": ["green_grub", "slime", "bat", "brute"],
	"pickups": ["xp", "heart", "magnet"],
	"skills": [
		"star_lance", "sun_orbit", "frost_tide",
		"ember_volley", "meteor_rain", "phoenix_heart",
	],
	"skill_branches": [],
	"relics": [],
}
