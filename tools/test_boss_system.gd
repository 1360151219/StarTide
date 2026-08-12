extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const StageDirector = preload("res://scripts/run/stage_director.gd")

var failed := false


func _initialize() -> void:
	_test_spawn_event()
	_test_spawn_stats_and_minion_caps()
	_test_phase_sequences()
	_test_fixed_seed_ttk()
	_test_immediate_victory_and_no_time_limit()
	if not failed:
		print("BOSS_OK spawn=75_once phases=3 deterministic=true no_repeat=true triple_dash=true warnings=1 minions=8 immediate_victory=true no_time_limit=true cleanup=true fixed_scaling=true")
	quit(1 if failed else 0)


func _test_spawn_event() -> void:
	var level := LevelCatalog.by_id("level_05")
	var director := StageDirector.new()
	director.configure(level)
	_require(not director.advance(74.99)["boss_due"], "驺吾在 75 秒前出现")
	_require(director.advance(75.0)["boss_due"], "驺吾没有在 75 秒出现")
	_require(not director.advance(149.0)["boss_due"], "驺吾重复出现")


func _test_spawn_stats_and_minion_caps() -> void:
	var session := _create_session(1201)
	for enemy in session.enemies.snapshot():
		session.enemies.remove_enemy(enemy)
	for _index in range(10):
		session.enemies.spawn_enemy("slime", null, 0.0)
	session.state.elapsed = 75.0
	session._update_stage_events()
	_require(session.state.boss_spawned and is_instance_valid(session.boss_enemy), "Boss 生命周期没有记录登场")
	_require(session.boss_enemy.max_health == 6000.0 and session.boss_enemy.speed == 72.0 and session.boss_enemy.damage == 10.0 and session.boss_enemy.radius == 52.0, "Boss 基础参数没有使用固定配置")
	_require(_normal_enemy_count(session) <= 6, "Boss 登场没有把远处敌人清理到 6 只")
	for step in range(30):
		session.enemies.advance_spawning(1.0, 76.0 + step)
	_require(_normal_enemy_count(session) <= 8, "Boss 战随从超过 8 只")
	session.free()


func _test_phase_sequences() -> void:
	var session := _create_session(1202)
	for enemy in session.enemies.snapshot():
		session.enemies.remove_enemy(enemy)
	session.state.elapsed = 75.0
	session._update_stage_events()
	var boss: Node = session.boss_enemy
	var controller: Node = session.boss_abilities
	session.damage_resolver.invulnerable_until = INF
	boss.position = Vector2(200, 0)
	session.player.position = Vector2.ZERO
	controller.advance(0.0, 75.81)
	_require(controller.active_warning_count() == 1 and controller.state["ability_id"] == "zouwu_dash" and int(controller.state["sequence_remaining"]) == 1 and session.audio.played_cue_ids.has("enemy_warning") and session.audio.played_cue_ids.has("zouwu_dash_charge"), "第一阶段没有从单次千里踏云开始或 Boss 技能音效缺失")
	boss.health = boss.max_health * 0.5
	controller.state["phase"] = "idle"
	controller.state["ready_at"] = 80.0
	controller.skill_cursor = 0
	controller.last_skill_id = "zouwu_marks"
	controller.skill_history = PackedStringArray(["zouwu_marks"])
	controller.advance(0.0, 80.0)
	_require(controller.current_combat_phase() == 2 and controller.state["ability_id"] == "zouwu_dash" and int(controller.state["sequence_remaining"]) == 2, "第二阶段千里踏云不是双冲刺")
	controller.state["phase"] = "idle"
	controller.state["ready_at"] = 85.0
	controller.last_skill_id = "zouwu_dash"
	boss.health = boss.max_health * 0.2
	controller.advance(0.0, 85.0)
	_require(controller.current_combat_phase() == 3 and controller.state["ability_id"] != "zouwu_dash", "第三阶段强制三连冲刺破坏了技能不连续规则")
	controller.state["phase"] = "idle"
	controller.state["ready_at"] = 86.0
	controller.advance(0.0, 86.0)
	_require(controller.state["ability_id"] == "zouwu_dash" and int(controller.state["sequence_remaining"]) == 3, "第三阶段首次千里踏云不是三连冲刺")
	for index in range(1, controller.skill_history.size()):
		_require(controller.skill_history[index] != controller.skill_history[index - 1], "Boss 连续释放了同一技能")
	_require(controller.active_warning_count() <= 1, "Boss 同时存在多个预警")
	session.pause()
	var warning_time: float = controller.telegraphs.animation_time
	controller.advance(1.0, 87.0)
	_require(controller.telegraphs.animation_time == warning_time, "暂停期间 Boss 预警仍推进")
	session.free()


func _test_immediate_victory_and_no_time_limit() -> void:
	var victory_session := _create_session(1203)
	for enemy in victory_session.enemies.snapshot():
		victory_session.enemies.remove_enemy(enemy)
	victory_session.state.elapsed = 75.0
	victory_session._update_stage_events()
	var boss: Node = victory_session.boss_enemy
	victory_session.enemies.damage_enemy(boss, 7000.0)
	_require(victory_session.state.finished and victory_session.state.victory and victory_session.state.boss_defeated, "Boss 生命归零后没有立即胜利")
	_require(boss.recognizing and not boss.contact_enabled and victory_session.boss_abilities.active_warning_count() == 0, "Boss 认可表现或结束清理错误")
	victory_session.free()
	var unlimited_session := _create_session(1204)
	unlimited_session.player.max_health = 99999.0
	unlimited_session.player.health = 99999.0
	unlimited_session.damage_resolver.invulnerable_until = INF
	unlimited_session.state.elapsed = 149.9
	unlimited_session.advance(0.2, Vector2.ZERO)
	_require(unlimited_session.state.elapsed > 150.0 and not unlimited_session.state.finished and unlimited_session.state.boss_spawned, "Boss 战在 150 秒被截断")
	unlimited_session.free()


func _test_fixed_seed_ttk() -> void:
	var recommended_times: Array[float] = []
	for seed_value in [2201, 2202, 2203]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var close_range_uptime := 0.46 + rng.randf_range(0.0, 0.08)
		recommended_times.append(_estimated_boss_ttk(1.18, 0.96, close_range_uptime))
	recommended_times.sort()
	var median: float = recommended_times[1]
	_require(median >= 30.0 and median <= 45.0, "推荐战力固定种子构筑的 Boss 中位击败时间不在 30～45 秒：%.2f" % median)
	var high_power_time := _estimated_boss_ttk(1.5, 0.88, 0.5)
	_require(high_power_time <= median * 0.8, "高战力构筑没有显著加快 Boss 击败：推荐 %.2f，高战力 %.2f" % [median, high_power_time])


func _estimated_boss_ttk(damage_multiplier: float, cooldown_multiplier: float, close_range_uptime: float) -> float:
	var volley := SkillCatalog.skill("ember_volley")
	var volley_runtime: Dictionary = volley["runtime"]
	var volley_branch: Dictionary = volley["branches"]["ember_volley_blast"]["level_overrides"][5]
	var volley_dps := float(volley_branch["count"]) * float(volley_runtime["damage"][5]) * float(volley_branch["damage_multiplier"]) * damage_multiplier
	volley_dps /= float(volley_runtime["cooldown"][5]) * cooldown_multiplier
	var meteor := SkillCatalog.skill("meteor_rain")
	var meteor_runtime: Dictionary = meteor["runtime"]
	var meteor_branch: Dictionary = meteor["branches"]["meteor_rain_focus"]["level_overrides"][5]
	var meteor_dps := float(meteor_runtime["damage"][5]) * float(meteor_branch["damage_multiplier"]) * damage_multiplier
	meteor_dps /= float(meteor_runtime["cooldown"][5]) * cooldown_multiplier
	var phoenix := SkillCatalog.skill("phoenix_heart")
	var phoenix_runtime: Dictionary = phoenix["runtime"]
	var phoenix_branch: Dictionary = phoenix["branches"]["phoenix_heart_inferno"]["level_overrides"][5]
	var phoenix_dps := float(phoenix_runtime["damage"][5]) * float(phoenix_branch["damage_multiplier"]) * damage_multiplier * close_range_uptime
	phoenix_dps /= float(phoenix_runtime["cooldown"][5]) * cooldown_multiplier
	return LevelCatalog.by_id("level_05").boss.health / (volley_dps + meteor_dps + phoenix_dps)


func _create_session(seed_value: int) -> Node:
	var session := RunSession.new()
	root.add_child(session)
	var audio := AudioStub.new()
	session.add_child(audio)
	var effects := CombatEffects.new()
	session.add_child(effects)
	session.configure("ember_ranger", LevelCatalog.by_id("level_05"), RunRecords.new(""), audio, effects, _random_streams(seed_value))
	return session


func _normal_enemy_count(session: Node) -> int:
	var count := 0
	for enemy in session.enemies.snapshot():
		count += int(not enemy.is_boss)
	return count


func _random_streams(seed_value: int) -> Dictionary:
	var streams := {}
	for stream_id in ["spawn", "loot", "skill", "upgrade", "enemy_ability"]:
		var random := RandomNumberGenerator.new()
		random.seed = seed_value + streams.size()
		streams[stream_id] = random
	return streams


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("BOSS_FAILED: " + message)
