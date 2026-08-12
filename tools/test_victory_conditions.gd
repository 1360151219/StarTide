extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunResultService = preload("res://scripts/run/run_result_service.gd")
const RunState = preload("res://scripts/run/run_state.gd")

var failed := false


func _initialize() -> void:
	var result_service := RunResultService.new()
	for level_id in ["level_01", "level_02", "level_03", "level_04"]:
		var level := LevelCatalog.by_id(level_id)
		_require(level.victory.mode == VictoryConfig.SURVIVE_AND_DEFEAT_ELITE, "%s 未使用统一精英通关条件" % level.display_name)
		_require(not level.victory.is_victory(level.duration, level.duration, false), "%s 未击败精英却胜利" % level.display_name)
		_require(not level.victory.is_victory(level.duration - 0.01, level.duration, true), "%s 击败精英后提前胜利" % level.display_name)
		_require(level.victory.is_victory(level.duration, level.duration, true), "%s 组合胜利条件错误" % level.display_name)
		_require(result_service.victory_hint(level).contains(level.elite.display_name) and result_service.victory_hint(level).contains("%d 秒" % level.duration), "%s 组合目标提示错误" % level.display_name)
	_test_paused_objective_clock(result_service)
	_test_defeat_elite_mode()
	_test_defeat_boss_mode(result_service)
	if not failed:
		print("VICTORY_OK elite_levels=4 boss=true objective_pause=true no_time_limit=true hints=true boundaries=true")
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


func _test_paused_objective_clock(result_service: RefCounted) -> void:
	var level := LevelCatalog.by_id("level_01")
	var state := RunState.new()
	state.elapsed = level.elite.spawn_time
	state.elite_spawned_at = state.elapsed
	state.elapsed += 20.0
	_require(is_equal_approx(state.objective_elapsed(), level.elite.spawn_time), "精英存活时通关计时没有暂停")
	state.elite_defeated = true
	state.elite_defeated_at = state.elapsed
	state.elapsed = level.duration + 19.99
	_require(not level.victory.is_victory(state.objective_elapsed(), level.duration, true), "扣除精英战时间后仍提前胜利")
	state.elapsed = level.duration + 20.0
	_require(level.victory.is_victory(state.objective_elapsed(), level.duration, true), "精英战后通关计时没有继续")
	var defeated_state := RunState.new()
	defeated_state.elapsed = 15.0
	defeated_state.end_reason = RunState.END_DEFEATED
	_require(result_service._outcome_hint(defeated_state, level) == "通关计时 90 秒 · 击败星蚀团子王 · 还差 01:15", "死亡结算没有展示剩余通关计时")


func _test_defeat_boss_mode(result_service: RefCounted) -> void:
	var level := LevelCatalog.by_id("level_05")
	_require(not level.victory.is_victory(9999.0, level.duration, false, false), "Boss 存活时因时间通过")
	_require(level.victory.is_victory(100.0, level.duration, false, true), "击败 Boss 后没有立即胜利")
	_require(result_service.victory_hint(level) == "击败千里巡守·驺吾", "Boss 目标提示错误")
	var defeated_state := RunState.new()
	defeated_state.elapsed = 9999.0
	defeated_state.end_reason = RunState.END_DEFEATED
	_require(result_service._outcome_hint(defeated_state, level) == "千里云庭 · Boss 尚未击败", "Boss 失败结算仍展示时间限制")
