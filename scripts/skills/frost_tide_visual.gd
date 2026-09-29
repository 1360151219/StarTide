extends Node2D

const CRYSTAL = preload("res://assets/art/skills/star_lance_core.png")
const NOISE = preload("res://scripts/skills/meteor_turbulence.tres")
const REVEAL_SHADER = preload("res://scripts/skills/frost_tide_reveal.gdshader")
const WAVE = preload("res://assets/art/skills/frost_tide_wave.png")
const FIELD_WAVE = preload("res://assets/art/skills/frost_tide_field_wave.png")
const SHATTER_WAVE = preload("res://assets/art/skills/frost_tide_shatter_wave.png")
const STAR_CROWN = preload("res://assets/art/skills/frost_tide_star_crown.png")
const SHARDS = preload("res://assets/art/skills/frost_tide_shards.png")
const TEXTURE_RADIUS := 490.0
const TRAVEL_TIME := preload("res://scripts/skills/star_skill_runtime.gd").FROST_TRAVEL_TIME

var player: Node2D
var level := 1
var branch_id := ""
var radius := 125.0
var duration := 0.48
var elapsed := 0.0
var trail_sprite: Sprite2D
var main_sprite: Sprite2D
var crown_sprite: Sprite2D


func configure(data: Dictionary, player_node: Node2D) -> void:
	player = player_node
	level = int(data["level"])
	branch_id = str(data["branch_id"])
	radius = float(data["radius"])
	position = Vector2(data["origin"])
	z_as_relative = false
	z_index = player.z_index - 1
	var texture := _wave_texture()
	trail_sprite = _create_sprite(texture)
	main_sprite = _create_sprite(texture)
	add_child(trail_sprite)
	add_child(main_sprite)
	if level == 5:
		crown_sprite = _create_sprite(STAR_CROWN)
		add_child(crown_sprite)
	refresh(data)


func refresh(data: Dictionary) -> void:
	duration = float(data["duration"])
	elapsed = duration - float(data["time_left"])
	var wave_progress := clampf(elapsed / TRAVEL_TIME, 0.0, 1.0)
	var target_scale := radius / TEXTURE_RADIUS
	var main_scale := maxf(wave_progress, 0.002) * target_scale
	main_sprite.scale = Vector2.ONE * main_scale
	var trail_progress := clampf((elapsed - 0.022) / TRAVEL_TIME, 0.0, 1.0)
	trail_sprite.scale = Vector2.ONE * maxf(trail_progress, 0.002) * target_scale
	var regular_dissolve := clampf((elapsed - TRAVEL_TIME) / maxf(duration - TRAVEL_TIME, 0.01), 0.0, 1.0)
	var main_dissolve := clampf((elapsed - 0.3) / 0.08, 0.0, 1.0) if level == 5 else regular_dissolve
	_set_shader(main_sprite, wave_progress, main_dissolve, 0.16, _intensity(), _safe_center_uv(main_sprite))
	main_sprite.modulate.a = smoothstep(0.0, 0.045, elapsed) * (1.0 - main_dissolve) * 0.74
	var trail_dissolve := clampf((elapsed - 0.34) / maxf(duration - 0.34, 0.01), 0.0, 1.0)
	_set_shader(trail_sprite, trail_progress, trail_dissolve, 0.32, _intensity() * 0.72, _safe_center_uv(trail_sprite))
	trail_sprite.modulate = Color(0.48, 0.88, 1.0, _trail_strength() * 0.55 * clampf(elapsed / 0.05, 0.0, 1.0) * (1.0 - trail_dissolve))
	if crown_sprite != null:
		_update_crown(target_scale)
	queue_redraw()


func _update_crown(target_scale: float) -> void:
	var reveal := clampf((elapsed - 0.28) / 0.08, 0.0, 1.0)
	var crack_duration := 0.135 if branch_id == "frost_tide_shatter" else 0.205
	var dissolve := clampf((elapsed - 0.415) / crack_duration, 0.0, 1.0)
	crown_sprite.scale = Vector2.ONE * target_scale * lerpf(0.84, 0.92, pow(reveal, 1.6))
	_set_shader(crown_sprite, reveal, dissolve, 1.0, _intensity() * 1.08, _safe_center_uv(crown_sprite))
	crown_sprite.modulate.a = reveal * (1.0 - dissolve) * 0.62


func _create_sprite(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_as_relative = false
	sprite.z_index = player.z_index - 1
	var material := ShaderMaterial.new()
	material.shader = REVEAL_SHADER
	material.set_shader_parameter("turbulence", NOISE)
	material.set_shader_parameter("crystal_material", CRYSTAL)
	sprite.material = material
	return sprite


func _set_shader(sprite: Sprite2D, wave: float, dissolve: float, freeze: float, strength: float, safe_uv: Vector2) -> void:
	var material := sprite.material as ShaderMaterial
	material.set_shader_parameter("age", elapsed)
	material.set_shader_parameter("wave_progress", wave)
	material.set_shader_parameter("dissolve_progress", dissolve)
	material.set_shader_parameter("freeze_amount", freeze)
	material.set_shader_parameter("intensity", strength)
	material.set_shader_parameter("safe_center_uv", safe_uv)
	material.set_shader_parameter("safe_radius_uv", Vector2(24, 30) / (1024.0 * sprite.global_scale.abs()).max(Vector2.ONE))


func _safe_center_uv(sprite: Sprite2D) -> Vector2:
	return sprite.to_local(player.global_position) / 1024.0 + Vector2(0.5, 0.5)


func _wave_texture() -> Texture2D:
	if branch_id == "frost_tide_field":
		return FIELD_WAVE
	if branch_id == "frost_tide_shatter":
		return SHATTER_WAVE
	return WAVE


func _intensity() -> float:
	return [0.0, 0.84, 0.94, 1.04, 1.14, 1.24][level]


func _trail_strength() -> float:
	var base := 0.34 if branch_id == "frost_tide_field" else 0.18 if branch_id == "frost_tide_shatter" else 0.23
	return base * (1.18 if level >= 4 else 1.0)


func _shard_count() -> int:
	if level == 1:
		return 8
	if branch_id == "frost_tide_field":
		return 14 if level == 5 else 12 if level >= 4 else 10
	if branch_id == "frost_tide_shatter":
		return 24 if level == 5 else 20 if level >= 4 else 16
	return 8


func _draw() -> void:
	if elapsed < 0.029:
		var gather_alpha := sin(clampf(elapsed / 0.029, 0.0, 1.0) * PI)
		for index in range(4):
			var direction := Vector2.from_angle(index * TAU / 4.0 + PI * 0.25)
			draw_line(direction * 18.0, direction * 11.0, Color(0.84, 0.99, 1.0, gather_alpha), 2.4, true)
	var count := _shard_count()
	var wave_progress := clampf(elapsed / TRAVEL_TIME, 0.0, 1.0)
	var fade_duration := 0.19 if level == 5 and branch_id == "frost_tide_shatter" else maxf(duration - TRAVEL_TIME, 0.01)
	var tail := clampf((elapsed - TRAVEL_TIME) / fade_duration, 0.0, 1.0)
	var shard_size := 29.0 if branch_id == "frost_tide_field" else 19.0 if branch_id == "frost_tide_shatter" else 23.0
	for index in range(count):
		var angle := index * TAU / float(count) + float(index % 3) * 0.075
		var direction := Vector2.from_angle(angle)
		var drift := 1.0 - pow(1.0 - tail, 2.0)
		var lag := sin(wave_progress * PI) * (5.0 + index % 4 * 3.0)
		var center := direction * (radius * wave_progress - lag + drift * (5.0 + index % 4 * 2.0))
		center += direction.orthogonal() * drift * (float(index % 3) - 1.0) * 14.0
		var alpha := smoothstep(0.035 + index % 3 * 0.022, 0.18 + index % 3 * 0.022, wave_progress) * pow(1.0 - tail, 1.4)
		if alpha <= 0.0:
			continue
		var size := shard_size * (0.78 + float(index % 4) * 0.08)
		draw_set_transform(center, angle + PI * 0.5 + drift * (float(index % 3) - 1.0) * 0.8, Vector2(1.0 - tail * 0.3, 1.0))
		draw_texture_rect_region(SHARDS, Rect2(-size * 0.5, -size * 0.5, size, size), Rect2((index % 4) * 128, 0, 128, 128), Color(1.0, 1.0, 1.0, alpha * 0.78))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
