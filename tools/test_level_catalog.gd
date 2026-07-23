extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const LevelBalance = preload("res://scripts/levels/level_balance.gd")
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")

var failed := false


func _initialize() -> void:
	var levels := LevelCatalog.all()
	_require(levels.size() == 3, "关卡数量必须为 3")
	if levels.size() != 3:
		quit(1)
		return
	var errors := LevelCatalog.validation_errors()
	_require(errors.is_empty(), "关卡配置校验失败：%s" % "；".join(errors))
	var pressures: Array[float] = []
	var expected := [
		{"id": "level_01", "duration": 90.0, "stages": 3, "victory": VictoryConfig.SURVIVE_DURATION, "elite_time": 60.0},
		{"id": "level_02", "duration": 105.0, "stages": 3, "victory": VictoryConfig.SURVIVE_AND_DEFEAT_ELITE, "elite_time": 70.0},
		{"id": "level_03", "duration": 120.0, "stages": 4, "victory": VictoryConfig.SURVIVE_AND_DEFEAT_ELITE, "elite_time": 90.0},
	]
	for index in range(levels.size()):
		var level := levels[index]
		var target: Dictionary = expected[index]
		_require(level.level_id == target["id"] and level.duration == target["duration"], "第 %d 关 ID 或时长不符合策划基线" % (index + 1))
		_require(level.stages.size() == target["stages"] and level.victory.mode == target["victory"], "%s 阶段数或胜利模式错误" % level.display_name)
		_require(level.elite.spawn_time == target["elite_time"], "%s 精英时间错误" % level.display_name)
		_require(level.order == index + 1, "关卡顺序不连续")
		_require(level.stage_index_at(0.0) == 0, "首阶段索引错误")
		_require(level.stage_index_at(level.duration - 0.01) == level.stages.size() - 1, "末阶段索引错误")
		_require(level.map.depth_index(level.map.world_bounds.position.y) == 1, "%s 地图顶部深度错误" % level.display_name)
		_require(level.map.depth_index(level.map.world_bounds.end.y) == 3800, "%s 地图底部深度错误" % level.display_name)
		for other_index in range(index):
			var other := levels[other_index]
			_require(level != other and level.map != other.map and level.difficulty != other.difficulty, "%s 与其他关卡共享核心配置资源" % level.display_name)
			_require(level.loot != other.loot and level.elite != other.elite and level.victory != other.victory and level.reward != other.reward, "%s 与其他关卡共享规则配置资源" % level.display_name)
		var previous_stage_pressure := 0.0
		for stage_index in range(level.stages.size()):
			var stage_pressure := LevelBalance.stage_pressure(level, stage_index)
			if stage_index > 0:
				_require(stage_pressure >= previous_stage_pressure * 1.15, "%s 的相邻阶段压力增长低于 15%%" % level.display_name)
			previous_stage_pressure = stage_pressure
		var pressure := LevelBalance.level_pressure(level)
		pressures.append(pressure)
	var second_ratio := pressures[1] / pressures[0]
	var third_ratio := pressures[2] / pressures[1]
	_require(second_ratio >= 1.30 and second_ratio <= 1.50, "第二关压力增长不在 30%%～50%% 目标区间：%.3f" % second_ratio)
	_require(third_ratio >= 1.90 and third_ratio <= 2.30, "第三关压力增长不在 90%%～130%% 目标区间：%.3f" % third_ratio)
	_test_pressure_formula()
	_test_ability_pressure()
	_test_rest_duration()
	var first_unlock: String = levels[0].reward.unlock_level_id
	var second_unlock: String = levels[1].reward.unlock_level_id
	_require(first_unlock == levels[1].level_id, "第一关解锁关系错误")
	_require(second_unlock == levels[2].level_id, "第二关解锁关系错误")
	_require(levels[2].reward.unlock_level_id.is_empty(), "第三关不应解锁不存在的关卡")
	if not failed:
		print("LEVELS_OK count=3 validated=true pressure=bounded abilities=weighted rewards=chained")
	quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("LEVELS_FAILED: " + message)


func _test_pressure_formula() -> void:
	var level := _synthetic_level(10.0)
	var stage := _synthetic_stage(0.0, 0.0, {"slime": 0.5, "brute": 0.5})
	level.stages = [stage]
	var slime := EnemyCatalog.enemy("slime")
	var brute := EnemyCatalog.enemy("brute")
	var reference_speed: float = slime["speed"]
	var expected_threat: float = 0.5 * slime["health"] * slime["damage"]
	expected_threat += 0.5 * brute["health"] * brute["damage"] * brute["speed"] / reference_speed
	var expected := 1.2 / 0.8 * expected_threat
	_require(is_equal_approx(LevelBalance.stage_pressure(level, 0), expected), "压力公式没有按单种怪物威胁加权")


func _test_rest_duration() -> void:
	var level := _synthetic_level(20.0)
	var first := _synthetic_stage(0.0, 0.0, {"slime": 1.0})
	var second := _synthetic_stage(10.0, 4.0, {"slime": 1.0})
	level.stages = [first, second]
	var stage_pressure := LevelBalance.stage_pressure(level, 0)
	_require(is_equal_approx(LevelBalance.level_pressure(level), stage_pressure * 0.8), "关卡压力没有扣除阶段喘息时间")


func _test_ability_pressure() -> void:
	var level := _synthetic_level(10.0)
	level.enemy_ability_budget = EnemyAbilityBudgetConfig.new()
	var stage := _synthetic_stage(0.0, 0.0, {"green_grub": 1.0})
	level.stages = [stage]
	var base := LevelBalance.stage_pressure(level, 0)
	stage.enabled_ability_ids = PackedStringArray(["green_grub_roll"])
	_require(is_equal_approx(LevelBalance.stage_pressure(level, 0), base * 1.10), "技能威胁没有按怪物类型计入压力")
	_require(is_equal_approx(EnemyAbilityCatalog.threat_multiplier("slime"), 1.0), "无技能史莱姆仍有技能威胁倍率")
	_require(is_equal_approx(EnemyAbilityCatalog.threat_multiplier("brute"), 1.0), "无技能巨怪仍有技能威胁倍率")


func _synthetic_level(duration: float) -> LevelConfig:
	var level := LevelConfig.new()
	level.duration = duration
	level.difficulty = DifficultyConfig.new()
	level.difficulty.health_end = 1.0
	level.difficulty.speed_end = 1.0
	return level


func _synthetic_stage(start_time: float, rest_duration: float, weights: Dictionary) -> StageConfig:
	var stage := StageConfig.new()
	stage.start_time = start_time
	stage.spawn_interval_start = 0.8
	stage.spawn_interval_end = 0.8
	stage.extra_spawn_chance = 0.2
	stage.enemy_weights = weights
	stage.transition_rest_duration = rest_duration
	return stage
