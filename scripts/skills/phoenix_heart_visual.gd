extends Node2D

const NOISE = preload("res://scripts/skills/meteor_turbulence.tres")
const REVEAL_SHADER = preload("res://scripts/skills/phoenix_wing_reveal.gdshader")
const FEATHER = preload("res://assets/art/skills/ember_volley_feather.png")
const WINGS = preload("res://assets/art/skills/phoenix_heart_wings.png")
const TEXTURE_SIZE := 1024.0
const IMPACT_TIME := preload("res://scripts/skills/ember_skill_runtime.gd").PHOENIX_IMPACT_TIME

var player: Node2D
var level := 1
var branch_id := ""
var duration := 0.42
var elapsed := 0.0
var left_main: Sprite2D
var right_main: Sprite2D
var left_trail: Sprite2D
var right_trail: Sprite2D


func configure(data: Dictionary, player_node: Node2D) -> void:
	player = player_node
	level = clampi(int(data["level"]), 1, 5)
	branch_id = str(data["branch_id"])
	position = Vector2(data["origin"])
	scale = Vector2.ONE * (float(data["radius"]) * 1.84 / TEXTURE_SIZE)
	z_as_relative = false
	left_trail = _create_wing(false, true)
	right_trail = _create_wing(true, true)
	left_main = _create_wing(false, false)
	right_main = _create_wing(true, false)
	for sprite in [left_trail, right_trail, left_main, right_main]:
		add_child(sprite)
	refresh(data)


func refresh(data: Dictionary) -> void:
	duration = float(data["duration"])
	elapsed = duration - float(data["time_left"])
	_update_wing(left_main, elapsed, false, false)
	_update_wing(right_main, elapsed, true, false)
	_update_wing(left_trail, maxf(0.0, elapsed - 0.027), false, true)
	_update_wing(right_trail, maxf(0.0, elapsed - 0.027), true, true)
	queue_redraw()


func _create_wing(right_side: bool, is_trail: bool) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = WINGS
	atlas.region = Rect2(512.0 if right_side else 0.0, 0.0, 512.0, 1024.0)
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = Vector2(0, 240)
	sprite.offset = Vector2(256.0 if right_side else -256.0, -240.0)
	sprite.z_as_relative = false
	sprite.z_index = player.z_index - 1
	if is_trail:
		sprite.modulate = Color(1.0, 0.38, 0.12, 0.0)
	var material := ShaderMaterial.new()
	material.shader = REVEAL_SHADER
	material.set_shader_parameter("turbulence", NOISE)
	material.set_shader_parameter("reverse", right_side)
	material.set_shader_parameter("region_start", 0.5 if right_side else 0.0)
	sprite.material = material
	return sprite


func _update_wing(sprite: Sprite2D, at: float, right_side: bool, trail: bool) -> void:
	var sweep := pow(clampf(at / IMPACT_TIME, 0.0, 1.0), 1.55)
	var settle := 1.0 - exp(-maxf(0.0, at - IMPACT_TIME) / 0.075)
	var side := 1.0 if right_side else -1.0
	var dissolve := clampf((elapsed - 0.235) / maxf(duration - 0.235, 0.01), 0.0, 1.0)
	sprite.rotation = side * deg_to_rad(19.0 * (1.0 - sweep) - 4.0 * settle)
	sprite.scale = Vector2(lerpf(0.48, 1.0, sweep) - settle * 0.06, lerpf(0.78, 1.0, sweep) - settle * 0.04)
	sprite.modulate.a = smoothstep(0.0, 0.045, at) * pow(1.0 - dissolve, 1.25) * (_trail_alpha() if trail else 0.86)
	var material := sprite.material as ShaderMaterial
	material.set_shader_parameter("age", at)
	material.set_shader_parameter("sweep_progress", sweep)
	material.set_shader_parameter("dissolve_progress", dissolve)
	material.set_shader_parameter("intensity", _intensity())
	material.set_shader_parameter("bend", side * (sin(sweep * PI) * 0.065 + settle * 0.018))
	material.set_shader_parameter("safe_center_uv", (sprite.to_local(player.global_position) - sprite.offset) / Vector2(512, 1024) + Vector2(0.5, 0.5))
	material.set_shader_parameter("safe_radius_uv", Vector2(26, 32) / (Vector2(512, 1024) * sprite.global_scale.abs()).max(Vector2.ONE))


func _intensity() -> float:
	var value: float = [0.0, 0.84, 0.94, 1.04, 1.14, 1.25][level]
	return value * (1.08 if branch_id == "phoenix_heart_inferno" else 0.98 if branch_id == "phoenix_heart_rebirth" else 1.0)


func _trail_alpha() -> float:
	var base := 0.28 if branch_id == "phoenix_heart_inferno" else 0.16 if branch_id == "phoenix_heart_rebirth" else 0.21
	return base * 0.48 * (1.18 if level >= 4 else 1.0)


func _draw() -> void:
	if elapsed >= 0.06:
		return
	var gather := sin(clampf(elapsed / 0.06, 0.0, 1.0) * PI)
	for side in [-1.0, 1.0]:
		var start := Vector2(side * lerpf(110.0, 38.0, elapsed / 0.06), 110.0)
		draw_set_transform(start, -PI * 0.5 + side * 0.35)
		draw_texture_rect(FEATHER, Rect2(-32, -10, 64, 20), false, Color(1.0, 0.85, 0.55, gather * 0.7))
	draw_set_transform(Vector2.ZERO)
