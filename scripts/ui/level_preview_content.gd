extends RefCounted

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")


static func texture_for(presentation: LevelPresentationConfig) -> Texture2D:
	if presentation == null:
		return null
	if not presentation.preview_region.has_area():
		return presentation.preview_texture
	var atlas := AtlasTexture.new()
	atlas.atlas = presentation.preview_texture
	atlas.region = presentation.preview_region
	return atlas


static func apply_enemy_textures(nodes: Array[TextureRect], presentation: LevelPresentationConfig, unlocked: bool) -> void:
	if presentation == null or presentation.featured_enemy_ids.is_empty():
		for enemy in nodes:
			enemy.visible = false
		return
	for index in range(nodes.size()):
		var enemy_id: String = presentation.featured_enemy_ids[index % presentation.featured_enemy_ids.size()]
		nodes[index].texture = EnemyCatalog.enemy(enemy_id)["front"]
		nodes[index].modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.55)
		nodes[index].visible = true
