extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")

var failed := false


func _initialize() -> void:
	var far_lanes := _create_session(701)
	_spawn_ring(far_lanes, "green_grub", 260.0)
	_start_warnings(far_lanes)
	_require(_warning_count(far_lanes) == 4, "未覆盖玩家的预警被危险区预算错误限制")
	far_lanes.free()
	var aimed_lines := _create_session(702)
	_spawn_ring(aimed_lines, "bat", 250.0)
	_start_warnings(aimed_lines)
	_require(_warning_count(aimed_lines) == 2, "覆盖玩家的预警没有遵守危险区上限")
	aimed_lines.free()
	_test_executing_areas_block_warning()
	_test_offscreen_cancel_and_pause_freeze()
	if not failed:
		print("ENEMY_BUDGETS_OK telegraphs=4 player_dangers=2 geometry=aware")
	quit(1 if failed else 0)


func _create_session(seed_value: int) -> Node:
	var session := RunSession.new()
	root.add_child(session)
	var audio := AudioStub.new()
	session.add_child(audio)
	var effects := CombatEffects.new()
	session.add_child(effects)
	session.configure("ember_ranger", LevelCatalog.by_id("level_02"), RunRecords.new(""), audio, effects, _random_streams(seed_value))
	for enemy in session.enemies.snapshot():
		session.enemies.remove_enemy(enemy)
	return session


func _spawn_ring(session: Node, enemy_id: String, distance: float) -> void:
	for index in range(4):
		var enemy: Node = session.enemies.spawn_enemy(enemy_id, null, 0.0)
		enemy.position = Vector2.from_angle(index * TAU / 4.0) * distance


func _test_executing_areas_block_warning() -> void:
	var session := _create_session(703)
	var first: Node = session.enemies.spawn_enemy("slime", null, 0.0)
	var second: Node = session.enemies.spawn_enemy("slime", null, 0.0)
	var bat: Node = session.enemies.spawn_enemy("bat", null, 0.0)
	first.position = Vector2(100, 0)
	second.position = Vector2(0, 100)
	bat.position = Vector2(250, 0)
	session.enemy_abilities.advance(0.0, 0.0)
	for elapsed in [1.26, 1.62, 1.98]:
		session.enemy_abilities.advance(0.0, elapsed)
	session.enemy_abilities.advance(0.8, 2.42)
	var bat_state: Dictionary = session.enemy_abilities.states[bat.get_instance_id()]
	_require(bat_state["phase"] == "idle", "执行中的危险区没有阻止第三个覆盖玩家预警")
	session.free()


func _test_offscreen_cancel_and_pause_freeze() -> void:
	var session := _create_session(704)
	var bat: Node = session.enemies.spawn_enemy("bat", null, 0.0)
	bat.position = Vector2(250, 0)
	session.enemy_abilities.advance(0.0, 0.0)
	session.enemy_abilities.advance(0.0, 1.26)
	session.player.position = Vector2(-1000, 0)
	session.enemy_abilities.advance(0.1, 1.36)
	_require(session.enemy_abilities.states[bat.get_instance_id()]["phase"] == "idle", "怪物离屏后预警没有取消")
	_require(session.enemy_projectiles.projectiles.is_empty(), "离屏取消的预警仍发射了弹体")
	var animation_before: float = session.enemy_abilities.telegraphs.animation_time
	session.pause()
	session.enemy_abilities.advance(1.0, 2.36)
	_require(session.enemy_abilities.telegraphs.animation_time == animation_before, "暂停期间预警动画仍在推进")
	session.free()


func _start_warnings(session: Node) -> void:
	session.enemy_abilities.advance(0.0, 0.0)
	for index in range(4):
		var elapsed := 1.26 + index * 0.36
		session.state.elapsed = elapsed
		session.enemy_abilities.advance(0.0, elapsed)


func _warning_count(session: Node) -> int:
	var count := 0
	for state in session.enemy_abilities.states.values():
		count += int(state["phase"] == "warning")
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
	push_error("ENEMY_BUDGETS_FAILED: " + message)
