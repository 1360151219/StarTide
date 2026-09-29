extends Node2D

const KINDS := ["star_hit", "frost_hit", "frost_tide_hit", "ember_volley_hit", "ember_volley_blast", "phoenix_impact"]
const NOISE = preload("res://scripts/skills/meteor_turbulence.tres")
const SHADER = preload("res://scripts/skills/skill_impact.gdshader")
const ICE = preload("res://assets/art/skills/frost_tide_shards.png")
const FIRE = preload("res://assets/art/skills/ember_fragments.png")

var kind := ""
var duration := 1.0
var elapsed := 0.0
var radius := 1.0
var direction := Vector2.RIGHT
var fiery := false
var returning := false
var level := 1
var player: Node2D
var clouds: Array[Sprite2D] = []


func configure(effect: Dictionary, player_node: Node2D = null) -> void:
	position = effect["position"]
	kind = effect["kind"]
	duration = effect["duration"]
	radius = effect["radius"]
	var data: Dictionary = effect["data"]
	direction = Vector2(data.get("direction", Vector2.RIGHT)).normalized()
	fiery = kind.begins_with("ember") or kind == "phoenix_impact"
	returning = data.get("branch_id", "") == "phoenix_heart_rebirth"
	level = clampi(int(data.get("level", 1)), 1, 5)
	player = player_node
	z_as_relative = false
	z_index = 3880
	# Phoenix already owns its main flame mass; only loose feathers belong to its hit.
	for index in range(0 if kind == "phoenix_impact" else 2 if kind == "ember_volley_blast" else 1):
		var sprite := Sprite2D.new()
		sprite.texture = NOISE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("turbulence", NOISE)
		material.set_shader_parameter("fiery", fiery)
		sprite.material = material
		add_child(sprite)
		clouds.append(sprite)
	refresh(effect)


func refresh(effect: Dictionary) -> void:
	elapsed = clampf(duration - float(effect["time"]), 0.0, duration)
	var follow: Node2D = effect["data"].get("follow")
	if is_instance_valid(follow): position = follow.position
	var spread := 1.0 - exp(-elapsed / 0.035)
	var hero := player.global_position if is_instance_valid(player) else Vector2(-100000, -100000)
	for index in range(clouds.size()):
		var cloud := clouds[index]
		var size := Vector2.ONE * radius * lerpf(1.1, 1.65, spread)
		cloud.rotation = direction.angle()
		if kind == "star_hit": size *= Vector2(1.25, 0.35)
		if kind == "frost_hit": size *= Vector2(0.7, 1.0)
		if kind == "frost_tide_hit": size *= Vector2(0.9, 0.7)
		if kind == "ember_volley_hit": size *= Vector2(0.9, 0.48)
		if kind == "ember_volley_blast":
			size *= Vector2(0.8, 0.62)
			cloud.rotation = index * 2.39996
			cloud.position = Vector2.from_angle(cloud.rotation) * radius * 0.35 * spread + Vector2(0, -elapsed * 20.0)
		cloud.scale = size / NOISE.get_size()
		cloud.material.set_shader_parameter("age", elapsed)
		cloud.material.set_shader_parameter("progress", elapsed / duration)
		cloud.material.set_shader_parameter("hero_position", hero)
		cloud.material.set_shader_parameter("opacity", 0.55 if kind == "ember_volley_blast" else 0.65)
	queue_redraw()


func _draw() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var alpha := pow(1.0 - progress, 1.4)
	var travel := 1.0 - exp(-elapsed / 0.085)
	var count := 8 if kind == "phoenix_impact" else 7 if kind == "ember_volley_blast" else 4 if kind == "frost_tide_hit" else 3
	for index in range(count):
		var angle := direction.angle() + (index - (count - 1) * 0.5) * 0.63
		if kind in ["phoenix_impact", "ember_volley_blast"]: angle = index * TAU / count + 0.4
		if kind == "frost_hit": angle -= PI * 0.5
		var extent := radius * (0.22 + travel * 0.6)
		if kind == "phoenix_impact": extent = radius * (lerpf(0.86, 0.28, travel) if returning else lerpf(0.54, 0.96, travel))
		var center := Vector2.from_angle(angle) * extent
		center.y -= sin(progress * PI) * (9.0 + index % 3 * 4.0)
		var protection := 1.0
		if is_instance_valid(player): protection = smoothstep(24.0, 40.0, (global_position + center).distance_to(player.global_position + Vector2(0, -16)))
		var size := Vector2(18, 12) * (1.0 - progress * 0.35)
		if kind == "star_hit": size *= Vector2(1.4, 0.65)
		if kind == "phoenix_impact": size *= 1.0 + level * 0.09
		if kind == "ember_volley_blast": size *= 1.2
		draw_set_transform(center, angle + elapsed * (3.5 if index % 2 else -4.0))
		var cell := (0 if kind == "phoenix_impact" else 2 + index % 2) if fiery else index % 4
		draw_texture_rect_region(FIRE if fiery else ICE, Rect2(-size * 0.5, size), Rect2(cell * 128, 0, 128, 128), Color(1, 1, 1, alpha * protection))
	draw_set_transform(Vector2.ZERO)
