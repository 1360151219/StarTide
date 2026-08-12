extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const PickupCatalog = preload("res://scripts/pickup_catalog.gd")

const HERO_TEXTURES := {
	"star_warden": preload("res://assets/art/characters/star_tide_warden.png"),
	"ember_ranger": preload("res://assets/art/characters/emberwing_ranger.png"),
}

static func entries(category: String) -> Array:
	match category:
		"heroes":
			return _hero_entries()
		"enemies":
			return _enemy_entries()
		"pickups":
			return _pickup_entries()
		"skills":
			return _skill_entries()
		"relics":
			return _relic_entries()
	return []


static func _hero_entries() -> Array:
	var result: Array = []
	for hero_id in HeroCatalog.HEROES:
		var hero: Dictionary = HeroCatalog.hero(hero_id)
		result.append({
			"id": hero_id,
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
		var entry := {"id": enemy_id, "name": data["name"], "subtitle": data["subtitle"], "description": data["description"]}
		entry["texture"] = data["front"]
		entry["accent"] = data["accent"]
		result.append(entry)
	return result


static func _pickup_entries() -> Array:
	var result: Array = []
	for pickup_id in PickupCatalog.ids():
		var entry: Dictionary = PickupCatalog.pickup(pickup_id).duplicate()
		entry["id"] = pickup_id
		entry["texture"] = PickupCatalog.texture(pickup_id)
		result.append(entry)
	return result


static func _skill_entries() -> Array:
	var result: Array = []
	for skill_id in SkillCatalog.ids():
		var skill := SkillCatalog.skill(skill_id)
		var hero_id := str(skill["owner_hero_id"])
		var branches := SkillCatalog.branch_ids(skill_id)
		var branch_entries: Array = []
		for branch_id in branches:
			var branch := SkillCatalog.branch(skill_id, branch_id)
			branch_entries.append({"id": branch_id, "name": branch["name"], "description": branch["description"]})
		result.append({
			"id": skill_id,
			"name": skill["name"],
			"subtitle": "%s专属 · 终极：%s" % [HeroCatalog.hero(hero_id)["name"], skill["ultimate_name"]],
			"description": "I · %s\n终极 · %s" % [skill["descriptions"][1], skill["descriptions"][int(skill["max_level"])]],
			"branches": branch_entries,
			"texture": skill["icon"],
			"accent": Color("70e8ff") if hero_id == "star_warden" else Color("ff9a62"),
			"card_height": 310.0,
		})
	return result


static func _relic_entries() -> Array:
	var result: Array = []
	for relic_id in RelicCatalog.ids():
		var relic := RelicCatalog.relic(relic_id)
		result.append({
			"id": relic_id,
			"name": relic["name"],
			"subtitle": "局内遗物 · 最高 III 级",
			"description": "%s\n每局最多装备 4 种不同遗物。" % relic["description"],
			"texture": RelicCatalog.icon(relic_id),
			"accent": Color("f6d782"),
		})
	return result
