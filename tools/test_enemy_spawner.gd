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
			var stage := level.stages[index]
			_require(is_equal_approx(stage.spawn_interval_at(stage.start_time, level.stage_end_time(index)), stage.spawn_interval_start), "%s 阶段起始间隔错误" % stage.display_name)
			_require(is_equal_approx(stage.spawn_interval_at(level.stage_end_time(index), level.stage_end_time(index)), stage.spawn_interval_end), "%s 阶段结束间隔错误" % stage.display_name)
		var initial_director := StageDirector.new()
		initial_director.configure(level)
		_test_spawn_positions(level, _spawner(level, initial_director, level.order * 1997))
		_test_expanded_viewport_clearance(level, _spawner(level, initial_director, level.order * 2997))
		_test_determinism(level)
	_test_spawn_timing()
	if not failed:
		print("SPAWNER_OK levels=3 weights=true intervals=true timing=true rest=true cap=true extra=true distances=true viewport_clearance=true deterministic=true")
	quit(1 if failed else 0)


func _test_stage_weights(level: LevelConfig, index: int, spawner: RefCounted) -> void:
	var counts := {}
	for enemy_id in EnemyCatalog.ids():
		counts[enemy_id] = 0
	var samples := 5000
	for _sample in range(samples):
		counts[spawner.roll_enemy_id()] += 1
	for enemy_id in counts:
		var actual: float = float(counts[enemy_id]) / samples
		var expected: float = level.stages[index].enemy_weights.get(enemy_id, 0.0)
		_require(absf(actual - expected) <= 0.035, "%s 的 %s 权重偏差过大" % [level.stages[index].display_name, enemy_id])


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
	guaranteed_extra.enemy_weights = {"slime": 1.0}
	synthetic.stages = [guaranteed_extra]
	var synthetic_director := StageDirector.new()
	synthetic_director.configure(synthetic)
	var extra_spawner := _spawner(synthetic, synthetic_director, 42)
	extra_spawner.spawn_timer = 0.0
	_require(extra_spawner.next_spawn_count(0.0, 0.0, 0) == 2, "100%% 额外刷新没有生成两只怪物")


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
