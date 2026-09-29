extends Node

signal skill_released(skill_id: String)

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const CombatTimeline = preload("res://scripts/combat/combat_timeline.gd")
const FROST_TRAVEL_TIME := 0.36
const SLASH_HIT_DELAY := 0.08
const SLASH_VISUAL_DURATION := 0.26
const ULTIMATE_SLASH_VISUAL_DURATION := 0.32

var player: Node2D
var enemies: Node2D
var projectiles: Node2D
var effects: Node2D
var audio: Node
var rng: RandomNumberGenerator
var levels: Dictionary
var skill_modifiers: Dictionary
var build_state: RefCounted
var bolt_timer := 0.25
var slash_timer := 0.6
var slash_visuals: Array[Dictionary] = []
var next_visual_id := 0
var pulse_timer := 1.0
var pulse_visual: Dictionary = {}
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

func advance(skill_delta: float, real_delta: float, elapsed: float) -> void:
	timeline.advance(real_delta)
	_update_slash_visuals(real_delta)
	_update_pulse_visual(real_delta)
	_update_star_lance(skill_delta)
	_update_frost_slash(skill_delta, elapsed)
	_update_frost_tide(skill_delta, elapsed)

func after_upgrade(skill_id: String) -> void:
	match skill_id:
		"star_lance": bolt_timer = minf(bolt_timer, 0.3)
		"sun_orbit": slash_timer = minf(slash_timer, 0.3)
		"frost_tide": pulse_timer = minf(pulse_timer, 0.3)

func cooldown_progress(skill_id: String) -> float:
	var skill_level: int = levels.get(skill_id, 0)
	if skill_level <= 0:
		return 0.0
	var data: Dictionary = SkillCatalog.skill(skill_id)["runtime"]
	var timer: float = bolt_timer if skill_id == "star_lance" else slash_timer if skill_id == "sun_orbit" else pulse_timer
	var duration: float = data["cooldown"][skill_level] * _multiplier(skill_id, "cooldown_multiplier")
	return clampf(1.0 - maxf(timer, 0.0) / duration, 0.0, 1.0)

func _update_star_lance(delta: float) -> void:
	var skill_level: int = levels.get("star_lance", 0)
	if skill_level <= 0:
		return
	bolt_timer = maxf(0.0, bolt_timer - delta)
	if bolt_timer > 0.0:
		return
	var data: Dictionary = SkillCatalog.skill("star_lance")["runtime"]
	var target: Node = enemies.nearest_enemy(player.position)
	if target == null:
		return
	bolt_timer = data["cooldown"][skill_level] * _multiplier("star_lance", "cooldown_multiplier")
	var base_angle: float = player.position.direction_to(target.position).angle()
	var count := int(_stat("star_lance", "count", data["count"][skill_level]))
	var spread_step := float(_stat("star_lance", "spread", data["spread"][skill_level]))
	for index in range(count):
		var spread: float = (index - (count - 1) * 0.5) * spread_step
		projectiles.spawn_projectile({
			"position": player.position, "angle": base_angle + spread, "player": player,
			"speed": data["speed"][skill_level] * _multiplier("star_lance", "projectile_speed_multiplier"),
			"damage": data["damage"][skill_level] * _multiplier("star_lance", "damage_multiplier"), "radius": data["radius"][skill_level],
			"pierce": int(_stat("star_lance", "pierce", data["pierce"][skill_level])), "visual_kind": "star_lance",
			"source_id": "skill:star_lance", "skill_level": skill_level,
			"branch_id": str(build_state.skill_branches.get("star_lance", "")), "volley_index": index, "volley_count": count,
		})
	skill_released.emit("star_lance")
	audio.play_sfx("skill_star_lance", -1.0, rng.randf_range(0.96, 1.04))

func _update_frost_slash(delta: float, elapsed: float) -> void:
	var skill_level: int = levels.get("sun_orbit", 0)
	if skill_level <= 0:
		return
	slash_timer -= delta
	if slash_timer > 0.0:
		return
	var data: Dictionary = SkillCatalog.skill("sun_orbit")["runtime"]
	slash_timer = data["cooldown"][skill_level] * _multiplier("sun_orbit", "cooldown_multiplier")
	var range_multiplier := _multiplier("sun_orbit", "range_multiplier")
	var inner_radius: float = data["inner_radius"][skill_level] * range_multiplier
	var radius: float = data["radius"][skill_level] * range_multiplier
	var arc_degrees: float = data["arc_degrees"][skill_level]
	var damage: float = data["damage"][skill_level] * _multiplier("sun_orbit", "damage_multiplier")
	var angles := _random_slash_angles(data["count"][skill_level], radius)
	var origin := player.position
	var visual_kind := "ultimate_upper" if skill_level == 5 else "regular"
	for angle in angles:
		_add_slash_visual(origin, angle, inner_radius, radius, arc_degrees, skill_level, visual_kind)
	timeline.schedule(SLASH_HIT_DELAY, _resolve_slash_hit.bind(origin, angles, inner_radius, radius, arc_degrees, damage, data["slow_factor"][skill_level], data["slow_duration"][skill_level], elapsed + SLASH_HIT_DELAY), "sun_orbit")
	if data["return_delay"][skill_level] > 0.0:
		var return_delay: float = data["return_delay"][skill_level]
		timeline.schedule(return_delay, _release_return_slash.bind(angles[0], inner_radius, radius, arc_degrees, damage * data["return_damage_multiplier"][skill_level], data["slow_factor"][skill_level], data["slow_duration"][skill_level], elapsed + return_delay), "sun_orbit")
	skill_released.emit("sun_orbit")
	audio.play_sfx("skill_sun_orbit", -2.0, rng.randf_range(0.96, 1.04))

func _release_return_slash(angle: float, inner_radius: float, radius: float, arc_degrees: float, damage: float, slow_factor: float, slow_duration: float, elapsed: float) -> void:
	var origin := player.position
	var angles: Array[float] = [angle]
	_add_slash_visual(origin, angle, inner_radius, radius, arc_degrees, 5, "ultimate_lower")
	audio.play_sfx("skill_frost_slash_return", -2.5, rng.randf_range(0.97, 1.03))
	timeline.schedule(SLASH_HIT_DELAY, _resolve_slash_hit.bind(origin, angles, inner_radius, radius, arc_degrees, damage, slow_factor, slow_duration, elapsed + SLASH_HIT_DELAY), "sun_orbit")

func _random_slash_angles(count: int, radius: float) -> Array[float]:
	var candidates: Array[float] = []
	for enemy in enemies.snapshot():
		if is_instance_valid(enemy) and enemies.is_active(enemy) and player.position.distance_to(enemy.position) <= radius + enemy.radius:
			candidates.append(player.position.direction_to(enemy.position).angle())
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = held
	var result: Array[float] = []
	for angle in candidates:
		if result.size() >= count:
			break
		var separated := true
		for chosen_angle in result:
			separated = separated and absf(wrapf(angle - chosen_angle, -PI, PI)) >= 0.52
		if separated:
			result.append(angle)
	while result.size() < count:
		result.append(rng.randf_range(-PI, PI))
	return result

func _add_slash_visual(origin: Vector2, angle: float, inner_radius: float, radius: float, arc_degrees: float, level: int, kind: String) -> void:
	var duration := ULTIMATE_SLASH_VISUAL_DURATION if kind.begins_with("ultimate") else SLASH_VISUAL_DURATION
	slash_visuals.append({
		"origin": origin, "angle": angle, "inner_radius": inner_radius, "radius": radius,
		"arc_degrees": arc_degrees, "level": level, "kind": kind, "visual_id": next_visual_id,
		"time_left": duration, "duration": duration,
	})
	next_visual_id += 1

func _update_slash_visuals(delta: float) -> void:
	for index in range(slash_visuals.size() - 1, -1, -1):
		slash_visuals[index]["time_left"] = float(slash_visuals[index]["time_left"]) - delta
		if slash_visuals[index]["time_left"] <= 0.0:
			slash_visuals.remove_at(index)

func _update_pulse_visual(delta: float) -> void:
	if pulse_visual.is_empty():
		return
	pulse_visual["time_left"] = float(pulse_visual["time_left"]) - delta
	if pulse_visual["time_left"] <= 0.0:
		pulse_visual.clear()


func _resolve_slash_hit(origin: Vector2, angles: Array[float], inner_radius: float, radius: float, arc_degrees: float, damage: float, slow_factor: float, slow_duration: float, impact_elapsed: float) -> void:
	for enemy in enemies.snapshot():
		if not is_instance_valid(enemy) or not enemies.is_active(enemy):
			continue
		for angle in angles:
			if not _inside_slash(enemy, origin, angle, inner_radius, radius, arc_degrees):
				continue
			enemy.apply_slow(slow_factor, slow_duration, impact_elapsed)
			effects.add_effect(enemy.position, enemy.radius + 18.0, Color("9ff4ff"), 0.28, "frost_hit")
			enemies.damage_enemy(enemy, damage, Color("9ff4ff"), origin, "skill:sun_orbit")
			audio.play_sfx("frost_hit", -5.0, rng.randf_range(0.96, 1.05))
			break


func _inside_slash(enemy: Node, origin: Vector2, angle: float, inner_radius: float, radius: float, arc_degrees: float) -> bool:
	var offset: Vector2 = enemy.position - origin
	var distance := offset.length()
	if distance < inner_radius - enemy.radius or distance > radius + enemy.radius:
		return false
	var edge_tolerance := asin(minf(1.0, enemy.radius / maxf(distance, 1.0)))
	return absf(wrapf(offset.angle() - angle, -PI, PI)) <= deg_to_rad(arc_degrees * 0.5) + edge_tolerance


func _update_frost_tide(delta: float, elapsed: float) -> void:
	var skill_level: int = levels.get("frost_tide", 0)
	if skill_level <= 0:
		return
	pulse_timer -= delta
	if pulse_timer > 0.0:
		return
	var data: Dictionary = SkillCatalog.skill("frost_tide")["runtime"]
	pulse_timer = data["cooldown"][skill_level] * _multiplier("frost_tide", "cooldown_multiplier")
	var center := player.position
	var branch_id := str(build_state.skill_branches.get("frost_tide", ""))
	var radius: float = data["radius"][skill_level] * _multiplier("frost_tide", "range_multiplier") * _branch_multiplier("frost_tide", "radius_multiplier")
	var visual_duration := 0.62 if skill_level == 5 else 0.54 if branch_id == "frost_tide_field" else 0.46 if branch_id == "frost_tide_shatter" else 0.48
	pulse_visual = {"origin": center, "radius": radius, "level": skill_level, "branch_id": branch_id, "visual_id": next_visual_id, "time_left": visual_duration, "duration": visual_duration}
	next_visual_id += 1
	skill_released.emit("frost_tide")
	var pitch := 0.97 if branch_id == "frost_tide_field" else 1.04 if branch_id == "frost_tide_shatter" else 1.0
	audio.play_sfx("skill_frost_tide_ultimate" if skill_level == 5 else "skill_frost_tide", 0.0, pitch)
	for enemy in enemies.snapshot():
		if is_instance_valid(enemy) and enemy.position.distance_to(center) <= radius + enemy.radius:
			var slow_duration: float = data["slow_duration"][skill_level] * _branch_multiplier("frost_tide", "slow_duration_multiplier")
			var travel_delay := clampf(enemy.position.distance_to(center) / maxf(radius, 1.0), 0.08, 1.0) * FROST_TRAVEL_TIME
			timeline.schedule(
				travel_delay,
				_resolve_frost_hit.bind(
					enemy, center, radius,
					data["damage"][skill_level] * _multiplier("frost_tide", "damage_multiplier"),
					data["slow_factor"][skill_level], slow_duration, elapsed + travel_delay
				),
				"frost_tide"
			)


func _resolve_frost_hit(enemy: Node, center: Vector2, radius: float, damage: float, slow_factor: float, slow_duration: float, impact_elapsed: float) -> void:
	if not is_instance_valid(enemy) or not enemies.is_active(enemy):
		return
	if enemy.position.distance_to(center) > radius + enemy.radius:
		return
	enemy.apply_slow(slow_factor, slow_duration, impact_elapsed)
	effects.add_effect(enemy.position, enemy.radius + 18.0, Color("9ff4ff"), 0.24, "frost_tide_hit", {"direction": center.direction_to(enemy.position)})
	enemies.damage_enemy(enemy, damage, Color("9ff4ff"), center, "skill:frost_tide")
	audio.play_sfx("frost_tide_hit", -4.0, rng.randf_range(0.97, 1.04))


func _multiplier(skill_id: String, field: String) -> float:
	var result := float(skill_modifiers.get(skill_id, {}).get(field, 1.0))
	if ["damage_multiplier", "cooldown_multiplier", "hit_interval_multiplier", "range_multiplier"].has(field):
		result *= build_state.modifier(field)
	return result * _branch_multiplier(skill_id, field)


func _branch_multiplier(skill_id: String, field: String) -> float:
	return float(build_state.branch_overrides(skill_id).get(field, 1.0))


func _stat(skill_id: String, field: String, base_value):
	return build_state.branch_overrides(skill_id).get(field, base_value)
