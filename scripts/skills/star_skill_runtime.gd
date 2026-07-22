extends Node

signal skill_released(skill_id: String)

const HeroCatalog = preload("res://scripts/hero_catalog.gd")

var player: Node2D
var enemies: Node2D
var projectiles: Node2D
var effects: Node2D
var audio: Node
var rng: RandomNumberGenerator
var levels: Dictionary
var skill_modifiers: Dictionary
var bolt_timer := 0.25
var orbit_hit_timer := 0.0
var orbit_phase := 0.0
var pulse_timer := 1.0
var pulse_visual_time := 0.0


func configure(player_node: Node2D, enemy_system: Node2D, projectile_system: Node2D, combat_effects: Node2D, audio_manager: Node, random: RandomNumberGenerator, skill_levels: Dictionary, permanent_modifiers: Dictionary = {}) -> void:
	player = player_node
	enemies = enemy_system
	projectiles = projectile_system
	effects = combat_effects
	audio = audio_manager
	rng = random
	levels = skill_levels
	skill_modifiers = permanent_modifiers


func advance(skill_delta: float, real_delta: float, elapsed: float) -> void:
	pulse_visual_time = maxf(0.0, pulse_visual_time - real_delta)
	_update_star_lance(skill_delta)
	_update_sun_orbit(skill_delta)
	_update_frost_tide(skill_delta, elapsed)


func after_upgrade(skill_id: String) -> void:
	if skill_id == "frost_tide":
		pulse_timer = minf(pulse_timer, 0.3)


func cooldown_progress(skill_id: String) -> float:
	var skill_level: int = levels.get(skill_id, 0)
	if skill_level <= 0:
		return 0.0
	if skill_id == "sun_orbit":
		return 1.0
	var data: Dictionary = HeroCatalog.skill(skill_id)["runtime"]
	var timer: float = bolt_timer if skill_id == "star_lance" else pulse_timer
	var duration: float = data["cooldown"][skill_level] * _multiplier(skill_id, "cooldown_multiplier")
	return clampf(1.0 - maxf(timer, 0.0) / duration, 0.0, 1.0)


func _update_star_lance(delta: float) -> void:
	var skill_level: int = levels.get("star_lance", 0)
	if skill_level <= 0:
		return
	bolt_timer -= delta
	if bolt_timer > 0.0:
		return
	var data: Dictionary = HeroCatalog.skill("star_lance")["runtime"]
	bolt_timer = data["cooldown"][skill_level] * _multiplier("star_lance", "cooldown_multiplier")
	var target: Node = enemies.nearest_enemy(player.position)
	if target == null:
		return
	var base_angle: float = player.position.direction_to(target.position).angle()
	for index in range(data["count"][skill_level]):
		var spread: float = (index - (data["count"][skill_level] - 1) * 0.5) * data["spread"][skill_level]
		projectiles.spawn_projectile({
			"position": player.position, "angle": base_angle + spread,
			"speed": data["speed"][skill_level] * _multiplier("star_lance", "projectile_speed_multiplier"),
			"damage": data["damage"][skill_level] * _multiplier("star_lance", "damage_multiplier"), "radius": data["radius"][skill_level],
			"pierce": data["pierce"][skill_level], "visual_kind": "star_lance",
		})
	skill_released.emit("star_lance")
	audio.play_sfx("skill_star_lance", -1.0, rng.randf_range(0.96, 1.04))


func _update_sun_orbit(delta: float) -> void:
	var skill_level: int = levels.get("sun_orbit", 0)
	if skill_level <= 0:
		return
	var data: Dictionary = HeroCatalog.skill("sun_orbit")["runtime"]
	orbit_phase += delta * data["spin_speed"][skill_level]
	orbit_hit_timer -= delta
	if orbit_hit_timer > 0.0:
		return
	orbit_hit_timer = data["hit_interval"][skill_level] * _multiplier("sun_orbit", "hit_interval_multiplier")
	var range_multiplier := _multiplier("sun_orbit", "range_multiplier")
	var hit_anything := false
	for index in range(data["count"][skill_level]):
		var angle: float = orbit_phase + index * TAU / data["count"][skill_level]
		var orb_position: Vector2 = player.position + Vector2.from_angle(angle) * data["orbit_radius"][skill_level] * range_multiplier
		for enemy in enemies.snapshot():
			if is_instance_valid(enemy) and enemy.position.distance_to(orb_position) <= enemy.radius + data["orb_radius"][skill_level] * range_multiplier:
				hit_anything = true
				effects.add_effect(enemy.position, 34.0, Color("ffbf45"), 0.24, "sun_hit")
				enemies.damage_enemy(enemy, data["damage"][skill_level] * _multiplier("sun_orbit", "damage_multiplier"), Color("ffd765"))
	if hit_anything:
		audio.play_sfx("skill_sun_orbit", -5.0, rng.randf_range(0.96, 1.04))


func _update_frost_tide(delta: float, elapsed: float) -> void:
	var skill_level: int = levels.get("frost_tide", 0)
	if skill_level <= 0:
		return
	pulse_timer -= delta
	if pulse_timer > 0.0:
		return
	var data: Dictionary = HeroCatalog.skill("frost_tide")["runtime"]
	pulse_timer = data["cooldown"][skill_level] * _multiplier("frost_tide", "cooldown_multiplier")
	pulse_visual_time = 0.3
	skill_released.emit("frost_tide")
	audio.play_sfx("skill_frost_tide", 0.0, rng.randf_range(0.97, 1.03))
	for enemy in enemies.snapshot():
		if is_instance_valid(enemy) and enemy.position.distance_to(player.position) <= data["radius"][skill_level] * _multiplier("frost_tide", "range_multiplier") + enemy.radius:
			enemy.apply_slow(data["slow_factor"][skill_level], data["slow_duration"][skill_level], elapsed)
			enemies.damage_enemy(enemy, data["damage"][skill_level] * _multiplier("frost_tide", "damage_multiplier"), Color("9ff4ff"))


func _multiplier(skill_id: String, field: String) -> float:
	var modifiers: Dictionary = skill_modifiers.get(skill_id, {})
	return float(modifiers.get(field, 1.0))
