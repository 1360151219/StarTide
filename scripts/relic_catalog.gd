extends RefCounted

const ITEM_ATLAS := preload("res://assets/art/items/item_atlas.png")
const MANIFEST: ContentManifestConfig = preload("res://content/relics.tres")
static var RELICS: Dictionary = MANIFEST.as_dictionary()


static func ids() -> PackedStringArray:
	return PackedStringArray(RELICS.keys())


static func has(relic_id: String) -> bool:
	return RELICS.has(relic_id)


static func relic(relic_id: String) -> Dictionary:
	return RELICS.get(relic_id, {})


static func icon(relic_id: String) -> AtlasTexture:
	return relic(relic_id).get("icon")


static func validation_errors() -> PackedStringArray:
	var errors := MANIFEST.validation_errors(PackedStringArray([
		"name", "description", "max_level", "modifiers_per_level", "acquire_effects", "icon",
	]))
	for relic_id in RELICS:
		var data: Dictionary = RELICS[relic_id]
		if int(data.get("max_level", 0)) <= 0:
			errors.append("%s 遗物等级上限无效" % relic_id)
		var relic_icon: AtlasTexture = data.get("icon")
		if relic_icon == null or relic_icon.atlas != ITEM_ATLAS:
			errors.append("%s 遗物图标没有使用统一图集" % relic_id)
	return errors
