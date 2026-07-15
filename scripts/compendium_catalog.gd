extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")

const HERO_TEXTURES := {
	"star_warden": preload("res://assets/art/characters/star_tide_warden.png"),
	"ember_ranger": preload("res://assets/art/characters/emberwing_ranger.png"),
}

const PICKUP_TEXTURES := {
	"xp": preload("res://assets/art/pickups/experience_shard.png"),
	"heart": preload("res://assets/art/pickups/healing_heart.png"),
	"magnet": preload("res://assets/art/pickups/magnet_charm.png"),
}

const SKILL_TEXTURES := {
	"star_lance": preload("res://assets/art/skills/star_lance.png"),
	"sun_orbit": preload("res://assets/art/skills/sun_orbit.png"),
	"frost_tide": preload("res://assets/art/skills/frost_tide.png"),
	"ember_volley": preload("res://assets/art/skills/ember_volley.png"),
	"meteor_rain": preload("res://assets/art/skills/meteor_rain.png"),
	"phoenix_heart": preload("res://assets/art/skills/phoenix_heart.png"),
}

const PICKUPS := {
	"xp": {"name": "星辉碎片", "subtitle": "经验道具", "description": "怪物被击败后掉落。\n积满经验即可获得三选一强化。"},
	"heart": {"name": "治愈星心", "subtitle": "恢复道具", "description": "少量怪物会掉落。\n拾取后立即恢复 22 点生命。"},
	"magnet": {"name": "星引护符", "subtitle": "功能道具", "description": "稀有的功能型掉落。\n5 秒内大范围吸取所有道具。"},
}


static func entries(category: String) -> Array:
	match category:
		"heroes":
			return _hero_entries()
		"enemies":
			return _enemy_entries()
		"pickups":
			return _pickup_entries()
		_:
			return _skill_entries()


static func _hero_entries() -> Array:
	var result: Array = []
	for hero_id in HeroCatalog.HEROES:
		var hero: Dictionary = HeroCatalog.hero(hero_id)
		result.append({
			"name": hero["name"],
			"subtitle": "%s · 生命 %d · 移速 %d" % [hero["title"], hero["max_health"], hero["speed"]],
			"description": "%s\n固有 · %s：%s" % [hero["description"].replace("\n", "；"), hero["passive_name"], hero["passive_description"]],
			"texture": HERO_TEXTURES[hero_id],
			"accent": Color("70e8ff") if hero_id == "star_warden" else Color("ff9a62"),
		})
	return result


static func _enemy_entries() -> Array:
	var result: Array = []
	for enemy_id in EnemyCatalog.ids():
		var data := EnemyCatalog.enemy(enemy_id)
		var entry := {"name": data["name"], "subtitle": data["subtitle"], "description": data["description"]}
		entry["texture"] = data["front"]
		entry["accent"] = data["accent"]
		result.append(entry)
	return result


static func _pickup_entries() -> Array:
	var result: Array = []
	for pickup_id in PICKUPS:
		var entry: Dictionary = PICKUPS[pickup_id].duplicate()
		entry["texture"] = PICKUP_TEXTURES[pickup_id]
		entry["accent"] = Color("70e8ff") if pickup_id == "xp" else Color("f0647d") if pickup_id == "heart" else Color("f6d782")
		result.append(entry)
	return result


static func _skill_entries() -> Array:
	var result: Array = []
	for hero_id in HeroCatalog.HEROES:
		var hero: Dictionary = HeroCatalog.hero(hero_id)
		for skill_id in hero["skills"]:
			var skill: Dictionary = HeroCatalog.skill(skill_id)
			result.append({
				"name": skill["name"],
				"subtitle": "%s专属 · 终极：%s" % [hero["name"], skill["ultimate_name"]],
				"description": "I · %s\nII · %s\n终极 · %s" % [skill["descriptions"][1], skill["descriptions"][2], skill["descriptions"][3]],
				"texture": SKILL_TEXTURES[skill_id],
				"accent": Color("70e8ff") if hero_id == "star_warden" else Color("ff9a62"),
				"card_height": 246.0,
			})
	return result
