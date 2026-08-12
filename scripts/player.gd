extends Node2D

signal healing_resolved(source_id: String, requested: float, applied: float, overheal: float)

const HeroRigScene = preload("res://scenes/presentation/hero_rig_2d.tscn")

var hero_id := "star_warden"
var max_health := 100.0
var health := 100.0
var base_max_health := 100.0
var speed := 230.0
var base_speed := 230.0
var build_speed_bonus := 0.0
var temporary_speed_multiplier := 1.0
var facing := Vector2.DOWN
var hurt_flash := 0.0
var animation_time := 0.0
var movement_amount := 0.0
var horizontal_facing := -1
var passive_active := false
var map: MapConfig
var hero_rig: HeroRig2D


func _ready() -> void:
	_ensure_hero_rig()


func _process(delta: float) -> void:
	animation_time += delta
	hurt_flash = maxf(0.0, hurt_flash - delta)
	if is_instance_valid(hero_rig):
		hero_rig.set_motion(facing, movement_amount)
		hero_rig.set_hurt_active(hurt_flash > 0.0)
	queue_redraw()


func configure(selected_hero_id: String, hero_data: Dictionary, map_config: MapConfig, progression: Dictionary = {}) -> void:
	_ensure_hero_rig()
	hero_id = selected_hero_id
	map = map_config
	base_max_health = hero_data["max_health"] * float(progression.get("health_multiplier", 1.0))
	max_health = base_max_health
	health = max_health
	base_speed = hero_data["speed"] * float(progression.get("move_speed_multiplier", 1.0))
	build_speed_bonus = 0.0
	temporary_speed_multiplier = 1.0
	_refresh_speed()
	hero_rig.configure(hero_id, 108.0)
	hero_rig.play_state("idle", true)
	queue_redraw()


func set_build_speed_bonus(additive_bonus: float) -> void:
	build_speed_bonus = maxf(0.0, additive_bonus)
	_refresh_speed()


func apply_build_modifiers(build_state: RefCounted) -> void:
	max_health = base_max_health + build_state.modifier("max_health_flat")
	health = minf(health, max_health)
	set_build_speed_bonus(build_state.modifier("move_speed_multiplier") - 1.0)


func apply_acquire_effects(effects: Dictionary, source_id := "upgrade") -> void:
	if not effects.has("heal"):
		return
	if effects.has("full_health_max") and is_equal_approx(health, max_health):
		max_health += float(effects["full_health_max"])
	heal(float(effects["heal"]), source_id)


func set_temporary_speed_multiplier(multiplier: float) -> void:
	temporary_speed_multiplier = maxf(0.1, multiplier)
	_refresh_speed()


func _refresh_speed() -> void:
	speed = base_speed * (1.0 + build_speed_bonus) * temporary_speed_multiplier


func move(direction: Vector2, delta: float) -> Vector2:
	var bounds := map.world_bounds
	var previous_position := position
	movement_amount = direction.length()
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
		if absf(facing.x) > 0.28:
			var next_facing := -1 if facing.x < 0.0 else 1
			if next_facing != horizontal_facing:
				horizontal_facing = next_facing
		position += facing * speed * delta
	position.x = clampf(position.x, bounds.position.x + 24.0, bounds.end.x - 24.0)
	position.y = clampf(position.y, bounds.position.y + 24.0, bounds.end.y - 24.0)
	z_index = map.depth_index(position.y)
	return position - previous_position


func take_damage(amount: float) -> bool:
	health = maxf(0.0, health - amount)
	hurt_flash = 0.14
	if is_instance_valid(hero_rig):
		hero_rig.trigger_hit()
	return health <= 0.0


func heal(amount: float, source_id := "unknown") -> float:
	var previous_health := health
	health = minf(max_health, health + amount)
	var applied := health - previous_health
	var requested := maxf(0.0, amount)
	healing_resolved.emit(source_id, requested, maxf(0.0, applied), maxf(0.0, requested - applied))
	return applied


func trigger_cast_animation() -> void:
	if is_instance_valid(hero_rig):
		hero_rig.trigger_cast()


func trigger_victory_animation() -> void:
	if is_instance_valid(hero_rig):
		hero_rig.trigger_victory()


func _draw() -> void:
	# 阴影独立于角色贴图，移动时仍然牢牢贴在地面上。
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2(3, 60), 32.0, Color(0.01, 0.02, 0.07, 0.48))
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2.ZERO, 31.0, Color(0.23, 0.87, 1.0, 0.06))
	draw_arc(Vector2.ZERO, 31.0, 0.0, TAU, 36, Color(0.55, 0.95, 1.0, 0.52), 2.2)
	if passive_active and hero_id == "star_warden":
		draw_circle(Vector2.ZERO, 43.0, Color(0.25, 0.9, 1.0, 0.06))
		draw_arc(Vector2.ZERO, 43.0, animation_time * 0.45, animation_time * 0.45 + PI * 1.55, 48, Color(0.48, 0.94, 1.0, 0.62), 3.2)
		for index in range(6):
			draw_circle(Vector2.from_angle(animation_time * 0.35 + index * TAU / 6.0) * 43.0, 2.8, Color(0.85, 0.98, 1.0, 0.72))
	elif passive_active and hero_id == "ember_ranger":
		for index in range(3):
			var wind_radius := 34.0 + index * 7.0
			draw_arc(Vector2.ZERO, wind_radius, animation_time * 2.5 + index, animation_time * 2.5 + index + PI * 0.9, 22, Color(1.0, 0.46 + index * 0.1, 0.18, 0.54 - index * 0.09), 2.8)


func _ensure_hero_rig() -> void:
	if is_instance_valid(hero_rig):
		return
	hero_rig = HeroRigScene.instantiate()
	hero_rig.position = Vector2(0, 31)
	add_child(hero_rig)
