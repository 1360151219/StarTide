extends RefCounted

const RunState = preload("res://scripts/run/run_state.gd")
const RunBalanceSample = preload("res://scripts/run/run_balance_sample.gd")

var _balance_sample: RefCounted
var _balance_sample_store: RefCounted


func begin_balance_sample(hero_id: String, level: LevelConfig, progression: Dictionary, random_streams: Dictionary, sample_store: RefCounted = null, sample_context: Dictionary = {}) -> void:
	_balance_sample = RunBalanceSample.new()
	_balance_sample_store = sample_store
	_balance_sample.begin(hero_id, level, progression, random_streams, sample_context)


func set_resolved_content_pool(pool: Dictionary) -> void:
	_balance_sample.set_resolved_content_pool(pool)


func attach_balance_sources(damage_resolver: RefCounted, enemies: Node, player: Node, skills: Node) -> void:
	damage_resolver.damage_applied.connect(_balance_sample.record_damage_taken)
	damage_resolver.damage_absorbed.connect(_balance_sample.record_damage_absorbed)
	damage_resolver.hit_rejected.connect(_balance_sample.record_hit_rejected)
	enemies.damage_resolved.connect(_balance_sample.record_damage_dealt)
	player.healing_resolved.connect(_balance_sample.record_healing)
	skills.skill_released.connect(_balance_sample.record_skill_release)


func record_movement(delta: float, moved: bool) -> void:
	if _balance_sample != null:
		_balance_sample.record_movement(delta, moved)


func record_skill_uptime(delta: float, skill_ids: PackedStringArray) -> void:
	if _balance_sample != null:
		_balance_sample.record_skill_uptime(delta, skill_ids)


func record_upgrade(elapsed: float, choice: Dictionary) -> void:
	if _balance_sample != null:
		_balance_sample.record_upgrade(elapsed, choice)


func finalize(records: RefCounted, state: RefCounted, level: LevelConfig, _passives: RefCounted, build_state: RefCounted, player: Node2D = null, balance_sample: RefCounted = null) -> Dictionary:
	var result: Dictionary = records.record_level_run(
		state.hero_id, level, state.victory, state.elite_defeated,
		state.kills, state.player_level, state.elapsed
	)
	var discoveries: Array[Dictionary] = records.new_content_discoveries()
	var presentation := {
		"heading": _heading(state, level),
		"outcome_hint": _outcome_hint(state, level),
		"won": state.victory,
		"hero_id": state.hero_id,
		"level_id": state.level_id,
		"duration_text": _format_time(state.elapsed),
		"kills": state.kills,
		"player_level": state.player_level,
		"elite_defeated": state.elite_defeated,
		"boss_defeated": state.boss_defeated,
		"new_record": bool(result["new_record"]),
		"best_kills": int(result["record"]["best_kills"]),
		"first_clear": bool(result["first_clear"]),
		"first_clear_hint": _first_clear_hint(level, bool(result["first_clear"])),
		"newly_unlocked": str(result["newly_unlocked"]),
		"progression_reward": result["progression_reward"],
		"equipment_reward": result["equipment_reward"],
		"random_equipment_reward": result["random_equipment_reward"],
		"discovery_count": discoveries.size(),
		"discoveries": discoveries,
		"build_snapshot": build_state.snapshot(),
	}
	var sample: RefCounted = balance_sample if balance_sample != null else _balance_sample
	if sample != null and player != null:
		presentation["balance_sample"] = sample.snapshot(state, player, build_state)
		presentation["balance_sample_persisted"] = _balance_sample_store.append(presentation["balance_sample"]) == OK if _balance_sample_store != null else false
	return presentation


func _heading(state: RefCounted, level: LevelConfig) -> String:
	if not state.victory:
		return level.victory.failure_heading
	if level.victory.is_perfect(state.elite_defeated):
		return level.victory.perfect_heading
	return level.victory.normal_heading


func _outcome_hint(state: RefCounted, level: LevelConfig) -> String:
	if state.victory:
		if state.boss_defeated:
			return "%s · Boss 已认可" % level.display_name
		return "%s · %s" % [level.display_name, "精英已击破" if state.elite_defeated else "星门已守住"]
	if state.end_reason == RunState.END_OBJECTIVE_TIMEOUT:
		return "时间结束 · 目标尚未完成"
	var remaining := maxf(0.0, level.duration - state.elapsed)
	return "%s · 还差 %s" % [victory_hint(level), _format_time(remaining)]


func _first_clear_hint(level: LevelConfig, first_clear: bool) -> String:
	if not first_clear or level.reward == null:
		return ""
	return "%s · %s" % [level.reward.display_name, level.reward.description]


func victory_hint(level: LevelConfig) -> String:
	if level.victory.mode == VictoryConfig.DEFEAT_BOSS:
		return "击败%s" % level.boss.display_name
	if level.victory.mode == VictoryConfig.SURVIVE_DURATION:
		return "坚持 %d 秒" % level.duration
	if level.victory.mode == VictoryConfig.DEFEAT_ELITE:
		return "击败%s" % level.elite.display_name
	return "击败%s并坚持 %d 秒" % [level.elite.display_name, level.duration]


func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
