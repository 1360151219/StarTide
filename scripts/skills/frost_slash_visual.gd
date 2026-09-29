extends Node2D

const CRYSTAL = preload("res://assets/art/skills/star_lance_core.png")
const NOISE = preload("res://scripts/skills/meteor_turbulence.tres")
const REVEAL_SHADER = preload("res://scripts/skills/frost_slash_reveal.gdshader")
const Runtime = preload("res://scripts/skills/star_skill_runtime.gd")
const SHARDS = preload("res://assets/art/skills/frost_tide_shards.png")
const ART := {
	"regular": preload("res://assets/art/skills/frost_slash_arc.png"),
	"ultimate_upper": preload("res://assets/art/skills/frost_slash_ultimate_upper.png"),
	"ultimate_lower": preload("res://assets/art/skills/frost_slash_ultimate_lower.png"),
}
const MASKS := {
	"regular": preload("res://assets/art/skills/frost_slash_arc_mask.png"),
	"ultimate_upper": preload("res://assets/art/skills/frost_slash_ultimate_upper_mask.png"),
	"ultimate_lower": preload("res://assets/art/skills/frost_slash_ultimate_lower_mask.png"),
}
const LEVEL_SCALE := [0.0, 0.9, 0.95, 1.0, 1.04, 1.0]
const LEVEL_INTENSITY := [0.0, 0.82, 0.9, 1.0, 1.08, 1.22]
const SHARD_COUNTS := [0, 3, 4, 4, 5, 7]

var player: Node2D
var kind := "regular"
var level := 1
var duration := 0.26
var elapsed := 0.0
var main_sprite: Sprite2D
var trail_sprite: Sprite2D


func configure(data: Dictionary, player_node: Node2D) -> void:
	player = player_node
	kind = str(data["kind"])
	level = int(data["level"])
	main_sprite = _create_sprite(ART[kind], MASKS[kind])
	trail_sprite = _create_sprite(ART[kind], MASKS[kind])
	trail_sprite.modulate = Color(0.45, 0.82, 1.0, 0.0)
	add_child(trail_sprite)
	add_child(main_sprite)
	_layout(data)
	refresh(data)


func refresh(data: Dictionary) -> void:
	duration = float(data["duration"])
	elapsed = maxf(0.0, duration - float(data["time_left"]))
	_update_sprite(main_sprite, elapsed, false)
	_update_sprite(trail_sprite, maxf(0.0, elapsed - 0.022), true)
	queue_redraw()


func _update_sprite(sprite: Sprite2D, at: float, trail: bool) -> void:
	var sweep := pow(clampf(at / Runtime.SLASH_HIT_DELAY, 0.0, 1.0), 1.65)
	var follow := 1.0 - exp(-maxf(at - Runtime.SLASH_HIT_DELAY, 0.0) / 0.065)
	var direction := -1.0 if kind == "ultimate_lower" else 1.0
	sprite.rotation = deg_to_rad(direction * (-28.0 * (1.0 - sweep) + 14.0 * follow))
	sprite.scale = Vector2(lerpf(0.82, 1.0, sweep) + 0.08 * follow, lerpf(0.62, 1.0, sweep) - 0.28 * follow)
	sprite.skew = direction * 0.08 * sin(sweep * PI)
	sprite.position = Vector2(-18.0 * (1.0 - sweep) + 16.0 * follow, direction * (-4.0 * (1.0 - sweep) + 2.0 * follow))
	var fade_start := Runtime.SLASH_HIT_DELAY + (0.035 if trail else 0.025)
	var fade := smoothstep(fade_start, duration, elapsed)
	var strength := _trail_strength() if trail else 0.88
	sprite.modulate.a = strength * smoothstep(0.0, 0.025, at) * (1.0 - fade)
	sprite.z_index = player.z_index - 1
	var material := sprite.material as ShaderMaterial
	material.set_shader_parameter("age", at)
	material.set_shader_parameter("sweep_progress", sweep)
	material.set_shader_parameter("dissolve_progress", smoothstep(fade_start, duration - 0.015, elapsed))
	material.set_shader_parameter("intensity", LEVEL_INTENSITY[level] * (0.55 if trail else 1.0))
	material.set_shader_parameter("motion_warp", direction * (0.24 * (1.0 - sweep) + follow * 0.07))
	material.set_shader_parameter("impact", smoothstep(0.045, Runtime.SLASH_HIT_DELAY, at) * (1.0 - smoothstep(Runtime.SLASH_HIT_DELAY, 0.125, at)))
	material.set_shader_parameter("safe_center_uv", sprite.to_local(player.global_position) / 512.0 + Vector2(0.5, 0.5))
	var world_scale := Vector2(sprite.global_transform.x.length(), sprite.global_transform.y.length())
	material.set_shader_parameter("safe_radius_uv", Vector2(26.0, 32.0) / (world_scale * 512.0))


func _layout(data: Dictionary) -> void:
	rotation = float(data["angle"])
	var radius := float(data["radius"])
	if kind == "regular":
		var inner_radius := float(data["inner_radius"])
		var band := radius - inner_radius
		position = Vector2(data["origin"]) + Vector2.from_angle(rotation) * (inner_radius + band * 0.64)
		scale = Vector2.ONE * (band * 1.28 * LEVEL_SCALE[level] / 512.0)
	else:
		position = data["origin"]
		scale = Vector2.ONE * (radius * 2.55 / 512.0)


func _create_sprite(texture: Texture2D, mask: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_as_relative = false
	var material := ShaderMaterial.new()
	material.shader = REVEAL_SHADER
	material.set_shader_parameter("turbulence", NOISE)
	material.set_shader_parameter("crystal_material", CRYSTAL)
	material.set_shader_parameter("motion_mask", mask)
	material.set_shader_parameter("reverse", kind == "ultimate_lower")
	sprite.material = material
	return sprite


func _trail_strength() -> float:
	return [0.0, 0.1, 0.14, 0.18, 0.22, 0.26][level]


func _draw() -> void:
	var shard_count: int = SHARD_COUNTS[level]
	var shard_origin := Vector2(222, -112)
	var direction := Vector2(1.0, -0.18).normalized()
	if kind == "ultimate_upper":
		shard_origin = Vector2(187, -66)
		direction = Vector2(1.0, 0.1).normalized()
	elif kind == "ultimate_lower":
		shard_origin = Vector2(-181, 78)
		direction = Vector2(-1.0, -0.12).normalized()
	var tile_size := Vector2(SHARDS.get_size()) / Vector2(4, 1)
	for index in range(shard_count):
		var shard_time := clampf((elapsed - Runtime.SLASH_HIT_DELAY - index * 0.006) / (duration - Runtime.SLASH_HIT_DELAY - index * 0.006), 0.0, 1.0)
		if shard_time <= 0.0 or shard_time >= 1.0:
			continue
		var side := float(index) - float(shard_count - 1) * 0.5
		var launch := direction.rotated(side * 0.19)
		var travel := 1.0 - pow(1.0 - shard_time, 2.0)
		var center := shard_origin + launch * travel * (34.0 + index * 8.0) + Vector2(0, shard_time * shard_time * 18.0)
		var length := (15.0 if kind.begins_with("ultimate") else 26.0) + float(index % 3) * 5.0
		var alpha := smoothstep(0.0, 0.1, shard_time) * (1.0 - smoothstep(0.25, 1.0, shard_time))
		draw_set_transform(center, launch.angle() + side * shard_time * 0.8, Vector2.ONE * lerpf(1.0, 0.45, shard_time))
		draw_texture_rect_region(SHARDS, Rect2(Vector2.ONE * -length * 0.5, Vector2.ONE * length), Rect2(Vector2((index % 4) * tile_size.x, 0), tile_size), Color(0.8, 0.96, 1.0, alpha * 0.8))
	draw_set_transform(Vector2.ZERO)
