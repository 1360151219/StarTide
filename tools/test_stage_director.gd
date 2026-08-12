extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const StageDirector = preload("res://scripts/run/stage_director.gd")

var failed := false


func _initialize() -> void:
	for level in LevelCatalog.all():
		if level.stages.size() < 2:
			_require(false, "%s 至少需要两个阶段完成边界测试" % level.display_name)
			continue
		var director := StageDirector.new()
		director.configure(level)
		_require(director.current_stage() == level.stages[0], "%s 初始阶段错误" % level.display_name)
		var before := director.advance(level.stages[1].start_time - 0.01)
		_require(before["transitions"].is_empty(), "%s 提前切换阶段" % level.display_name)
		var crossed := director.advance(level.duration - 0.01)
		_require(crossed["transitions"].size() == level.stages.size() - 1, "%s 大步长跨阶段遗漏事件" % level.display_name)
		_require(director.stage_index == level.stages.size() - 1, "%s 末阶段错误" % level.display_name)
		var expects_elite := level.elite != null and level.elite.enabled
		var expects_boss := level.boss != null and level.boss.enabled
		_require(bool(crossed["elite_due"]) == expects_elite, "%s 精英事件触发状态错误" % level.display_name)
		_require(bool(crossed["boss_due"]) == expects_boss, "%s Boss 事件触发状态错误" % level.display_name)
		var expects_rest := level.stages[-1].transition_rest_duration > 0.0
		_require(director.is_spawn_resting(level.duration - 0.01) == expects_rest, "%s 跨阶段后的喘息状态错误" % level.display_name)
		_require(not director.is_spawn_resting(director.spawn_rest_until), "%s 喘息结束边界错误" % level.display_name)
		_require(not director.advance(level.duration)["elite_due"], "%s 精英事件重复触发" % level.display_name)
		_require(not director.advance(level.duration)["boss_due"], "%s Boss 事件重复触发" % level.display_name)
	if not failed:
		print("STAGES_OK boundaries=true jumps=true rest=true elite_once=true boss_once=true")
	quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("STAGES_FAILED: " + message)
