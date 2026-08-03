extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")

var failed := false


func _initialize() -> void:
	_test_runtime_pools_and_discovery()
	_test_pickup_effects()
	_test_branch_and_relic_runtime()
	if not failed:
		print("CONTENT_RUNTIME_OK pools=progressive discovery=events replay=cross_level reroll=session pickups=haste+bomb branch=applied relics=runtime")
	quit(1 if failed else 0)


func _test_runtime_pools_and_discovery() -> void:
	var records := RunRecords.new("")
	var session := _create_session("level_01", records, 810)
	_require(Array(session.skill_pool_ids) == ["star_lance"], "第一关没有只开放所选英雄签名技能")
	_require(session.relic_pool_ids.size() == 2, "第一关遗物引入池数量错误")
	_require(records.is_content_discovered("skills", "star_lance"), "签名技能没有在出征时发现")
	_require(not records.is_content_discovered("enemies", "bat") and not records.is_content_discovered("enemies", "brute"), "第一关提前发现后续怪物")
	session.add_experience(36)
	var first_offer := str(session.build_state.last_offer_key)
	_require(session.reroll_upgrade(), "会话层免费重抽失败")
	_require(session.build_state.rerolls_remaining == 0 and str(session.build_state.last_offer_key) != first_offer, "重抽次数或候选去重错误")
	session.free()
	session = _session_with_choice("level_01", records, "skill_branch", 840)
	_require(session != null, "随机候选池无法生成技能分支")
	if session == null:
		return
	var branch_choice := _choice_of_kind(session, "skill_branch")
	_require(not branch_choice.is_empty() and session.select_upgrade(branch_choice["choice_key"]), "技能分支无法通过会话应用")
	_require(session.build_state.skill_levels["star_lance"] == 2, "技能分支没有提升到 II 级")
	_require(records.is_content_discovered("skill_branches", branch_choice["branch_id"]), "实际选择技能分支后没有解锁分支图鉴")
	session.add_experience(session.state.experience_needed)
	var relic_choice := _choice_of_kind(session, "relic_upgrade")
	_require(not relic_choice.is_empty() and session.select_upgrade(relic_choice["choice_key"]), "遗物无法通过会话应用")
	_require(records.is_content_discovered("relics", relic_choice["content_id"]), "实际获得遗物后没有解锁图鉴")
	session.free()

	records.discover_content("skills", "frost_tide")
	records.discover_content("relics", "echo_lens")
	var replay := _create_session("level_01", records, 811)
	_require(replay.skill_pool_ids.has("frost_tide"), "已发现技能不能带回早期关卡")
	_require(replay.relic_pool_ids.has("echo_lens"), "已发现遗物不能带回早期关卡")
	_require(not LevelCatalog.level_content_ids("level_01", "enemies").has("bat"), "玩家发现状态污染了第一关怪物生态")
	replay.free()


func _test_pickup_effects() -> void:
	var records := RunRecords.new("")
	var haste_session := _create_session("level_02", records, 820)
	var base_speed: float = haste_session.player.speed
	haste_session.pickups.spawn_pickup("haste_leaf", haste_session.player.position, 1)
	haste_session.pickups.advance(0.0, 0.0)
	_require(is_equal_approx(haste_session.player.speed, base_speed * 1.2), "疾风叶没有提供 20% 移速")
	_require(records.is_content_discovered("pickups", "haste_leaf"), "拾取疾风叶后没有解锁图鉴")
	haste_session.pickups.advance(0.0, 6.01)
	_require(is_equal_approx(haste_session.player.speed, base_speed), "疾风叶持续时间结束后移速没有恢复")
	haste_session.free()

	var bomb_session := _create_session("level_03", records, 821)
	var enemy: Node = bomb_session.enemies.enemies[0]
	for other in bomb_session.enemies.snapshot():
		if other != enemy:
			bomb_session.enemies.remove_enemy(other)
	enemy.position = bomb_session.player.position
	enemy.max_health = 999.0
	enemy.health = 999.0
	bomb_session.pickups.spawn_pickup("star_bomb", bomb_session.player.position, 1)
	bomb_session.pickups.advance(0.0, 0.0)
	_require(is_equal_approx(enemy.health, 964.0), "星爆糖没有造成 35 点范围伤害")
	_require(records.is_content_discovered("pickups", "star_bomb"), "拾取星爆糖后没有解锁图鉴")
	bomb_session.free()

	var bell_session := _create_session("level_03", records, 822)
	_require(bell_session.build_state.add_or_upgrade_relic("star_bell"), "星引铃无法加入构筑")
	var distant_pickup: Node = bell_session.pickups.spawn_pickup("xp", bell_session.player.position + Vector2(110, 0), 1)
	bell_session.pickups.advance(0.1, 0.0)
	_require(distant_pickup.position.distance_to(bell_session.player.position) < 110.0, "星引铃没有扩大普通拾取范围")
	bell_session.free()


func _test_branch_and_relic_runtime() -> void:
	var session := _create_session("level_03", RunRecords.new(""), 830)
	_require(session.build_state.select_branch("star_lance", "star_lance_fan"), "测试分支无法选择")
	_require(session.build_state.upgrade_skill("star_lance"), "测试分支无法升级到终极")
	for relic_id in ["energy_prism", "time_gear", "flow_feather"]:
		_require(session.build_state.add_or_upgrade_relic(relic_id), "测试遗物无法加入构筑：" + relic_id)
	session.player.apply_build_modifiers(session.build_state)
	session.skills.sync_after_upgrade("star_lance")
	var enemy: Node = session.enemies.enemies[0]
	for other in session.enemies.snapshot():
		if other != enemy:
			session.enemies.remove_enemy(other)
	enemy.position = session.player.position + Vector2(120, 0)
	session.skills.runtime.bolt_timer = 0.0
	session.skills.advance(0.0, 0.0, 1.0)
	_require(session.projectiles.projectiles.size() == 4, "星雨齐射终极分支没有生成 4 枚星枪")
	var projectile: Node = session.projectiles.projectiles[0]
	_require(is_equal_approx(projectile.damage, 31.0 * 0.74 * 1.07), "技能分支与聚能棱晶伤害没有组合生效")
	_require(is_equal_approx(session.skills.runtime.bolt_timer, 0.88 * 0.95), "时砂齿轮没有作用于技能冷却")
	_require(is_equal_approx(session.player.speed, session.player.base_speed * 1.08), "流光羽没有作用于角色移速")
	session.free()


func _choice_of_kind(session: Node, kind: String) -> Dictionary:
	for choice in session.build_state.pending_choices.values():
		if str(choice["kind"]) == kind:
			return choice
	return {}


func _session_with_choice(level_id: String, records: RefCounted, kind: String, first_seed: int) -> Node:
	for seed_value in range(first_seed, first_seed + 128):
		var session := _create_session(level_id, records, seed_value)
		session.add_experience(36)
		if not _choice_of_kind(session, kind).is_empty():
			return session
		session.free()
	return null


func _create_session(level_id: String, records: RefCounted, seed_value: int) -> Node:
	var session := RunSession.new()
	root.add_child(session)
	var audio := AudioStub.new()
	session.add_child(audio)
	var effects := CombatEffects.new()
	session.add_child(effects)
	session.configure("star_warden", LevelCatalog.by_id(level_id), records, audio, effects, _random_streams(seed_value))
	return session


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
	push_error("CONTENT_RUNTIME_FAILED: " + message)
