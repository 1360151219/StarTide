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
var effects: Node2D
var states: Dictionary = {}
var last_warning_start := -INF
var telegraphs: Node2D
var viewport_size := Vector2(540, 960)

func configure(level_config: LevelConfig, state: RefCounted, player_node: Node2D, enemies: Node2D, projectiles: Node2D, director: RefCounted, random: RandomNumberGenerator, combat_effects: Node2D) -> void:
	level = level_config
	run_state = state
	player = player_node
	enemy_system = enemies
	projectile_system = projectiles
	stage_director = director
	rng = random
	effects = combat_effects
	telegraphs = TelegraphRenderer.new()
	add_child(telegraphs)
	enemy_system.enemy_removed.connect(_on_enemy_removed)

func advance(delta: float, elapsed: float) -> void:
	if run_state.finished or run_state.paused:
		return
	AbilityRules.cleanup_states(states)
	telegraphs.advance(delta)
	viewport_size = get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(540, 960)
	var warning_count := AbilityRules.phase_count(states, false)
	for enemy in AbilityRules.ordered_enemies(enemy_system.snapshot()):
		if run_state.finished:
			break
		if not enemy_system.is_active(enemy):
			continue
		var state := _state_for(enemy)
		AbilityRules.update_visibility(state, enemy.position, player.position, viewport_size, elapsed)
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
			if enemy.has_method("clear_ability_visual"):
				enemy.clear_ability_visual()
	states.clear()
	if is_instance_valid(telegraphs):
		telegraphs.clear_warnings()

func _state_for(enemy: Node) -> Dictionary:
	var key := enemy.get_instance_id()
	if not states.has(key):
		states[key] = {
			"enemy": enemy, "phase": "idle", "phase_left": 0.0,
			"cooldown_until": 0.0, "visible_since": -1.0,
				"direction": Vector2.ZERO, "target": Vector2.INF,
				"start": enemy.position, "remaining": 0.0, "hit_done": false,
				"trail_elapsed": 0.0,
			}
	return states[key]

func _can_begin(state: Dictionary, enemy: Node, elapsed: float, warning_count: int) -> bool:
	var budget: EnemyAbilityBudgetConfig = level.enemy_ability_budget
	var ability_id: String = enemy.ability_id
	if budget == null or ability_id.is_empty() or not budget.allows_ability(ability_id) or elapsed < budget.opening_protection_time:
		return false
	if float(state["visible_since"]) < 0.0 or elapsed - float(state["visible_since"]) < VISIBLE_CAST_DELAY:
		return false
	if elapsed < float(state["cooldown_until"]) or elapsed - last_warning_start < budget.min_start_interval:
		return false
	if warning_count >= budget.max_telegraphs:
		return false
	if not enemy.is_elite and AbilityRules.elite_slot_reserved(enemy_system, states, level, elapsed, warning_count, viewport_size):
		return false
	var config := AbilityCatalog.ability(ability_id)
	if config.is_empty():
		return false
	if AbilityRules.warning_covers_player(enemy, player, config) and AbilityRules.player_danger_count(states, player.position) >= budget.max_player_danger_areas:
		return false
	if str(config["runtime_kind"]) == "bolt" and projectile_system.projectiles.size() >= budget.max_projectiles:
		return false
	var distance: float = enemy.position.distance_to(player.position)
	return distance >= float(config["min_range"]) and distance <= float(config["max_range"])


func _begin_warning(state: Dictionary, enemy: Node, elapsed: float) -> void:
	var ability_id: String = enemy.ability_id
	var config := AbilityCatalog.ability(ability_id)
	var direction: Vector2 = enemy.position.direction_to(player.position)
	state["ability_id"] = ability_id
	state["phase"] = "warning"
	state["phase_left"] = float(config["warning"])
	state["direction"] = direction
	state["target"] = player.position
	state["start"] = enemy.position
	state["hit_done"] = false
	state["trail_elapsed"] = 0.0
	last_warning_start = elapsed
	if enemy.has_method("set_ability_visual"):
		enemy.set_ability_visual(ability_id, "warning", 0.0, direction)


func _advance_warning(state: Dictionary, enemy: Node, delta: float, elapsed: float) -> void:
	if float(state["visible_since"]) < 0.0:
		state["phase"] = "idle"
		enemy.contact_enabled = true
		if enemy.has_method("clear_ability_visual"):
			enemy.clear_ability_visual()
		return
	var config := AbilityCatalog.ability(state["ability_id"])
	if str(config["runtime_kind"]) == "bolt":
		_advance_idle(enemy, delta, elapsed)
		if float(state["phase_left"]) > float(config["lock_time"]) + 0.0001:
			state["direction"] = enemy.position.direction_to(player.position)
	else:
		enemy.advance_motion(Vector2.ZERO, 0.0, delta, elapsed)
	state["phase_left"] = float(state["phase_left"]) - delta
	var warning_progress := clampf(1.0 - float(state["phase_left"]) / maxf(float(config["warning"]), 0.001), 0.0, 1.0)
	if enemy.has_method("set_ability_visual"):
		enemy.set_ability_visual(state["ability_id"], "warning", warning_progress, state["direction"])
	if float(state["phase_left"]) <= 0.0001:
		_start_execution(state, enemy, elapsed)


func _start_execution(state: Dictionary, enemy: Node, elapsed: float) -> void:
	var config := AbilityCatalog.ability(state["ability_id"])
	match str(config["runtime_kind"]):
		"roll":
			state["phase"] = "executing"
			state["remaining"] = float(config["distance"])
			enemy.contact_enabled = false
			if enemy.has_method("set_ability_visual"):
				enemy.set_ability_visual(state["ability_id"], "executing", 0.0, state["direction"])
		"bolt":
			effects.add_effect(enemy.position, enemy.radius + 28.0, Color("a66be8"), 0.26, "bat_launch")
			if enemy.has_method("set_ability_visual"):
				enemy.set_ability_visual(state["ability_id"], "executing", 1.0, state["direction"])
			projectile_system.spawn_bolt(enemy, enemy.position, state["direction"], config, enemy.ability_damage_multiplier)
			_enter_recovery(state, enemy, elapsed)
		"burst":
			if AbilityRules.telegraph_covers_point(enemy.position, state["direction"], player.position, config, state["target"]):
				state["hit_done"] = true
				_emit_hit(enemy, config)
			_enter_recovery(state, enemy, elapsed)


func _advance_execution(state: Dictionary, enemy: Node, delta: float, elapsed: float) -> void:
	var config := AbilityCatalog.ability(state["ability_id"])
	var before: Vector2 = enemy.position
	var movement_delta := minf(delta, float(state["remaining"]) / float(config["speed"]))
	var movement: Vector2 = enemy.advance_motion(state["direction"], float(config["speed"]), movement_delta, elapsed)
	state["remaining"] = float(state["remaining"]) - movement.length()
	state["trail_elapsed"] = float(state["trail_elapsed"]) + delta
	if float(state["trail_elapsed"]) >= 0.06:
		state["trail_elapsed"] = 0.0
		effects.add_effect(enemy.position, enemy.radius + 12.0, Color("8bcf65"), 0.24, "grub_roll_trail", {"direction": state["direction"]})
	var execution_progress := clampf(1.0 - float(state["remaining"]) / maxf(float(config["distance"]), 0.001), 0.0, 1.0)
	if enemy.has_method("set_ability_visual"):
		enemy.set_ability_visual(state["ability_id"], "executing", execution_progress, state["direction"])
	if not state["hit_done"] and AbilityRules.segment_hits_circle(before, enemy.position, player.position, enemy.radius + 21.0):
		state["hit_done"] = true
		_emit_hit(enemy, config)
	if float(state["remaining"]) <= 0.01:
		_enter_recovery(state, enemy, elapsed)


func _advance_recovery(state: Dictionary, enemy: Node, delta: float, elapsed: float) -> void:
	enemy.advance_motion(Vector2.ZERO, 0.0, delta, elapsed)
	state["phase_left"] = float(state["phase_left"]) - delta
	var recovery_duration := maxf(float(AbilityCatalog.ability(state["ability_id"])["recovery"]), 0.001)
	var recovery_progress := clampf(1.0 - float(state["phase_left"]) / recovery_duration, 0.0, 1.0)
	if enemy.has_method("set_ability_visual"):
		enemy.set_ability_visual(state["ability_id"], "recovery", recovery_progress, state["direction"])
	if float(state["phase_left"]) <= 0.0:
		state["phase"] = "idle"
		var cooldown: float = AbilityCatalog.ability(state["ability_id"])["cooldown"]
		state["cooldown_until"] = elapsed + cooldown * rng.randf_range(0.85, 1.15)
		if enemy.has_method("clear_ability_visual"):
			enemy.clear_ability_visual()


func _enter_recovery(state: Dictionary, enemy: Node, _elapsed: float) -> void:
	var config := AbilityCatalog.ability(state["ability_id"])
	state["phase"] = "recovery"
	state["phase_left"] = float(config["recovery"])
	enemy.contact_enabled = true
	if str(config["runtime_kind"]) == "roll" and not bool(state["hit_done"]):
		effects.add_effect(enemy.position, enemy.radius + 24.0, Color("ffe36b"), float(config["recovery"]), "grub_recover")


func _advance_idle(enemy: Node, delta: float, elapsed: float) -> void:
	enemy.advance_motion(AbilityRules.movement_direction(enemy, player.position), enemy.speed, delta, elapsed)


func _emit_hit(enemy: Node, config: Dictionary) -> void:
	var hit := PlayerHitData.create(float(config["damage"]) * enemy.ability_damage_multiplier, enemy, config["hit_type"], enemy.position, float(config.get("knockback", 0.0)))
	player_hit_requested.emit(hit)


func _on_enemy_removed(enemy: Node) -> void:
	if is_instance_valid(enemy) and enemy.has_method("clear_ability_visual"):
		enemy.clear_ability_visual()
	states.erase(enemy.get_instance_id())
	telegraphs.set_states(states)
