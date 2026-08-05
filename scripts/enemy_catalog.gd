extends RefCounted

const ROLE_MELEE := "melee"
const ROLE_RANGED := "ranged"
const MANIFEST: ContentManifestConfig = preload("res://content/enemies.tres")
static var ENEMIES: Dictionary = MANIFEST.as_dictionary()


static func enemy(enemy_id: String) -> Dictionary:
	return ENEMIES.get(enemy_id, {})


static func ids() -> PackedStringArray:
	return PackedStringArray(ENEMIES.keys())


static func is_ranged(enemy_id: String) -> bool:
	return str(enemy(enemy_id).get("role", ROLE_MELEE)) == ROLE_RANGED


static func validation_errors() -> PackedStringArray:
	var errors := MANIFEST.validation_errors(PackedStringArray([
		"name", "role", "health", "speed", "damage", "radius", "experience", "front", "side",
	]))
	for enemy_id in ENEMIES:
		var data: Dictionary = ENEMIES[enemy_id]
		if str(data.get("role", "")) not in [ROLE_MELEE, ROLE_RANGED]:
			errors.append("%s 怪物角色无效" % enemy_id)
		for field in ["health", "speed", "damage", "radius", "experience"]:
			if float(data.get(field, 0.0)) <= 0.0:
				errors.append("%s 的 %s 必须大于 0" % [enemy_id, field])
	return errors
