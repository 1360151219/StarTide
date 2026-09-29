extends Node2D

const CORE = preload("res://assets/art/skills/star_lance_core.png")
const FEATHER = preload("res://assets/art/skills/ember_volley_feather.png")
const SHARDS = preload("res://assets/art/skills/frost_tide_shards.png")
const EMBERS = preload("res://assets/art/skills/ember_fragments.png")
const NOISE = preload("res://scripts/skills/meteor_turbulence.tres")
const MATERIAL = preload("res://scripts/skills/projectile_material.gdshader")

var projectile: Node2D
var body: Sprite2D
var wake: Sprite2D
var fiery := false
var body_size := Vector2.ONE
var tail_size := Vector2.ONE


func configure(source: Node2D) -> void:
	projectile = source
	fiery = source.visual_kind == "ember_arrow"
	var level: int = source.skill_level
	if fiery:
		var length: float = [0.0, 49.0, 51.0, 53.0, 56.0, 60.0][level]
		body_size = Vector2(length, length * 0.34)
		if source.branch_id == "ember_volley_blast": body_size *= Vector2(1.08, 1.16)
		if source.branch_id == "ember_volley_flock": body_size *= Vector2(0.94, 0.88)
		if level == 5 and source.volley_index == source.volley_count / 2: body_size *= 1.1
	else:
		# Transparent padding is included; the four-facet core stays on the collision axis.
		body_size = Vector2.ONE * (58.0 + level * 2.0)
		if source.branch_id == "star_lance_pierce": body_size *= Vector2(1.45, 1.1)
		if source.branch_id == "star_lance_fan": body_size *= Vector2(0.88, 0.85)
	tail_size = Vector2(body_size.x * (1.45 if source.branch_id == "star_lance_pierce" else 1.05), 26.0 if fiery else 22.0)
	wake = _sprite(NOISE, tail_size, true)
	body = _sprite(FEATHER if fiery else CORE, body_size, false)
	body.position.x = -body_size.x * (0.22 if fiery else 0.12)
	refresh()


func refresh() -> void:
	var age: float = projectile.age
	var travel: float = clampf(age * projectile.velocity.length() / 60.0, 0.0, 1.0)
	wake.position.x = -body_size.x * 0.26 - tail_size.x * travel * 0.4
	wake.scale.x = tail_size.x * maxf(travel, 0.001) / NOISE.get_width()
	wake.modulate.a = travel * (0.75 if fiery else 0.45)
	body.scale.y = body_size.y / body.texture.get_height() * lerpf(0.75, 1.0, smoothstep(0.0, 0.045, age))
	var hero: Vector2 = projectile.visual_player.global_position if is_instance_valid(projectile.visual_player) else Vector2(-100000, -100000)
	for sprite in [body, wake]:
		sprite.material.set_shader_parameter("age", age)
		sprite.material.set_shader_parameter("hero_position", hero)
	queue_redraw()


func _sprite(texture: Texture2D, size: Vector2, is_wake: bool) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = size / texture.get_size()
	var material := ShaderMaterial.new()
	material.shader = MATERIAL
	material.set_shader_parameter("turbulence", NOISE)
	material.set_shader_parameter("crystal_material", CORE)
	material.set_shader_parameter("fiery", fiery)
	material.set_shader_parameter("wake", is_wake)
	material.set_shader_parameter("variation", projectile.volley_index * 0.17)
	sprite.material = material
	add_child(sprite)
	return sprite


func _draw() -> void:
	if projectile == null: return
	var age: float = projectile.age
	var travel: float = clampf(age * projectile.velocity.length() / 60.0, 0.0, 1.0)
	for index in range(3):
		var drift := fposmod(age * (4.0 if fiery else 3.0) + index / 3.0, 1.0)
		var center := Vector2(-body_size.x * 0.3 - drift * tail_size.x * travel * 0.75, (1.0 if index % 2 else -1.0) * drift * 11.0)
		draw_set_transform(center, drift * (1.6 if index % 2 else -1.3))
		var size := Vector2(9, 5) * (1.0 - drift * 0.45)
		var protection := 1.0
		if is_instance_valid(projectile.visual_player): protection = smoothstep(24.0, 40.0, to_global(center).distance_to(projectile.visual_player.global_position + Vector2(0, -16)))
		draw_texture_rect_region(EMBERS if fiery else SHARDS, Rect2(-size * 0.5, size), Rect2(384 if fiery else (index % 4) * 128, 0, 128, 128), Color(1, 1, 1, (1.0 - drift) * travel * 0.8 * protection))
	draw_set_transform(Vector2.ZERO)
