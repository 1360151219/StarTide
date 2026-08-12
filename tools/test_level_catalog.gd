extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const LevelBalance = preload("res://scripts/levels/level_balance.gd")
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const WAVE_REORDER_BASELINES := {
	"level_01": {"pressure": 782.93, "spawns": 158.643, "experience": 1318.003},
	"level_02": {"pressure": 1170.48, "spawns": 214.295, "experience": 1789.120},
	"level_03": {"pressure": 2545.80, "spawns": 283.473, "experience": 2962.564},
}
const WAVE_REORDER_STARTS := {
	"level_01": [0.0, 20.0, 45.0, 60.0],
	"level_02": [0.0, 22.0, 48.0, 65.0, 70.0],
	"level_03": [0.0, 24.0, 50.0, 65.0, 90.0, 105.0],
}
const CAMPAIGN_EXTENSION_STARTS := {
	"level_04": [0.0, 25.0, 52.0, 72.0, 88.0, 100.0, 118.0],
	"level_05": [0.0, 28.0, 55.0, 70.0, 75.0],
}
const RECOMMENDED_POWERS := [1000, 1100, 1250, 1450, 1650]
const RARITY_WEIGHTS := [
	{"common": 82.0, "rare": 16.0, "top": 2.0},
	{"common": 72.0, "rare": 23.0, "top": 5.0},
	{"common": 62.0, "rare": 28.0, "top": 10.0},
	{"common": 55.0, "rare": 30.0, "top": 15.0},
	{"common": 45.0, "rare": 32.0, "top": 23.0},
]

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
	_test_wave_reorder_budgets()
	_test_campaign_extension(levels)
	if not failed:
		print("LEVELS_OK count=%d manifest=true pressure_curve=true wave_budgets=stable rewards=configured" % levels.size())
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
	if level.order > 3:
		return
	var previous_combat_pressure := 0.0
	var found_respite := false
	for stage_index in range(level.stages.size()):
		var stage := level.stages[stage_index]
		var pressure := LevelBalance.stage_pressure(level, stage_index)
		if stage.stage_id.ends_with("_respite"):
			found_respite = true
			_require(stage_index > 0 and stage_index + 1 < level.stages.size(), "%s 喘息阶段没有位于两轮战斗之间" % level.level_id)
			var previous_pressure := LevelBalance.stage_pressure(level, stage_index - 1)
			var next_pressure := LevelBalance.stage_pressure(level, stage_index + 1)
			_require(pressure <= previous_pressure * 0.75, "%s 喘息阶段压力回落不足" % level.level_id)
			_require(next_pressure >= pressure * 1.5, "%s 喘息后的高潮压力不足" % level.level_id)
			continue
		if previous_combat_pressure > 0.0:
			_require(pressure >= previous_combat_pressure * 1.15, "%s 非喘息阶段压力增长低于 15%%" % level.level_id)
		previous_combat_pressure = pressure
	_require(found_respite, "%s 缺少明确的波次喘息阶段" % level.level_id)


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
	level.enemy_ability_budget.disabled_ability_ids = PackedStringArray(["green_grub_roll"])
	_require(is_equal_approx(LevelBalance.stage_pressure(level, 0), base), "关卡禁用的怪物技能仍然计入压力")
	_require(is_equal_approx(EnemyAbilityCatalog.threat_multiplier(""), 1.0), "无技能怪物仍有技能威胁倍率")


func _test_wave_reorder_budgets() -> void:
	for level_id in WAVE_REORDER_BASELINES:
		var level := LevelCatalog.by_id(level_id)
		var baseline: Dictionary = WAVE_REORDER_BASELINES[level.level_id]
		var stage_starts: Array = []
		for stage in level.stages:
			stage_starts.append(stage.start_time)
		_require(stage_starts == WAVE_REORDER_STARTS[level.level_id], "%s 波次节点没有保持重排方案" % level.level_id)
		_require(_within_ratio(LevelBalance.level_pressure(level), float(baseline["pressure"]), 0.05), "%s 重排后的总压力偏离原版超过 5%%" % level.level_id)
		_require(_within_ratio(LevelBalance.expected_spawn_budget(level), float(baseline["spawns"]), 0.05), "%s 重排后的预期刷怪量偏离原版超过 5%%" % level.level_id)
		_require(_within_ratio(LevelBalance.expected_experience_budget(level), float(baseline["experience"]), 0.05), "%s 重排后的预期经验偏离原版超过 5%%" % level.level_id)


func _test_campaign_extension(levels: Array[LevelConfig]) -> void:
	_require(levels.size() == 5, "战役关卡数量不是 5")
	for index in range(levels.size()):
		_require(levels[index].recommended_power == RECOMMENDED_POWERS[index], "%s 推荐战力错误" % levels[index].level_id)
		_require(levels[index].equipment_drop_table.rarity_weights == RARITY_WEIGHTS[index], "%s 实际品质掉落权重偏离数值契约" % levels[index].level_id)
		if index + 1 < levels.size():
			_require(levels[index].reward.unlock_level_id == levels[index + 1].level_id, "%s 解锁链断裂" % levels[index].level_id)
	var fourth := LevelCatalog.by_id("level_04")
	var fifth := LevelCatalog.by_id("level_05")
	for level in [fourth, fifth]:
		var starts: Array = []
		for stage in level.stages:
			starts.append(stage.start_time)
		_require(starts == CAMPAIGN_EXTENSION_STARTS[level.level_id], "%s 波次节点错误" % level.level_id)
	var pressure_ratio := LevelBalance.level_pressure(fourth) / LevelBalance.level_pressure(LevelCatalog.by_id("level_03"))
	_require(pressure_ratio >= 0.95 and pressure_ratio <= 1.05, "禁用新怪技能后，第四关普通波压力没有贴近第三关：%.3f" % pressure_ratio)
	var fourth_respite_ratio := LevelBalance.stage_pressure(fourth, 3) / LevelBalance.stage_pressure(fourth, 2)
	_require(fourth_respite_ratio >= 0.5 and fourth_respite_ratio <= 0.65, "第四关喘息压力没有接近前一波 60%%：%.3f" % fourth_respite_ratio)
	_require(fourth.elite.spawn_time == 100.0 and fourth.elite.bonus_upgrade_count == 2 and fourth.elite.magnet_duration == 8.0, "第四关精英节点或奖励错误")
	var fifth_respite_ratio := LevelBalance.stage_pressure(fifth, 2) / LevelBalance.stage_pressure(fifth, 1)
	_require(fifth_respite_ratio >= 0.5 and fifth_respite_ratio <= 0.6, "第五关整备压力没有接近前一波 55%%：%.3f" % fifth_respite_ratio)
	_require(not fifth.stages[3].spawning_enabled and fifth.boss.spawn_time(fifth.duration) == 75.0, "第五关停潮或 Boss 时间错误")
	_require(fifth.boss.initial_minion_limit == 6 and fifth.boss.minion_limit == 8, "第五关随从上限错误")


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


func _within_ratio(value: float, baseline: float, tolerance: float) -> bool:
	return absf(value / baseline - 1.0) <= tolerance


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("LEVELS_FAILED: " + message)
