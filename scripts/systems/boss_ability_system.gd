extends Node2D

signal player_hit_requested(hit: PlayerHit)

const AbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const AbilityRules = preload("res://scripts/systems/enemy_ability_rules.gd")
const PlayerHitData = preload("res://scripts/combat/player_hit.gd")
const TelegraphRenderer = preload("res://scripts/presentation/enemy_telegraph_renderer.gd")

var level: LevelConfig
var run_state: RefCounted
var player: Node2D
var enemy_system: Node2D
var audio: Node
var effects: Node2D
var rng: RandomNumberGenerator
var boss: Node
var telegraphs: Node2D
var state: Dictionary = {}
var skill_cursor := 0
var last_skill_id := ""
var forced_triple_used := false
var skill_history := PackedStringArray()


func configure(level_config: LevelConfig, state_ref: RefCounted, player_node: Node2D, enemies: Node2D, audio_manager: Node, combat_effects: Node2D, random: RandomNumberGenerator) -> void:
	level = level_config
	run_state = state_ref
	player = player_node
	enemy_system = enemies
	audio = audio_manager
	effects = combat_effects
	rng = random
	telegraphs = TelegraphRenderer.new()
	add_child(telegraphs)
	_reset_state()


func activate(boss_node: Node, elapsed: float) -> void:
	boss = boss_node
	skill_cursor = 0
	last_skill_id = ""
	forced_triple_used = false
	skill_history.clear()
	_reset_state()
	state["phase"] = "idle"
	state["ready_at"] = elapsed + 0.8


func advance(delta: float, elapsed: float) -> void:
	if run_state.finished or run_state.paused or not is_instance_valid(boss):
		return
	telegraphs.advance(delta)
	var combat_phase := level.boss.phase_for_health(boss.health / maxf(boss.max_health, 0.001))
	if combat_phase == 3 and int(state["combat_phase"]) < 3:
		state["force_triple_dash"] = true
	state["combat_phase"] = combat_phase
	match state["phase"]:
		"warning":
			_advance_warning(delta, elapsed)
		"executing":
			_advance_execution(delta, elapsed)
		"recovery":
			_advance_recovery(delta, elapsed)
		_:
			boss.advance_motion(boss.position.direction_to(player.position), boss.speed, delta, elapsed)
			if elapsed >= float(state["ready_at"]):
				_begin_next_skill(elapsed)
	AbilityRules.clamp_to_bounds(boss, level.map.world_bounds)
	_refresh_telegraph()


func clear_all() -> void:
	if is_instance_valid(boss):
		if not boss.recognizing:
			boss.contact_enabled = true
		boss.clear_ability_visual()
	boss = null
	_reset_state()
	if is_instance_valid(telegraphs):
		telegraphs.clear_warnings()


func active_warning_count() -> int:
	return int(state.get("phase", "") == "warning")


func current_combat_phase() -> int:
	return int(state.get("combat_phase", 0))


func _reset_state() -> void:
	state = {
		"phase": "inactive", "combat_phase": 0, "phase_left": 0.0, "ready_at": INF,
		"ability_id": "", "direction": Vector2.ZERO, "target": Vector2.INF,
		"remaining_distance": 0.0, "sequence_remaining": 0, "hit_done": false,
		"force_triple_dash": false, "triple_dash_active": false,
	}


func _begin_next_skill(elapsed: float) -> void:
	var ability_id := _next_skill_id()
	if ability_id.is_empty():
		state["ready_at"] = elapsed + 0.5
		return
	var config := AbilityCatalog.ability(ability_id)
	state["ability_id"] = ability_id
	state["sequence_remaining"] = _sequence_count(config)
	if bool(state["triple_dash_active"]):
		state["force_triple_dash"] = false
	_begin_warning(config)
	last_skill_id = ability_id
	skill_history.append(ability_id)


func _next_skill_id() -> String:
	var skills: PackedStringArray = level.boss.skill_ids
	if skills.is_empty():
		return ""
	state["triple_dash_active"] = false
	if bool(state["force_triple_dash"]) and not forced_triple_used:
		for skill_id in skills:
			if str(AbilityCatalog.ability(skill_id).get("runtime_kind", "")) == "boss_dash" and skill_id != last_skill_id:
				forced_triple_used = true
				state["triple_dash_active"] = true
				return skill_id
	for _attempt in range(skills.size()):
		var ability_id := skills[skill_cursor % skills.size()]
		skill_cursor += 1
		if ability_id != last_skill_id or skills.size() == 1:
			return ability_id
	return skills[skill_cursor % skills.size()]


func _sequence_count(config: Dictionary) -> int:
	var combat_phase := int(state["combat_phase"])
	match str(config["runtime_kind"]):
		"boss_dash":
			if combat_phase == 3 and bool(state["triple_dash_active"]):
				return 3
			return 1 if combat_phase == 1 else 2
		"boss_marks":
			return 2 if combat_phase == 1 else 3
	return 1


func _begin_warning(config: Dictionary) -> void:
	state["phase"] = "warning"
	state["phase_left"] = float(config["warning"])
	state["direction"] = boss.position.direction_to(player.position)
	state["target"] = player.position
	state["hit_done"] = false
	boss.contact_enabled = true
	boss.set_ability_visual(state["ability_id"], "warning", 0.0, state["direction"])
	_play_cue(config, "warning_cue")
	_play_cue(config, "charge_cue", -4.0)


func _advance_warning(delta: float, elapsed: float) -> void:
	var config := AbilityCatalog.ability(state["ability_id"])
	boss.advance_motion(Vector2.ZERO, 0.0, delta, elapsed)
	state["phase_left"] = float(state["phase_left"]) - delta
	var progress := clampf(1.0 - float(state["phase_left"]) / maxf(float(config["warning"]), 0.001), 0.0, 1.0)
	boss.set_ability_visual(state["ability_id"], "warning", progress, state["direction"])
	if float(state["phase_left"]) <= 0.0:
		_start_execution(config, elapsed)


func _start_execution(config: Dictionary, elapsed: float) -> void:
	_play_cue(config, "execute_cue", -1.0, rng.randf_range(0.98, 1.03))
	match str(config["runtime_kind"]):
		"boss_dash":
			state["phase"] = "executing"
			state["remaining_distance"] = float(config["distance"])
			boss.contact_enabled = false
			boss.set_ability_visual(state["ability_id"], "executing", 0.0, state["direction"])
		"boss_tail_sweep", "boss_marks":
			_apply_area_hit(config)
			state["sequence_remaining"] = int(state["sequence_remaining"]) - 1
			if int(state["sequence_remaining"]) > 0:
				_begin_warning(config)
			else:
				_enter_recovery(config, elapsed)


func _advance_execution(delta: float, elapsed: float) -> void:
	var config := AbilityCatalog.ability(state["ability_id"])
	var before: Vector2 = boss.position
	var movement_delta := minf(delta, float(state["remaining_distance"]) / float(config["speed"]))
	var movement: Vector2 = boss.advance_motion(state["direction"], float(config["speed"]), movement_delta, elapsed)
	state["remaining_distance"] = float(state["remaining_distance"]) - movement.length()
	var progress := clampf(1.0 - float(state["remaining_distance"]) / maxf(float(config["distance"]), 0.001), 0.0, 1.0)
	boss.set_ability_visual(state["ability_id"], "executing", progress, state["direction"])
	if not bool(state["hit_done"]) and AbilityRules.segment_hits_circle(before, boss.position, player.position, boss.radius + 21.0):
		state["hit_done"] = true
		_emit_hit(config, boss.position)
	if float(state["remaining_distance"]) <= 0.01:
		state["sequence_remaining"] = int(state["sequence_remaining"]) - 1
		boss.contact_enabled = true
		if int(state["sequence_remaining"]) > 0:
			_begin_warning(config)
		else:
			_enter_recovery(config, elapsed)


func _apply_area_hit(config: Dictionary) -> void:
	if AbilityRules.telegraph_covers_point(boss.position, state["direction"], player.position, config, state["target"]):
		state["hit_done"] = true
		var origin: Vector2 = state["target"] if str(config["shape"]) == "circle" else boss.position
		_emit_hit(config, origin)


func _emit_hit(config: Dictionary, origin: Vector2) -> void:
	_play_cue(config, "hit_cue", -1.0, rng.randf_range(0.98, 1.03))
	var hit := PlayerHitData.create(float(config["damage"]), boss, str(config["hit_type"]), origin, float(config.get("knockback", 0.0)))
	player_hit_requested.emit(hit)


func _enter_recovery(config: Dictionary, elapsed: float) -> void:
	state["phase"] = "recovery"
	state["phase_left"] = float(config["recovery"])
	boss.contact_enabled = true
	boss.set_ability_visual(state["ability_id"], "recovery", 0.0, state["direction"])
	state["ready_at"] = elapsed + float(config["recovery"]) + level.boss.skill_interval(int(state["combat_phase"]))


func _advance_recovery(delta: float, elapsed: float) -> void:
	var config := AbilityCatalog.ability(state["ability_id"])
	boss.advance_motion(Vector2.ZERO, 0.0, delta, elapsed)
	state["phase_left"] = float(state["phase_left"]) - delta
	var progress := clampf(1.0 - float(state["phase_left"]) / maxf(float(config["recovery"]), 0.001), 0.0, 1.0)
	boss.set_ability_visual(state["ability_id"], "recovery", progress, state["direction"])
	if float(state["phase_left"]) <= 0.0:
		state["phase"] = "idle"
		boss.clear_ability_visual()


func _refresh_telegraph() -> void:
	if state["phase"] != "warning" or not is_instance_valid(boss):
		telegraphs.clear_warnings()
		return
	var config := AbilityCatalog.ability(state["ability_id"])
	telegraphs.set_locked_warning(boss.position, config, state)


func _play_cue(config: Dictionary, field: String, volume_db := 0.0, pitch_scale := 1.0) -> void:
	var cue_id := str(config.get(field, ""))
	if not cue_id.is_empty():
		audio.play_sfx(cue_id, volume_db, pitch_scale)
