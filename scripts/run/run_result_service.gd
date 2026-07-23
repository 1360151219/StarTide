extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const BuildSummary = preload("res://scripts/run/build_summary.gd")


func finalize(records: RefCounted, state: RefCounted, level: LevelConfig, passives: RefCounted, build_state: RefCounted) -> Dictionary:
	var result: Dictionary = records.record_level_run(
		state.hero_id, state.level_id, state.victory, state.elite_defeated,
		state.kills, state.player_level, state.elapsed, level.reward
	)
	var discoveries: Array[Dictionary] = records.new_content_discoveries()
	return {
		"heading": _heading(state, level),
		"body": _body(state, level, passives, result),
		"reward_text": _reward_text(level, result, state.victory, discoveries.size()),
		"build_text": BuildSummary.text(build_state),
		"won": state.victory,
		"hero_id": state.hero_id,
		"level_id": state.level_id,
		"progression_reward": result["progression_reward"],
		"discoveries": discoveries,
	}


func _heading(state: RefCounted, level: LevelConfig) -> String:
	if not state.victory:
		return level.victory.failure_heading
	if level.victory.is_perfect(state.elite_defeated):
		return level.victory.perfect_heading
	return level.victory.normal_heading


func _body(state: RefCounted, level: LevelConfig, passives: RefCounted, result: Dictionary) -> String:
	var hero_name: String = HeroCatalog.hero(state.hero_id)["name"]
	var outcome := "挑战成功" if state.victory else "挑战失败"
	var record_line := "新纪录" if result["new_record"] else "个人最佳 · 击败 %d" % result["record"]["best_kills"]
	return "%s · %s\n%s · %s\n用时 %s · 击败 %d · 等级 %d\n精英 %s\n%s\n%s" % [
		level.display_name, hero_name, outcome, victory_hint(level), _format_time(state.elapsed),
		state.kills, state.player_level, "已击败" if state.elite_defeated else "未击败",
		passives.result_text(), record_line,
	]


func _reward_text(level: LevelConfig, result: Dictionary, won: bool, discovery_count: int) -> String:
	var progression: Dictionary = result["progression_reward"]
	var growth_line := "英雄熟练度 +%d · 当前 Lv.%d" % [progression["mastery_xp_gained"], progression["level"]]
	if progression["levels_gained"] > 0:
		growth_line += " · 技能点 +%d" % progression["skill_points_gained"]
	if discovery_count > 0:
		growth_line += "\n本局新发现 %d 项 · 已加入图鉴" % discovery_count
	if not won:
		return "本次未获得关卡通关奖励\n" + growth_line
	if result["first_clear"]:
		return "首次通关 · %s\n%s\n%s" % [level.reward.display_name, level.reward.description, growth_line]
	return "重复通关 · 永久奖励已领取\n" + growth_line


func victory_hint(level: LevelConfig) -> String:
	if level.victory.mode == VictoryConfig.SURVIVE_DURATION:
		return "坚持 %d 秒" % level.duration
	if level.victory.mode == VictoryConfig.DEFEAT_ELITE:
		return "击败%s" % level.elite.display_name
	return "击败%s并坚持 %d 秒" % [level.elite.display_name, level.duration]


func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
