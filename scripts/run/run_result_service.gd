extends RefCounted

const RunState = preload("res://scripts/run/run_state.gd")


func finalize(records: RefCounted, state: RefCounted, level: LevelConfig, _passives: RefCounted, build_state: RefCounted) -> Dictionary:
	var result: Dictionary = records.record_level_run(
		state.hero_id, level, state.victory, state.elite_defeated,
		state.kills, state.player_level, state.elapsed
	)
	var discoveries: Array[Dictionary] = records.new_content_discoveries()
	return {
		"heading": _heading(state, level),
		"outcome_hint": _outcome_hint(state, level),
		"won": state.victory,
		"hero_id": state.hero_id,
		"level_id": state.level_id,
		"duration_text": _format_time(state.elapsed),
		"kills": state.kills,
		"player_level": state.player_level,
		"elite_defeated": state.elite_defeated,
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


func _heading(state: RefCounted, level: LevelConfig) -> String:
	if not state.victory:
		return level.victory.failure_heading
	if level.victory.is_perfect(state.elite_defeated):
		return level.victory.perfect_heading
	return level.victory.normal_heading


func _outcome_hint(state: RefCounted, level: LevelConfig) -> String:
	if state.victory:
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
	if level.victory.mode == VictoryConfig.SURVIVE_DURATION:
		return "坚持 %d 秒" % level.duration
	if level.victory.mode == VictoryConfig.DEFEAT_ELITE:
		return "击败%s" % level.elite.display_name
	return "击败%s并坚持 %d 秒" % [level.elite.display_name, level.duration]


func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
