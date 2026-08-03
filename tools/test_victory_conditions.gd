extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunResultService = preload("res://scripts/run/run_result_service.gd")
const RunState = preload("res://scripts/run/run_state.gd")

var failed := false


func _initialize() -> void:
	var first := LevelCatalog.by_id("level_01")
	var result_service := RunResultService.new()
	_require(not first.victory.is_victory(89.99, first.duration, false), "第一关提前胜利")
	_require(first.victory.is_victory(90.0, first.duration, false), "第一关生存胜利边界错误")
	_require(first.victory.is_perfect(true) and not first.victory.is_perfect(false), "第一关完美远征条件错误")
	_require(result_service.victory_hint(first) == "坚持 90 秒", "第一关生存目标提示错误")
	var defeated_state := RunState.new()
	defeated_state.elapsed = 15.0
	defeated_state.end_reason = RunState.END_DEFEATED
	_require(result_service._outcome_hint(defeated_state, first) == "坚持 90 秒 · 还差 01:15", "死亡结算没有展示目标与剩余时间")
	defeated_state.end_reason = RunState.END_OBJECTIVE_TIMEOUT
	_require(result_service._outcome_hint(defeated_state, first) == "时间结束 · 目标尚未完成", "目标超时结算语义错误")
	for level_id in ["level_02", "level_03"]:
		var level := LevelCatalog.by_id(level_id)
		_require(not level.victory.is_victory(level.duration, level.duration, false), "%s 未击败精英却胜利" % level.display_name)
		_require(level.victory.is_timeout_failure(level.duration, level.duration, false), "%s 超时失败未生效" % level.display_name)
		_require(not level.victory.is_victory(level.duration - 0.01, level.duration, true), "%s 击败精英后提前胜利" % level.display_name)
		_require(level.victory.is_victory(level.duration, level.duration, true), "%s 组合胜利条件错误" % level.display_name)
		_require(result_service.victory_hint(level).contains(level.elite.display_name) and result_service.victory_hint(level).contains("%d 秒" % level.duration), "%s 组合目标提示错误" % level.display_name)
	_test_defeat_elite_mode()
	if not failed:
		print("VICTORY_OK survive=true elite=true combined=true timeout=true hints=true boundaries=true")
	quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("VICTORY_FAILED: " + message)


func _test_defeat_elite_mode() -> void:
	var victory := VictoryConfig.new()
	victory.mode = VictoryConfig.DEFEAT_ELITE
	_require(not victory.is_victory(20.0, 60.0, false), "纯精英模式未击败精英却胜利")
	_require(victory.is_victory(20.0, 60.0, true), "纯精英模式击败后没有立即胜利")
	var level := LevelConfig.new()
	level.duration = 60.0
	level.victory = victory
	level.elite = EliteConfig.new()
	level.elite.display_name = "测试精英"
	_require(RunResultService.new().victory_hint(level) == "击败测试精英", "纯精英模式目标提示错误")
