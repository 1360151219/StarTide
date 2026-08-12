extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const StageDirector = preload("res://scripts/run/stage_director.gd")
const EnemySpawner = preload("res://scripts/systems/enemy_spawner.gd")
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")

var failed := false


func _initialize() -> void:
	for level in LevelCatalog.all():
		for index in range(level.stages.size()):
			var director := StageDirector.new()
			director.configure(level)
			director.advance(level.stages[index].start_time)
			var spawner := _spawner(level, director, level.order * 997 + index)
			_require(director.current_stage() == level.stages[index], "%s 没有通过阶段导演进入目标阶段" % level.display_name)
			_test_stage_weights(level, index, spawner)
			_test_ranged_cap(level, index, spawner)
			_test_per_enemy_caps(level, index, spawner)
			var stage := level.stages[index]
			_require(is_equal_approx(stage.spawn_interval_at(stage.start_time, level.stage_end_time(index)), stage.spawn_interval_start), "%s 阶段起始间隔错误" % stage.display_name)
			_require(is_equal_approx(stage.spawn_interval_at(level.stage_end_time(index), level.stage_end_time(index)), stage.spawn_interval_end), "%s 阶段结束间隔错误" % stage.display_name)
		var initial_director := StageDirector.new()
		initial_director.configure(level)
		_test_spawn_positions(level, _spawner(level, initial_director, level.order * 1997))
		_test_expanded_viewport_clearance(level, _spawner(level, initial_director, level.order * 2997))
		_test_determinism(level)
	_test_spawn_timing()
	_test_first_level_opening_budget()
	if not failed:
		print("SPAWNER_OK levels=%d weights=true per_enemy_caps=true ranged_cap=true deterministic=true" % LevelCatalog.all().size())
	quit(1 if failed else 0)


func _test_stage_weights(level: LevelConfig, index: int, spawner: RefCounted) -> void:
	if not level.stages[index].spawning_enabled:
		_require(spawner.roll_enemy_id().is_empty(), "%s 停刷阶段仍会产生怪物" % level.stages[index].display_name)
		return
	var counts := {}
	for enemy_id in EnemyCatalog.ids():
		counts[enemy_id] = 0
	var samples := 5000
	for _sample in range(samples):
		counts[spawner.roll_enemy_id()] += 1
	for enemy_id in counts:
		var actual: float = float(counts[enemy_id]) / samples
		var expected: float = level.stages[index].enemy_weight(enemy_id)
		_require(absf(actual - expected) <= 0.035, "%s 的 %s 权重偏差过大" % [level.stages[index].display_name, enemy_id])


func _test_ranged_cap(level: LevelConfig, index: int, spawner: RefCounted) -> void:
	var stage: StageConfig = level.stages[index]
	var has_ranged_weight := false
	for entry in stage.enemy_entries:
		has_ranged_weight = has_ranged_weight or EnemyCatalog.is_ranged(entry.enemy_id)
	if not has_ranged_weight:
		return
	var saw_ranged_below_cap := false
	for _sample in range(512):
		var available_id: String = spawner.roll_enemy_id({}, maxi(0, level.max_ranged_enemies - 1))
		saw_ranged_below_cap = saw_ranged_below_cap or EnemyCatalog.is_ranged(available_id)
		var capped_id: String = spawner.roll_enemy_id({}, level.max_ranged_enemies)
		_require(not capped_id.is_empty() and not EnemyCatalog.is_ranged(capped_id), "%s 达到远程上限后仍刷新远程怪" % stage.display_name)
	_require(saw_ranged_below_cap, "%s 在远程上限前无法刷新远程怪" % stage.display_name)


func _test_per_enemy_caps(level: LevelConfig, index: int, spawner: RefCounted) -> void:
	var stage: StageConfig = level.stages[index]
	for entry in stage.enemy_entries:
		if entry.max_active <= 0:
			continue
		var active_counts := {entry.enemy_id: entry.max_active}
		for _sample in range(64):
			var rolled_id: String = spawner.roll_enemy_id(active_counts, 0)
			_require(rolled_id != entry.enemy_id, "%s 达到 %s 独立上限后仍继续刷新" % [stage.display_name, entry.enemy_id])


func _test_spawn_positions(level: LevelConfig, spawner: RefCounted) -> void:
	var bounds := level.map.world_bounds
	var players := [
		bounds.get_center(),
		bounds.position + Vector2(24.0, 24.0),
		Vector2(bounds.end.x - 24.0, bounds.position.y + 24.0),
		bounds.end - Vector2(24.0, 24.0),
		Vector2(bounds.position.x + 24.0, bounds.end.y - 24.0),
	]
	var valid_bounds := bounds.grow(-30.0)
	for elite in [false, true]:
		var minimum: float = level.map.elite_spawn_distance_min if elite else level.map.spawn_distance_min
		var maximum: float = level.map.elite_spawn_distance_max if elite else level.map.spawn_distance_max
		for player_position in players:
			for _sample in range(24):
				var position: Vector2 = spawner.spawn_position(player_position, elite)
				var distance := position.distance_to(player_position)
				_require(valid_bounds.has_point(position), "%s 的刷怪点越过地图安全边界" % level.display_name)
				_require(distance >= minimum - 0.01 and distance <= maximum + 0.01, "%s 的刷怪距离越界：%.2f" % [level.display_name, distance])


func _test_determinism(level: LevelConfig) -> void:
	var first_director := StageDirector.new()
	var second_director := StageDirector.new()
	first_director.configure(level)
	second_director.configure(level)
	var first := _spawner(level, first_director, level.order * 7919)
	var second := _spawner(level, second_director, level.order * 7919)
	for _sample in range(64):
		_require(first.roll_enemy_id() == second.roll_enemy_id(), "%s 同种子怪物序列不一致" % level.display_name)
		_require(first.spawn_position(Vector2.ZERO) == second.spawn_position(Vector2.ZERO), "%s 同种子位置序列不一致" % level.display_name)


func _test_expanded_viewport_clearance(level: LevelConfig, spawner: RefCounted) -> void:
	var viewport_size := Vector2(540.0, 1200.0)
	var minimum := viewport_size.length() * 0.5 + 48.0
	var valid_bounds := level.map.world_bounds.grow(-30.0)
	for elite in [false, true]:
		for _sample in range(32):
			var position: Vector2 = spawner.spawn_position(level.map.player_start, elite, viewport_size)
			_require(valid_bounds.has_point(position), "%s 的全面屏刷怪点越过地图边界" % level.display_name)
			_require(position.distance_to(level.map.player_start) >= minimum - 0.01, "%s 的怪物会直接生成在全面屏可见范围内" % level.display_name)


func _test_spawn_timing() -> void:
	var level := LevelCatalog.first()
	var director := StageDirector.new()
	director.configure(level)
	var spawner := _spawner(level, director, 41)
	_require(spawner.next_spawn_count(0.29, 0.29, 0) == 0, "初始 0.3 秒计时器提前刷新")
	_require(spawner.next_spawn_count(0.02, 0.31, 0) == 1, "初始计时器到点没有刷新")
	_require(spawner.next_spawn_count(10.0, 0.31, level.max_enemies) == 0, "达到怪物上限后仍然刷新")
	var transition_time: float = level.stages[1].start_time
	director.advance(transition_time)
	_require(spawner.next_spawn_count(10.0, transition_time, 0) == 0, "阶段喘息期间仍然刷新")
	_require(spawner.next_spawn_count(10.0, director.spawn_rest_until, 0) >= 1, "阶段喘息结束后没有恢复刷新")
	var synthetic := LevelConfig.new()
	synthetic.duration = 10.0
	synthetic.max_enemies = 10
	var guaranteed_extra := StageConfig.new()
	guaranteed_extra.spawn_interval_start = 1.0
	guaranteed_extra.spawn_interval_end = 1.0
	guaranteed_extra.extra_spawn_chance = 1.0
	var slime_entry := EnemySpawnEntryConfig.new()
	slime_entry.enemy_id = "slime"
	guaranteed_extra.enemy_entries = [slime_entry]
	synthetic.stages = [guaranteed_extra]
	var synthetic_director := StageDirector.new()
	synthetic_director.configure(synthetic)
	var extra_spawner := _spawner(synthetic, synthetic_director, 42)
	extra_spawner.spawn_timer = 0.0
	_require(extra_spawner.next_spawn_count(0.0, 0.0, 0) == 2, "100%% 额外刷新没有生成两只怪物")


func _test_first_level_opening_budget() -> void:
	var level := LevelCatalog.first()
	var stage := level.stages[0]
	_require(level.initial_enemy_count == 3, "第一关新手阶段初始怪物数回退")
	_require(is_equal_approx(stage.spawn_interval_start, 1.3) and is_equal_approx(stage.spawn_interval_end, 1.05), "第一关新手阶段刷新曲线回退")
	var director := StageDirector.new()
	director.configure(level)
	var spawner := _spawner(level, director, 119)
	var count := level.initial_enemy_count
	var elapsed := 0.0
	while elapsed < 17.0:
		var delta := minf(1.0 / 60.0, 17.0 - elapsed)
		elapsed += delta
		count += spawner.next_spawn_count(delta, elapsed, count)
	_require(count <= 18, "第一关 17 秒怪物生成预算过高：%d" % count)


func _spawner(level: LevelConfig, director: RefCounted, seed_value: int) -> RefCounted:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var spawner := EnemySpawner.new()
	spawner.configure(level, director, rng)
	return spawner


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("SPAWNER_FAILED: " + message)
