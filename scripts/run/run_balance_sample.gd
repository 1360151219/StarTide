extends RefCounted

const Contract = preload("res://scripts/run/balance_sample_contract.gd")

var sample_id := ""
var hero_id := ""
var level_id := ""
var recommended_score := 0
var context: Dictionary = {}
var opening_permanent: Dictionary = {}
var random_streams: Dictionary = {}
var resolved_content_pool: Dictionary = {}
var confirmed_hit_damage_by_source: Dictionary = {}
var applied_damage_by_source: Dictionary = {}
var overkill_damage_by_source: Dictionary = {}
var connected_incoming_damage_by_source: Dictionary = {}
var damage_taken_by_source: Dictionary = {}
var damage_absorbed_by_source: Dictionary = {}
var healing_requested_by_source: Dictionary = {}
var healing_received_by_source: Dictionary = {}
var overhealing_by_source: Dictionary = {}
var skill_releases_by_source: Dictionary = {}
var enemy_hits_by_source: Dictionary = {}
var player_hits_taken_by_source: Dictionary = {}
var player_hits_absorbed_by_source: Dictionary = {}
var invulnerable_rejections_by_source: Dictionary = {}
var fatal_overkill_by_source: Dictionary = {}
var skill_active_seconds: Dictionary = {}
var upgrade_timeline: Array[Dictionary] = []
var movement_seconds := 0.0


func begin(selected_hero_id: String, level: LevelConfig, permanent_snapshot: Dictionary, rng_streams: Dictionary, sample_context: Dictionary = {}) -> void:
	hero_id = selected_hero_id
	level_id = level.level_id
	recommended_score = level.recommended_power
	context = sample_context.duplicate(true)
	if context.is_empty():
		context = {"mode": "player"}
	sample_id = str(context.get("sample_id", ""))
	if sample_id.is_empty():
		sample_id = "%s-%s-%d-%d" % [hero_id, level_id, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	opening_permanent = _opening_snapshot(permanent_snapshot)
	random_streams = _random_stream_snapshot(rng_streams)
	resolved_content_pool.clear()
	confirmed_hit_damage_by_source.clear()
	applied_damage_by_source.clear()
	overkill_damage_by_source.clear()
	connected_incoming_damage_by_source.clear()
	damage_taken_by_source.clear()
	damage_absorbed_by_source.clear()
	healing_requested_by_source.clear()
	healing_received_by_source.clear()
	overhealing_by_source.clear()
	skill_releases_by_source.clear()
	enemy_hits_by_source.clear()
	player_hits_taken_by_source.clear()
	player_hits_absorbed_by_source.clear()
	invulnerable_rejections_by_source.clear()
	fatal_overkill_by_source.clear()
	skill_active_seconds.clear()
	upgrade_timeline.clear()
	movement_seconds = 0.0


func set_resolved_content_pool(pool: Dictionary) -> void:
	resolved_content_pool = {
		"skill_ids": Array(pool.get("skill_ids", PackedStringArray())).duplicate(),
		"relic_ids": Array(pool.get("relic_ids", PackedStringArray())).duplicate(),
		"skill_weights": pool.get("skill_weights", {}).duplicate(true),
		"relic_weights": pool.get("relic_weights", {}).duplicate(true),
	}


func record_skill_release(skill_id: String) -> void:
	_increment(skill_releases_by_source, "skill:%s" % skill_id)


func record_damage_dealt(source_id: String, attempted: float, applied: float) -> void:
	var safe_source := _source(source_id)
	var safe_attempted := maxf(0.0, attempted)
	var safe_applied := clampf(applied, 0.0, safe_attempted)
	_add(confirmed_hit_damage_by_source, safe_source, safe_attempted)
	_add(applied_damage_by_source, safe_source, safe_applied)
	_add(overkill_damage_by_source, safe_source, safe_attempted - safe_applied)
	_increment(enemy_hits_by_source, safe_source)


func record_damage_taken(source_id: String, attempted: float, applied: float) -> void:
	var safe_source := _source(source_id)
	var safe_attempted := maxf(0.0, attempted)
	var safe_applied := clampf(applied, 0.0, safe_attempted)
	_add(connected_incoming_damage_by_source, safe_source, safe_attempted)
	_add(damage_taken_by_source, safe_source, safe_applied)
	_add(fatal_overkill_by_source, safe_source, safe_attempted - safe_applied)
	_increment(player_hits_taken_by_source, safe_source)


func record_damage_absorbed(source_id: String, amount: float) -> void:
	var safe_source := _source(source_id)
	var safe_amount := maxf(0.0, amount)
	_add(connected_incoming_damage_by_source, safe_source, safe_amount)
	_add(damage_absorbed_by_source, safe_source, safe_amount)
	_increment(player_hits_absorbed_by_source, safe_source)


func record_hit_rejected(source_id: String, reason: String) -> void:
	if reason == "invulnerable":
		_increment(invulnerable_rejections_by_source, _source(source_id))


func record_healing(source_id: String, requested: float, applied: float, overheal: float) -> void:
	var safe_source := _source(source_id)
	_add(healing_requested_by_source, safe_source, maxf(0.0, requested))
	_add(healing_received_by_source, safe_source, maxf(0.0, applied))
	_add(overhealing_by_source, safe_source, maxf(0.0, overheal))


func record_movement(delta: float, moved: bool) -> void:
	if moved:
		movement_seconds += maxf(0.0, delta)


func record_skill_uptime(delta: float, skill_ids: PackedStringArray) -> void:
	for skill_id in skill_ids:
		_add(skill_active_seconds, "skill:%s" % skill_id, maxf(0.0, delta))


func record_upgrade(elapsed: float, choice: Dictionary) -> void:
	upgrade_timeline.append({
		"elapsed_seconds": elapsed,
		"choice_key": str(choice.get("choice_key", "")),
		"kind": str(choice.get("kind", "")),
		"content_id": str(choice.get("content_id", "")),
		"target_level": int(choice.get("target_level", 0)),
		"branch_id": str(choice.get("branch_id", "")),
	})


func snapshot(state: RefCounted, player: Node2D, build_state: RefCounted) -> Dictionary:
	return {
		"schema_version": Contract.SCHEMA_VERSION,
		"build_id": Contract.BUILD_ID,
		"content_balance_version": Contract.CONTENT_BALANCE_VERSION,
		"sample_id": sample_id,
		"captured_at_unix": int(Time.get_unix_time_from_system()),
		"hero_id": hero_id,
		"level_id": level_id,
		"recommended_score": recommended_score,
		"simulation_step_seconds": float(context.get("step_seconds", 0.0)),
		"context": context.duplicate(true),
		"opening_permanent": opening_permanent.duplicate(true),
		"random_streams": random_streams.duplicate(true),
		"resolved_content_pool": resolved_content_pool.duplicate(true),
		"final_build": build_state.snapshot(),
		"upgrade_timeline": upgrade_timeline.duplicate(true),
		"outcome": {
			"won": state.victory,
			"end_reason": state.end_reason,
			"duration_seconds": state.elapsed,
			"kills": state.kills,
			"player_level": state.player_level,
			"remaining_health": player.health,
			"max_health": player.max_health,
		},
		"combat": {
			"confirmed_hit_damage_by_source": confirmed_hit_damage_by_source.duplicate(true),
			"applied_damage_by_source": applied_damage_by_source.duplicate(true),
			"overkill_damage_by_source": overkill_damage_by_source.duplicate(true),
			"connected_incoming_damage_by_source": connected_incoming_damage_by_source.duplicate(true),
			"damage_taken_by_source": damage_taken_by_source.duplicate(true),
			"damage_absorbed_by_source": damage_absorbed_by_source.duplicate(true),
			"healing_requested_by_source": healing_requested_by_source.duplicate(true),
			"healing_received_by_source": healing_received_by_source.duplicate(true),
			"overhealing_by_source": overhealing_by_source.duplicate(true),
			"skill_releases_by_source": skill_releases_by_source.duplicate(true),
			"enemy_hits_by_source": enemy_hits_by_source.duplicate(true),
			"player_hits_taken_by_source": player_hits_taken_by_source.duplicate(true),
			"player_hits_absorbed_by_source": player_hits_absorbed_by_source.duplicate(true),
			"invulnerable_rejections_by_source": invulnerable_rejections_by_source.duplicate(true),
			"fatal_overkill_by_source": fatal_overkill_by_source.duplicate(true),
			"skill_active_seconds": skill_active_seconds.duplicate(true),
			"movement_seconds": movement_seconds,
		},
	}


func _opening_snapshot(permanent_snapshot: Dictionary) -> Dictionary:
	var power: Dictionary = permanent_snapshot.get("power", {})
	var equipment: Dictionary = permanent_snapshot.get("equipment", {})
	return {
		"score": int(power.get("total", 0)),
		"score_formula_version": int(power.get("formula_version", 0)),
		"score_purpose": str(power.get("purpose", "")),
		"score_calibrated": bool(power.get("calibrated", false)),
		"hero_level": int(permanent_snapshot.get("level", 1)),
		"hero_xp": int(permanent_snapshot.get("hero_xp", 0)),
		"training": permanent_snapshot.get("training", {}).duplicate(true),
		"resolved_stats": permanent_snapshot.get("resolved_stats", {}).duplicate(true),
		"equipment_loadout": equipment.get("loadout", {}).duplicate(true),
		"equipped_items": equipment.get("equipped_items", []).duplicate(true),
	}


func _random_stream_snapshot(rng_streams: Dictionary) -> Dictionary:
	var result := {}
	for stream_id in rng_streams:
		var rng: Variant = rng_streams[stream_id]
		if rng is RandomNumberGenerator:
			result[str(stream_id)] = {"seed": rng.seed, "state": rng.state}
	return result


func _source(source_id: String) -> String:
	return source_id if not source_id.is_empty() else "unknown"


func _add(target: Dictionary, source_id: String, amount: float) -> void:
	if amount <= 0.0:
		return
	target[source_id] = float(target.get(source_id, 0.0)) + amount


func _increment(target: Dictionary, source_id: String) -> void:
	target[source_id] = int(target.get(source_id, 0)) + 1
