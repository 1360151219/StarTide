extends Node2D

const CORE = preload("res://assets/art/skills/meteor_rain_body.png")
const FRAGMENTS = preload("res://assets/art/skills/ember_fragments.png")
const NOISE = preload("res://scripts/skills/meteor_turbulence.tres")
const FLAME = preload("res://scripts/skills/meteor_flame.gdshader")
const GROUND = preload("res://scripts/skills/meteor_ground.gdshader")
const IMPACT_DURATION := 0.72
const FALL_OFFSET := Vector2(-0.58, -2.1)
const CORE_TIP := 0.409

var radius := 1.0
var elapsed := 0.0
var duration := 1.0
var seed_offset := 0.0
var warning := false
var focused := false
var level := 1
var player: Node2D
var ground: Sprite2D
var comet: Node2D
var core: Sprite2D
var tail: Sprite2D
var light: PointLight2D
var puffs: Array[Sprite2D] = []
var debris: Array[Sprite2D] = []
var embers: Array[Sprite2D] = []
var body_size := Vector2.ONE


func configure(effect: Dictionary) -> void:
	position = effect["position"]
	radius = float(effect["radius"])
	duration = float(effect["duration"])
	warning = effect["kind"] == "meteor_warning"
	var data: Dictionary = effect["data"]
	focused = data.get("branch_id", "") == "meteor_rain_focus"
	level = clampi(int(data.get("level", 1)), 1, 5)
	player = data.get("player")
	seed_offset = fposmod(position.x * 0.017 + position.y * 0.031, 10.0)
	z_as_relative = false
	z_index = 3880
	ground = _sprite(NOISE, GROUND, self, Vector2.ONE * radius * 2.24)
	ground.z_as_relative = false
	ground.z_index = 0
	ground.material.set_shader_parameter("warning", warning)
	if warning:
		_build_comet()
	else:
		for index in range(3 if focused or level >= 3 else 2):
			var puff := _sprite(NOISE, FLAME, self, Vector2.ONE * radius)
			puff.material.set_shader_parameter("form", 1)
			puff.material.set_shader_parameter("variation", seed_offset + index * 0.37)
			puffs.append(puff)
		for index in range(7 if focused else 5):
			debris.append(_rock(self, Vector2.ONE * (13.0 + index % 3 * 4.0)))
		_build_light()
	for index in range(6 if warning else 8):
		var atlas := AtlasTexture.new()
		atlas.atlas = FRAGMENTS
		atlas.region = Rect2(384, 0, 128, 128)
		embers.append(_sprite(atlas, FLAME, comet if warning else self, Vector2(12, 7)))
		embers[-1].material.set_shader_parameter("form", 2)
	refresh(effect)


func refresh(effect: Dictionary) -> void:
	elapsed = clampf(duration - float(effect["time"]), 0.0, duration)
	ground.material.set_shader_parameter("age", elapsed)
	ground.material.set_shader_parameter("variation", seed_offset)
	if warning:
		_refresh_comet()
	else:
		_refresh_impact()
	var hero := player.global_position if is_instance_valid(player) else Vector2(-100000, -100000)
	for sprite in puffs + debris + embers + ([core, tail] if warning else []):
		sprite.material.set_shader_parameter("age", elapsed)
		sprite.material.set_shader_parameter("hero_position", hero)
	queue_redraw()


static func fall_progress(progress: float) -> float:
	return pow(clampf(progress, 0.0, 1.0), 2.4)


static func impact_front(age: float) -> float:
	return lerpf(0.78, 1.0, 1.0 - pow(1.0 - clampf(age / 0.056, 0.0, 1.0), 3.0))


func _build_comet() -> void:
	comet = Node2D.new()
	add_child(comet)
	comet.rotation = (-FALL_OFFSET).angle() - PI * 0.5
	var width := radius * (0.61 if focused else 0.47) * (0.92 + level * 0.025)
	body_size = Vector2(width * 1.65, width * 1.9)
	var tail_size := Vector2(width * 2.25, width * (3.6 if focused else 3.9))
	tail = _sprite(NOISE, FLAME, comet, tail_size)
	tail.position.y = body_size.y * CORE_TIP - tail_size.y * 0.45
	core = _rock(comet, body_size)


func _refresh_comet() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var travel := fall_progress(progress)
	comet.position = FALL_OFFSET * radius * (1.0 - travel) - Vector2(0, body_size.y * CORE_TIP).rotated(comet.rotation)
	var appear := smoothstep(0.0, 0.045, elapsed)
	core.material.set_shader_parameter("opacity", appear)
	tail.material.set_shader_parameter("opacity", appear * 0.96)
	tail.material.set_shader_parameter("variation", seed_offset)
	ground.material.set_shader_parameter("opacity", 0.5 + progress * 0.5)
	for index in range(embers.size()):
		var phase := fposmod(elapsed * 2.0 + index * 0.173, 1.0)
		var side := -1.0 if index % 2 else 1.0
		embers[index].position = Vector2(side * body_size.x * (0.16 + phase * 0.33), -body_size.y * (0.1 + phase * 1.1))
		embers[index].rotation = -0.55 + side * 0.5
		embers[index].material.set_shader_parameter("opacity", sin(phase * PI) * appear * 0.7)


func _refresh_impact() -> void:
	var fade := 1.0 - smoothstep(0.3, duration, elapsed)
	ground.material.set_shader_parameter("front", impact_front(elapsed))
	ground.material.set_shader_parameter("opacity", fade)
	for index in range(puffs.size()):
		var rise := 1.0 - exp(-elapsed / 0.13)
		var size := radius * (0.55 + rise * 0.45) * (1.15 if focused else 0.92)
		var puff := puffs[index]
		puff.position = Vector2((index - 1) * radius * 0.23, -radius * (0.12 + rise * 0.27) + absf(index - 1) * radius * 0.1)
		puff.scale = Vector2(size, size * (1.12 if focused else 0.87)) / NOISE.get_size()
		puff.rotation = sin(index * 2.4 + seed_offset) * 0.32
		puff.material.set_shader_parameter("opacity", (1.0 - smoothstep(0.08, 0.59, elapsed)) * (0.9 if index == 1 else 0.75))
	for index in range(debris.size()):
		var angle := index * 2.39996 + seed_offset
		var travel := 1.0 - exp(-elapsed / 0.23)
		var lift := sin(clampf(elapsed / 0.56, 0.0, 1.0) * PI) * radius * (0.28 + index % 3 * 0.08)
		debris[index].position = Vector2.from_angle(angle) * radius * (0.16 + travel * 0.69) + Vector2(0, -lift)
		debris[index].rotation = angle + elapsed * (3.0 if index % 2 else -4.0)
		debris[index].material.set_shader_parameter("opacity", fade)
	for index in range(embers.size()):
		var angle := index * 2.39996 + seed_offset + 0.7
		var travel := 1.0 - exp(-elapsed / 0.19)
		embers[index].position = Vector2.from_angle(angle) * radius * travel * 0.88 + Vector2(0, -elapsed * 24.0)
		embers[index].rotation = angle - 0.45
		embers[index].material.set_shader_parameter("opacity", (1.0 - smoothstep(0.12, 0.6, elapsed)) * 0.9)
	light.energy = (0.48 if focused else 0.32) * (1.0 - smoothstep(0.025, 0.16, elapsed))
	light.visible = light.energy > 0.001


func _sprite(texture: Texture2D, shader: Shader, parent: Node2D, size: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if texture == CORE else CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if texture == NOISE else CanvasItem.TEXTURE_REPEAT_DISABLED
	sprite.scale = size / texture.get_size()
	var material := ShaderMaterial.new()
	material.shader = shader
	if shader == FLAME:
		material.set_shader_parameter("turbulence", NOISE)
	sprite.material = material
	parent.add_child(sprite)
	return sprite


func _rock(parent: Node2D, size: Vector2) -> Sprite2D:
	var sprite := _sprite(CORE, FLAME, parent, size)
	sprite.material.set_shader_parameter("form", 2)
	return sprite


func _build_light() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 1.0)
	light = PointLight2D.new()
	light.texture = texture
	light.texture_scale = radius * 2.4 / 128.0
	light.color = Color(1.0, 0.55, 0.2)
	light.range_z_max = 3800
	add_child(light)


func _draw() -> void:
	if not warning:
		return
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var alpha := 0.5 + progress * 0.35
	var gap := PI * 0.19
	draw_arc(Vector2.ZERO, radius, -PI * 0.5 + gap, PI * 1.5 - gap, 64, Color(0.28, 0.22, 0.12, alpha * 0.65), 3.0, true)
	draw_arc(Vector2.ZERO, radius, -PI * 0.5 + gap, PI * 1.5 - gap, 64, Color(1.0, 0.78, 0.37, alpha), 1.35, true)
