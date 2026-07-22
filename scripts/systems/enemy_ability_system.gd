extends Node2D
signal player_hit_requested(hit: PlayerHit)

const AbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const AbilityRules = preload("res://scripts/systems/enemy_ability_rules.gd")
const PlayerHitData = preload("res://scripts/combat/player_hit.gd")
const TelegraphRenderer = preload("res://scripts/presentation/enemy_telegraph_renderer.gd")
const VISIBLE_CAST_DELAY := 1.25

var level: LevelConfig
var run_state: RefCounted
var player: Node2D
var enemy_system: Node2D
var projectile_system: Node2D
var stage_director: RefCounted
var rng: RandomNumberGenerator
var audio: Node
var states: Dictionary = {}
var last_warning_start := -INF
var telegraphs: Node2D

func configure(level_config: LevelConfig, state: RefCounted, player_node: Node2D, enemies: Node2D, projectiles: Node2D, director: RefCounted, random: RandomNumberGenerator, audio_manager: Node) -> void:
	level = level_config
	run_state = state
	player = player_node
	enemy_system = enemies
	projectile_system = projectiles
	stage_director = director
	rng = random
	audio = audio_manager
	telegraphs = TelegraphRenderer.new()
	add_child(telegraphs)
	enemy_system.enemy_removed.connect(_on_enemy_removed)

func advance(delta: float, elapsed: float) -> void:
	if run_state.finished or run_state.paused:
		return
	_cleanup_states()
	telegraphs.advance(delta)
	var warning_count := AbilityRules.phase_count(states, false)
	for enemy in AbilityRules.ordered_enemies(enemy_system.snapshot()):
		if run_state.finished:
			break
		if not enemy_system.is_active(enemy):
			continue
		var state := _state_for(enemy)
		_update_visibility(state, enemy, elapsed)
		match state["phase"]:
			"warning":
				_advance_warning(state, enemy, delta, elapsed)
			"executing":
				_advance_execution(state, enemy, delta, elapsed)
			"recovery":
				_advance_recovery(state, enemy, delta, elapsed)
			_:
				_advance_idle(enemy, delta, elapsed)
				if _can_begin(state, enemy, elapsed, warning_count):
					_begin_warning(state, enemy, elapsed)
					warning_count += 1
		AbilityRules.clamp_to_bounds(enemy, level.map.world_bounds)
	telegraphs.set_states(states)

func clear_all() -> void:
	for state in states.values():
		var enemy: Node = state["enemy"]
		if is_instance_valid(enemy):
			enemy.contact_enabled = true
	states.clear()
	if is_instance_valid(telegraphs):
		telegraphs.clear_warnings()

func _state_for(enemy: Node) -> Dictionary:
	var key := enemy.get_instance_id()
	if not states.has(key):
		states[key] = {
			"enemy": enemy, "phase": "idle", "phase_left": 0.0,
			"cooldown_until": 0.0, "visible_since": -1.0,
			"direction": Vector2.ZERO, "target": enemy.position,
			"start": enemy.position, "remaining": 0.0, "hit_done": false,
		}
	return states[key]

func _can_begin(state: Dictionary, enemy: Node, elapsed: float, warning_count: int) -> bool:
	var budget: EnemyAbilityBudgetConfig = level.enemy_ability_budget
	var ability_id := AbilityCatalog.ability_for_enemy(enemy.kind)
	if budget == null or ability_id.is_empty() or elapsed < budget.opening_protection_time:
		return false
	if not stage_director.current_stage().enabled_ability_ids.has(ability_id):
		return false
	if float(state["visible_since"]) < 0.0 or elapsed - float(state["visible_since"]) < VISIBLE_CAST_DELAY:
		return false
	if elapsed < float(state["cooldown_until"]) or elapsed - last_warning_start < budget.min_start_interval:
		return false
	if warning_count >= budget.max_telegraphs:
		return false
	if not enemy.is_elite and _elite_slot_reserved(elapsed, warning_count):
		return false
	var config := AbilityCatalog.ability(ability_id)
	if AbilityRules.warning_covers_player(enemy, player, config) and AbilityRules.player_danger_count(states, player.position) >= budget.max_player_danger_areas:
		return false
	if ability_id == "bat_bolt" and projectile_system.projectiles.size() >= budget.max_projectiles:
		return false
	var distance: float = enemy.position.distance_to(player.position)
	return distance >= float(config["min_range"]) and distance <= float(config["max_range"])


func _begin_warning(state: Dictionary, enemy: Node, elapsed: float) -> void:
	var ability_id := AbilityCatalog.ability_for_enemy(enemy.kind)
	var config := AbilityCatalog.ability(ability_id)
	var direction: Vector2 = enemy.position.direction_to(player.position)
	state["ability_id"] = ability_id
	state["phase"] = "warning"
	state["phase_left"] = float(config["warning"])
	state["direction"] = direction
	state["start"] = enemy.position
	state["target"] = AbilityRules.ability_target(enemy, player, direction, config)
	state["hit_done"] = false
	last_warning_start = elapsed
	audio.play_sfx("ui_select", -8.0, 1.15)


func _advance_warning(state: Dictionary, enemy: Node, delta: float, elapsed: float) -> void:
	if float(state["visible_since"]) < 0.0:
		state["phase"] = "idle"
		enemy.contact_enabled = true
		return
	var config := AbilityCatalog.ability(state["ability_id"])
	if state["ability_id"] == "bat_bolt":
		_advance_idle(enemy, delta, elapsed)
		if float(state["phase_left"]) > float(config["lock_time"]) + 0.0001:
			state["direction"] = enemy.position.direction_to(player.position)
			state["target"] = player.position
	else:
		enemy.advance_motion(Vector2.ZERO, 0.0, delta, elapsed)
	state["phase_left"] = float(state["phase_left"]) - delta
	if float(state["phase_left"]) <= 0.0001:
		_start_execution(state, enemy, elapsed)


func _start_execution(state: Dictionary, enemy: Node, elapsed: float) -> void:
	var config := AbilityCatalog.ability(state["ability_id"])
	match state["ability_id"]:
		"green_grub_roll":
			state["phase"] = "executing"
			state["remaining"] = float(config["distance"])
			enemy.contact_enabled = false
		"slime_jump":
			state["phase"] = "executing"
			state["phase_left"] = float(config["execute_time"])
			state["phase_total"] = float(config["execute_time"])
			state["start"] = enemy.position
			enemy.contact_enabled = false
		"bat_bolt":
			projectile_system.spawn_bolt(enemy, enemy.position, state["direction"], config, enemy.ability_damage_multiplier)
			_enter_recovery(state, enemy, elapsed)
		"brute_slam":
			if AbilityRules.player_in_sector(enemy.position, state["direction"], player.position, config):
				_emit_hit(enemy, config)
			_enter_recovery(state, enemy, elapsed)


func _advance_execution(state: Dictionary, enemy: Node, delta: float, elapsed: float) -> void:
	var config := AbilityCatalog.ability(state["ability_id"])
	if state["ability_id"] == "green_grub_roll":
		var before: Vector2 = enemy.position
		var movement_delta := minf(delta, float(state["remaining"]) / float(config["speed"]))
		var movement: Vector2 = enemy.advance_motion(state["direction"], float(config["speed"]), movement_delta, elapsed)
		state["remaining"] = float(state["remaining"]) - movement.length()
		if not state["hit_done"] and AbilityRules.segment_hits_circle(before, enemy.position, player.position, enemy.radius + 21.0):
			state["hit_done"] = true
			_emit_hit(enemy, config)
		if float(state["remaining"]) <= 0.01:
			_enter_recovery(state, enemy, elapsed)
	else:
		enemy.advance_motion(Vector2.ZERO, 0.0, delta, elapsed)
		state["phase_left"] = float(state["phase_left"]) - delta
		var progress: float = 1.0 - maxf(0.0, float(state["phase_left"])) / float(state["phase_total"])
		enemy.position = Vector2(state["start"]).lerp(Vector2(state["target"]), progress)
		if float(state["phase_left"]) <= 0.0:
			if enemy.position.distance_to(player.position) <= float(config["radius"]) + 21.0:
				_emit_hit(enemy, config)
			_enter_recovery(state, enemy, elapsed)


func _advance_recovery(state: Dictionary, enemy: Node, delta: float, elapsed: float) -> void:
	enemy.advance_motion(Vector2.ZERO, 0.0, delta, elapsed)
	state["phase_left"] = float(state["phase_left"]) - delta
	if float(state["phase_left"]) <= 0.0:
		state["phase"] = "idle"
		var cooldown: float = AbilityCatalog.ability(state["ability_id"])["cooldown"]
		state["cooldown_until"] = elapsed + cooldown * rng.randf_range(0.85, 1.15)


func _enter_recovery(state: Dictionary, enemy: Node, _elapsed: float) -> void:
	var config := AbilityCatalog.ability(state["ability_id"])
	state["phase"] = "recovery"
	state["phase_left"] = float(config["recovery"])
	enemy.contact_enabled = true


func _advance_idle(enemy: Node, delta: float, elapsed: float) -> void:
	enemy.advance_motion(AbilityRules.movement_direction(enemy, player.position), enemy.speed, delta, elapsed)


func _emit_hit(enemy: Node, config: Dictionary) -> void:
	var hit := PlayerHitData.create(float(config["damage"]) * enemy.ability_damage_multiplier, enemy, config["hit_type"], enemy.position, float(config.get("knockback", 0.0)))
	player_hit_requested.emit(hit)


func _update_visibility(state: Dictionary, enemy: Node, elapsed: float) -> void:
	if _is_visible(enemy.position):
		if float(state["visible_since"]) < 0.0:
			state["visible_since"] = elapsed
	else:
		state["visible_since"] = -1.0


func _is_visible(position: Vector2) -> bool:
	var viewport := get_viewport()
	var size := viewport.get_visible_rect().size if viewport != null else Vector2(540, 960)
	return AbilityRules.is_visible(position, player.position, size)


func _elite_slot_reserved(elapsed: float, warning_count: int) -> bool:
	if warning_count < level.enemy_ability_budget.max_telegraphs - 1:
		return false
	for enemy in enemy_system.snapshot():
		if enemy.is_elite and _is_visible(enemy.position):
			var state := _state_for(enemy)
			if state["phase"] == "idle" and elapsed >= float(state["cooldown_until"]):
				return true
	return false


func _cleanup_states() -> void:
	for key in states.keys():
		if not is_instance_valid(states[key]["enemy"]):
			states.erase(key)


func _on_enemy_removed(enemy: Node) -> void:
	states.erase(enemy.get_instance_id())
	telegraphs.set_states(states)
