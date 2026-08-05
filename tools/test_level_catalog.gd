extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const LevelBalance = preload("res://scripts/levels/level_balance.gd")
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")

var failed := false


func _initialize() -> void:
	var levels := LevelCatalog.all()
	_require(not levels.is_empty(), "战役清单不能没有关卡")
	_require(levels == LevelCatalog.manifest().levels, "关卡目录没有以战役清单为单一数据源")
	var errors := LevelCatalog.validation_errors()
	_require(errors.is_empty(), "战役配置校验失败：%s" % "；".join(errors))
	for index in range(levels.size()):
		_validate_level(levels[index], index, levels)
	_test_pressure_formula()
	_test_ability_pressure()
	_test_rest_duration()
	if not failed:
		print("LEVELS_OK count=%d manifest=true pressure_curve=true rewards=configured" % levels.size())
	quit(1 if failed else 0)


func _validate_level(level: LevelConfig, index: int, levels: Array[LevelConfig]) -> void:
	_require(level.order == index + 1, "战役清单关卡顺序不连续")
	_require(level.stage_index_at(0.0) == 0, "%s 首阶段索引错误" % level.level_id)
	_require(level.stage_index_at(level.duration - 0.01) == level.stages.size() - 1, "%s 末阶段索引错误" % level.level_id)
	_require(level.map.depth_index(level.map.world_bounds.position.y) == 1, "%s 地图顶部深度错误" % level.level_id)
	_require(level.map.depth_index(level.map.world_bounds.end.y) == 3800, "%s 地图底部深度错误" % level.level_id)
	_require(level.equipment_drop_table.min_drops >= 1 and level.equipment_drop_table.max_drops <= 4, "%s 胜利掉落数量越界" % level.level_id)
	_require(level.reward.first_clear_equipment_reward != null, "%s 缺少首通固定奖励" % level.level_id)
	if not level.reward.unlock_level_id.is_empty():
		var unlocked := LevelCatalog.by_id(level.reward.unlock_level_id)
		_require(unlocked != null and unlocked.order > level.order, "%s 解锁关系没有指向后续关卡" % level.level_id)
	for other_index in range(index):
		var other := levels[other_index]
		_require(level != other and level.map != other.map and level.difficulty != other.difficulty, "%s 与其他关卡共享核心资源" % level.level_id)
		_require(level.loot != other.loot and level.reward != other.reward and level.equipment_drop_table != other.equipment_drop_table, "%s 与其他关卡共享规则资源" % level.level_id)
	var previous_pressure := 0.0
	for stage_index in range(level.stages.size()):
		var pressure := LevelBalance.stage_pressure(level, stage_index)
		if stage_index > 0:
			_require(pressure >= previous_pressure * 1.15, "%s 相邻阶段压力增长低于 15%%" % level.level_id)
		previous_pressure = pressure


func _test_pressure_formula() -> void:
	var level := _synthetic_level(10.0)
	level.stages = [_synthetic_stage(0.0, 0.0, {"slime": 0.5, "brute": 0.5})]
	var slime := EnemyCatalog.enemy("slime")
	var brute := EnemyCatalog.enemy("brute")
	var reference_speed: float = slime["speed"]
	var expected_threat: float = 0.5 * slime["health"] * slime["damage"]
	expected_threat += 0.5 * brute["health"] * brute["damage"] * brute["speed"] / reference_speed
	var expected := 1.2 / 0.8 * expected_threat
	_require(is_equal_approx(LevelBalance.stage_pressure(level, 0), expected), "压力公式没有按怪物编成权重计算")


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
	stage.entry_for("green_grub").ability_variant_id = "green_grub_roll"
	_require(is_equal_approx(LevelBalance.stage_pressure(level, 0), base * 1.10), "怪物技能变体威胁没有计入压力")
	_require(is_equal_approx(EnemyAbilityCatalog.threat_multiplier(""), 1.0), "无技能怪物仍有技能威胁倍率")


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
	stage.transition_rest_duration = rest_duration
	for enemy_id in weights:
		var entry := EnemySpawnEntryConfig.new()
		entry.enemy_id = enemy_id
		entry.weight = float(weights[enemy_id])
		stage.enemy_entries.append(entry)
	return stage


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("LEVELS_FAILED: " + message)
