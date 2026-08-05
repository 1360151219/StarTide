extends RefCounted

const MANIFEST: ContentManifestConfig = preload("res://content/pickups.tres")
const SUPPORTED_EFFECTS := ["experience", "heal", "magnet", "speed_boost", "area_damage"]
static var PICKUPS: Dictionary = MANIFEST.as_dictionary()


static func ids() -> PackedStringArray:
	return PackedStringArray(PICKUPS.keys())


static func pickup(pickup_id: String) -> Dictionary:
	return PICKUPS.get(pickup_id, {})


static func texture(pickup_id: String) -> Texture2D:
	return pickup(pickup_id).get("texture")


static func validation_errors() -> PackedStringArray:
	var errors := MANIFEST.validation_errors(PackedStringArray([
		"name", "effect", "amount", "duration", "radius", "size", "accent", "texture",
	]))
	for pickup_id in PICKUPS:
		var data: Dictionary = PICKUPS[pickup_id]
		if str(data.get("effect", "")) not in SUPPORTED_EFFECTS:
			errors.append("%s 道具效果没有运行时实现" % pickup_id)
		if float(data.get("radius", 0.0)) <= 0.0 or data.get("texture") == null:
			errors.append("%s 道具视觉配置无效" % pickup_id)
	return errors
