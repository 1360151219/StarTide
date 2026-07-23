extends RefCounted

const ATLAS := preload("res://assets/art/items/item_atlas.png")
const CELL_SIZE := Vector2(384.0, 512.0)
const CELL_BY_ID := {
	"star_core": Vector2i(0, 0),
	"flow_feather": Vector2i(1, 0),
	"energy_prism": Vector2i(2, 0),
	"time_gear": Vector2i(3, 0),
	"echo_lens": Vector2i(0, 1),
	"star_bell": Vector2i(1, 1),
	"haste_leaf": Vector2i(2, 1),
	"star_bomb": Vector2i(3, 1),
}


static func texture(content_id: String) -> Texture2D:
	if not CELL_BY_ID.has(content_id):
		return null
	var cell: Vector2i = CELL_BY_ID[content_id]
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = Rect2(Vector2(cell) * CELL_SIZE, CELL_SIZE)
	texture.filter_clip = true
	return texture
