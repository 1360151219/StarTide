extends RefCounted

const QUALITY_TEXTURES := {
	"common": preload("res://assets/art/ui/character/quality_cell_common.png"),
	"rare": preload("res://assets/art/ui/character/quality_cell_rare.png"),
	"top": preload("res://assets/art/ui/character/quality_cell_top.png"),
}
const HERO_AVATARS := {
	"star_warden": preload("res://assets/art/characters/star_tide_warden.png"),
	"ember_ranger": preload("res://assets/art/characters/emberwing_ranger.png"),
}
const HERO_AVATAR_REGIONS := {
	"star_warden": Rect2(66, 10, 210, 185),
	"ember_ranger": Rect2(45, 8, 175, 175),
}


static func quality_texture(rarity_id: String) -> Texture2D:
	return QUALITY_TEXTURES.get(rarity_id, QUALITY_TEXTURES["common"])


static func hero_avatar_texture(hero_id: String) -> Texture2D:
	if not HERO_AVATARS.has(hero_id):
		return null
	var avatar := AtlasTexture.new()
	avatar.atlas = HERO_AVATARS[hero_id]
	avatar.region = HERO_AVATAR_REGIONS[hero_id]
	avatar.filter_clip = true
	return avatar
