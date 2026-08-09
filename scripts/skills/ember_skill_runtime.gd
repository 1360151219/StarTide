extends Node

signal skill_released(skill_id: String)

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const CombatTimeline = preload("res://scripts/combat/combat_timeline.gd")
const METEOR_FALL_TIME := 0.34
const PHOENIX_IMPACT_TIME := 0.18

var player: Node2D
var enemies: Node2D
var projectiles: Node2D
var effects: Node2D
var audio: Node
var rng: RandomNumberGenerator
var levels: Dictionary
var skill_modifiers: Dictionary
var build_state: RefCounted
var volley_timer := 0.25
var meteor_timer := 1.0
var phoenix_timer := 1.0
var timeline := CombatTimeline.new()


func configure(player_node: Node2D, enemy_system: Node2D, projectile_system: Node2D, combat_effects: Node2D, audio_manager: Node, random: RandomNumberGenerator, skill_levels: Dictionary, permanent_modifiers: Dictionary, build: RefCounted) -> void:
	player = player_node
	enemies = enemy_system
	projectiles = projectile_system
	effects = combat_effects
	audio = audio_manager
	rng = random
	levels = skill_levels
	skill_modifiers = permanent_modifiers
	build_state = build


func advance(skill_delta: float, real_delta: float, _elapsed: float) -> void:
	timeline.advance(real_delta)
	_update_ember_volley(skill_delta)
	_update_meteor_rain(skill_delta)
	_update_phoenix_heart(skill_delta)


func after_upgrade(skill_id: String) -> void:
	if skill_id == "meteor_rain":
		meteor_timer = minf(meteor_timer, 0.3)
	elif skill_id == "phoenix_heart":
		phoenix_timer = minf(phoenix_timer, 0.3)


func cooldown_progress(skill_id: String) -> float:
	var skill_level: int = levels.get(skill_id, 0)
	if skill_level <= 0:
		return 0.0
	var data: Dictionary = SkillCatalog.skill(skill_id)["runtime"]
	var timer := volley_timer
	if skill_id == "meteor_rain":
		timer = meteor_timer
	elif skill_id == "phoenix_heart":
		timer = phoenix_timer
	var duration: float = data["cooldown"][skill_level] * _multiplier(skill_id, "cooldown_multiplier")
	return clampf(1.0 - maxf(timer, 0.0) / duration, 0.0, 1.0)


func _update_ember_volley(delta: float) -> void:
	var skill_level: int = levels.get("ember_volley", 0)
	if skill_level <= 0:
		return
	volley_timer -= delta
	if volley_timer > 0.0:
		return
	var data: Dictionary = SkillCatalog.skill("ember_volley")["runtime"]
	volley_timer = data["cooldown"][skill_level] * _multiplier("ember_volley", "cooldown_multiplier")
	var target: Node = enemies.nearest_enemy(player.position)
	if target == null:
		return
	var base_angle: float = player.position.direction_to(target.position).angle()
	var count := int(_stat("ember_volley", "count", data["count"][skill_level]))
	var spread_step := float(_stat("ember_volley", "spread", data["spread"][skill_level]))
	for index in range(count):
		var spread: float = (index - (count - 1) * 0.5) * spread_step
		projectiles.spawn_projectile({
			"position": player.position, "angle": base_angle + spread,
			"speed": data["speed"][skill_level] * _multiplier("ember_volley", "projectile_speed_multiplier"),
			"damage": data["damage"][skill_level] * _multiplier("ember_volley", "damage_multiplier"), "radius": data["radius"][skill_level],
			"pierce": int(_stat("ember_volley", "pierce", data["pierce"][skill_level])),
			"blast_radius": data["blast_radius"][skill_level] * _multiplier("ember_volley", "range_multiplier") * _branch_multiplier("ember_volley", "blast_radius_multiplier"),
			"visual_kind": "ember_arrow",
		})
	skill_released.emit("ember_volley")
	audio.play_sfx("skill_ember_volley", -1.0, rng.randf_range(0.95, 1.05))


func _update_meteor_rain(delta: float) -> void:
	var skill_level: int = levels.get("meteor_rain", 0)
	if skill_level <= 0:
		return
	meteor_timer -= delta
	if meteor_timer > 0.0:
		return
	var data: Dictionary = SkillCatalog.skill("meteor_rain")["runtime"]
	meteor_timer = data["cooldown"][skill_level] * _multiplier("meteor_rain", "cooldown_multiplier")
	skill_released.emit("meteor_rain")
	audio.play_sfx("skill_meteor_rain", 1.0, rng.randf_range(0.96, 1.03))
	var candidates: Array[Node] = []
	for enemy in enemies.snapshot():
		if is_instance_valid(enemy):
			candidates.append(enemy)
	var targeting := str(_stat("meteor_rain", "targeting", "random"))
	if targeting == "elite_first":
		candidates.sort_custom(_higher_threat_first)
	else:
		_shuffle(candidates)
	var count := int(_stat("meteor_rain", "count", data["count"][skill_level]))
	for index in range(mini(count, candidates.size())):
		var target_position: Vector2 = candidates[index].position
		var radius: float = data["radius"][skill_level] * _multiplier("meteor_rain", "range_multiplier") * _branch_multiplier("meteor_rain", "radius_multiplier")
		var fall_time := METEOR_FALL_TIME + index * 0.055
		effects.add_effect(target_position, radius, Color("ffb43f"), fall_time, "meteor_warning")
		timeline.schedule(
			fall_time,
			_resolve_meteor_impact.bind(
				target_position, radius,
				data["damage"][skill_level] * _multiplier("meteor_rain", "damage_multiplier")
			),
			"meteor_rain"
		)


func _update_phoenix_heart(delta: float) -> void:
	var skill_level: int = levels.get("phoenix_heart", 0)
	if skill_level <= 0:
		return
	phoenix_timer -= delta
	if phoenix_timer > 0.0:
		return
	var data: Dictionary = SkillCatalog.skill("phoenix_heart")["runtime"]
	phoenix_timer = data["cooldown"][skill_level] * _multiplier("phoenix_heart", "cooldown_multiplier")
	skill_released.emit("phoenix_heart")
	audio.play_sfx("skill_phoenix_heart", 0.0, rng.randf_range(0.97, 1.03))
	var radius: float = data["radius"][skill_level] * _multiplier("phoenix_heart", "range_multiplier") * _branch_multiplier("phoenix_heart", "radius_multiplier")
	var center := player.position
	effects.add_effect(center, radius, Color("ff9b3d"), 0.48, "phoenix")
	timeline.schedule(
		PHOENIX_IMPACT_TIME,
		_resolve_phoenix_impact.bind(
			center, radius,
			data["damage"][skill_level] * _multiplier("phoenix_heart", "damage_multiplier"),
			data["healing"][skill_level] * _multiplier("phoenix_heart", "healing_multiplier")
		),
		"phoenix_heart"
	)


func _resolve_meteor_impact(center: Vector2, radius: float, damage: float) -> void:
	enemies.damage_area(center, radius, damage)
	effects.add_effect(center, radius, Color("ff7a35"), 0.46, "meteor_impact")
	audio.play_sfx("meteor_impact", -1.0, rng.randf_range(0.96, 1.04))


func _resolve_phoenix_impact(center: Vector2, radius: float, damage: float, healing: float) -> void:
	if not is_instance_valid(player):
		return
	player.heal(healing)
	effects.add_heal_number(player.position - Vector2(18.0, 36.0), healing)
	enemies.damage_area(center, radius, damage)
	effects.add_effect(center, radius, Color("ff9b3d"), 0.42, "phoenix_impact")
	audio.play_sfx("phoenix_impact", -1.0, rng.randf_range(0.97, 1.03))


func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value


func _multiplier(skill_id: String, field: String) -> float:
	var modifiers: Dictionary = skill_modifiers.get(skill_id, {})
	var result := float(modifiers.get(field, 1.0))
	if ["damage_multiplier", "cooldown_multiplier", "hit_interval_multiplier", "range_multiplier"].has(field):
		result *= build_state.modifier(field)
	return result * _branch_multiplier(skill_id, field)


func _branch_multiplier(skill_id: String, field: String) -> float:
	return float(build_state.branch_overrides(skill_id).get(field, 1.0))


func _stat(skill_id: String, field: String, base_value):
	return build_state.branch_overrides(skill_id).get(field, base_value)


func _higher_threat_first(left: Node, right: Node) -> bool:
	if left.is_elite != right.is_elite:
		return left.is_elite
	return left.health > right.health
