extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")
const PlayerHitData = preload("res://scripts/combat/player_hit.gd")
const FeedbackDirectionContract = preload("res://tools/support/combat_feedback_direction_contract.gd")
const AbilityRules = preload("res://scripts/systems/enemy_ability_rules.gd")

var failed := false

func _initialize() -> void:
	_test_opening_protection_and_budget()
	_test_grub_roll()
	_test_non_casters_stay_idle()
	_test_bat_lock_and_projectile()
	_test_deterministic_cooldown()
	_test_pause_and_projectile_cap()
	_test_death_and_projectile_lifetime()
	_test_shared_invulnerability_and_shield()
	_test_area_geometry()
	if not failed:
		print("ENEMY_ABILITIES_OK abilities=%d variants=data_driven deterministic=true budgets=true geometry=lane_sector_circle_annular swept=true feedback_direction=true shield=true cleanup=true" % EnemyAbilityCatalog.ids().size())
	quit(1 if failed else 0)


func _test_opening_protection_and_budget() -> void:
	var session := _create_session("level_01", "ember_ranger", 101)
	var enemies: Array[Node] = []
	for existing in session.enemies.snapshot():
		session.enemies.remove_enemy(existing)
	for index in range(4):
		var enemy: Node = session.enemies.spawn_enemy("green_grub", session.level.elite if index == 0 else null, 0.0)
		enemy.position = Vector2(120 + index * 6, index * 44)
		enemies.append(enemy)
	_prime_visibility(session, 0.0)
	_advance_abilities(session, 0.0, 1.26)
	_require(_phase_count(session, "warning") == 0, "第一关开场保护期仍然启动技能")
	for step in range(4):
		_advance_abilities(session, 0.0, 20.0 + step * 0.35)
	_require(AbilityRules.player_danger_count(session.enemy_abilities.states, session.player.position) <= 2, "同时覆盖玩家的危险区域超过上限")
	_require(_phase_of(session, enemies[0]) == "warning", "精英没有优先获得预留施法名额")
	session.free()


func _test_grub_roll() -> void:
	var session := _create_session("level_03", "ember_ranger", 102)
	var enemy := _spawn_only(session, "green_grub", Vector2(120, 0))
	_prime_and_start(session, enemy)
	_advance_abilities(session, 0.65, 1.91)
	_require(not enemy.contact_enabled and _phase_of(session, enemy) == "executing", "团团滚执行期间没有关闭接触伤害")
	var before: float = session.player.health
	_advance_abilities(session, 0.6, 2.51)
	_require(session.player.health < before, "团团滚穿过玩家时没有造成伤害")
	_require(enemy.contact_enabled and enemy.position.distance_to(Vector2(20, 0)) < 0.1, "团团滚距离或后摇切换错误：pos=%s phase=%s" % [enemy.position, _phase_of(session, enemy)])
	_require(session.audio.played_cue_ids.size() == 1 and session.audio.played_cue_ids[0] == "hero_hurt", "普通怪物技能仍播放音效：%s" % [session.audio.played_cue_ids])
	session.free()


func _test_non_casters_stay_idle() -> void:
	var session := _create_session("level_03", "ember_ranger", 103)
	for existing in session.enemies.snapshot():
		session.enemies.remove_enemy(existing)
	var slime: Node = session.enemies.spawn_enemy("slime", null, 0.0)
	var brute: Node = session.enemies.spawn_enemy("brute", null, 0.0)
	slime.position = Vector2(100, 0)
	brute.position = Vector2(140, 0)
	_prime_visibility(session, 0.0)
	_advance_abilities(session, 0.0, 10.0)
	_require(_phase_of(session, slime) == "idle" and slime.contact_enabled, "星蚀史莱姆仍然进入了技能状态")
	_require(_phase_of(session, brute) == "idle" and brute.contact_enabled, "陨岩巨怪仍然进入了技能状态")
	_require(session.enemy_projectiles.projectiles.is_empty(), "无技能怪物错误生成了敌方弹体")
	session.free()

func _test_bat_lock_and_projectile() -> void:
	var session := _create_session("level_03", "ember_ranger", 104)
	var enemy := _spawn_only(session, "bat", Vector2(250, 0))
	EnemyAbilityCatalog.ABILITIES["test_bolt_variant"] = EnemyAbilityCatalog.ability("bat_bolt").duplicate(true)
	enemy.ability_id = "test_bolt_variant"
	_prime_and_start(session, enemy)
	session.player.position = Vector2(0, 80)
	_advance_abilities(session, 0.6, 1.86)
	var locked_direction: Vector2 = session.enemy_abilities.states[enemy.get_instance_id()]["direction"]
	session.player.position = Vector2(0, -80)
	_advance_abilities(session, 0.31, 2.17)
	_require(session.enemy_projectiles.projectiles.size() == 1, "暮翼光弹没有生成敌方弹体")
	var projectile: Node = session.enemy_projectiles.projectiles[0]
	_require(projectile.velocity.normalized().dot(locked_direction) > 0.999, "暮翼光弹最后 0.3 秒没有锁定方向")
	var feedback := FeedbackDirectionContract.watch(session, projectile)
	session.player.position = projectile.position + projectile.velocity.normalized() * 100.0
	session.enemy_projectiles.advance(0.5)
	_require(session.player.health < float(feedback["health"]) and session.enemy_projectiles.projectiles.is_empty() and FeedbackDirectionContract.swept_hit_stays_on_incoming_side(session.player.position, feedback) and FeedbackDirectionContract.enemy_uses_local_source_position(enemy) and session.audio.played_cue_ids.size() == 1 and session.audio.played_cue_ids[0] == "hero_hurt", "高速敌弹命中、来袭侧反馈、普通怪物静音或敌人局部坐标方向错误")
	EnemyAbilityCatalog.ABILITIES.erase("test_bolt_variant")
	session.free()


func _test_deterministic_cooldown() -> void:
	var first := _cooldown_after_roll(205)
	var second := _cooldown_after_roll(205)
	_require(is_equal_approx(first, second), "相同随机种子的技能冷却不一致")


func _cooldown_after_roll(seed_value: int) -> float:
	var session := _create_session("level_03", "ember_ranger", seed_value)
	var enemy := _spawn_only(session, "green_grub", Vector2(120, 0))
	_prime_and_start(session, enemy)
	_advance_abilities(session, 0.65, 1.91)
	_advance_abilities(session, 0.6, 2.51)
	_advance_abilities(session, 0.45, 2.96)
	var cooldown: float = session.enemy_abilities.states[enemy.get_instance_id()]["cooldown_until"]
	session.free()
	return cooldown


func _test_pause_and_projectile_cap() -> void:
	var session := _create_session("level_01", "ember_ranger", 206)
	var bat: Node = _spawn_only(session, "bat", Vector2(180, 0))
	var config: Dictionary = EnemyAbilityCatalog.ability("bat_bolt")
	for _index in range(3):
		session.enemy_projectiles.spawn_bolt(bat, bat.position, Vector2.LEFT, config, 1.0)
	_require(session.enemy_projectiles.projectiles.size() == 2, "敌方弹体没有遵守关卡全局上限")
	var projectile: Node = session.enemy_projectiles.projectiles[0]
	var before: Vector2 = projectile.position
	session.pause()
	session.advance(1.0, Vector2.ZERO)
	_require(projectile.position == before, "暂停期间敌方弹体仍在推进")
	session.free()


func _test_death_and_projectile_lifetime() -> void:
	var session := _create_session("level_03", "ember_ranger", 106)
	var grub := _spawn_only(session, "green_grub", Vector2(120, 0))
	_prime_and_start(session, grub)
	session.enemies.remove_enemy(grub)
	_require(not session.enemy_abilities.states.has(grub.get_instance_id()), "怪物死亡后预警没有立即取消")
	var bat: Node = session.enemies.spawn_enemy("bat", null, 0.0)
	bat.position = Vector2(180, 0)
	var config := EnemyAbilityCatalog.ability("bat_bolt")
	session.enemy_projectiles.spawn_bolt(bat, bat.position, Vector2.LEFT, config, 1.0)
	session.enemies.remove_enemy(bat)
	_require(session.enemy_projectiles.projectiles.size() == 1, "施法者死亡错误清除了已发射弹体")
	session.free()


func _test_shared_invulnerability_and_shield() -> void:
	var shield_session := _create_session("level_02", "star_warden", 107)
	var bat := _spawn_only(shield_session, "bat", Vector2(150, 0))
	var remote_hit := PlayerHitData.create(6.0, bat, PlayerHitData.BAT_BOLT, bat.position)
	var bat_position: Vector2 = bat.position
	shield_session._apply_player_hit(remote_hit)
	_require(shield_session.player.health == shield_session.player.max_health, "星潮结界没有抵挡远程弹")
	_require(bat.position == bat_position, "结界抵挡远程弹时错误击退了施法者")
	shield_session.free()

	var session := _create_session("level_02", "ember_ranger", 108)
	var enemy := _spawn_only(session, "green_grub", Vector2(20, 0))
	var before: float = session.player.health
	var first := PlayerHitData.create(7.0, enemy, PlayerHitData.GRUB_ROLL, enemy.position)
	var second := PlayerHitData.create(6.0, enemy, PlayerHitData.CONTACT, enemy.position)
	session._apply_player_hit(first)
	session._apply_player_hit(second)
	_require(is_equal_approx(session.player.health, before - 7.0), "同帧技能和接触造成了重复伤害")
	session.free()


func _test_area_geometry() -> void:
	var direction := Vector2.RIGHT
	var lane := EnemyAbilityCatalog.ability("zouwu_dash")
	_require(AbilityRules.telegraph_covers_point(Vector2.ZERO, direction, Vector2(520, 35), lane, Vector2.INF, 0.0), "直线预警边界未命中")
	_require(not AbilityRules.telegraph_covers_point(Vector2.ZERO, direction, Vector2(521, 36), lane, Vector2.INF, 0.0), "直线预警边界外错误命中")
	var sector := EnemyAbilityCatalog.ability("cloud_hart_sector")
	var sector_edge := Vector2.from_angle(deg_to_rad(55.0)) * 150.0
	_require(AbilityRules.telegraph_covers_point(Vector2.ZERO, direction, sector_edge, sector, Vector2.INF, 0.0), "扇形预警边界未命中")
	_require(not AbilityRules.telegraph_covers_point(Vector2.ZERO, direction, Vector2.from_angle(deg_to_rad(56.0)) * 151.0, sector, Vector2.INF, 0.0), "扇形预警边界外错误命中")
	var circle := EnemyAbilityCatalog.ability("bellfeather_circle")
	_require(AbilityRules.telegraph_covers_point(Vector2.ZERO, direction, Vector2(170, 70), circle, Vector2(170, 0), 0.0), "圆形预警边界未命中")
	_require(not AbilityRules.telegraph_covers_point(Vector2.ZERO, direction, Vector2(170, 70.1), circle, Vector2(170, 0), 0.0), "圆形预警边界外错误命中")
	var annular := EnemyAbilityCatalog.ability("zouwu_tail")
	_require(AbilityRules.telegraph_covers_point(Vector2.ZERO, direction, Vector2(70, 0), annular, Vector2.INF, 0.0), "环形扇区内边界未命中")
	_require(AbilityRules.telegraph_covers_point(Vector2.ZERO, direction, Vector2.from_angle(deg_to_rad(135.0)) * 230.0, annular, Vector2.INF, 0.0), "环形扇区外弧边界未命中")
	_require(not AbilityRules.telegraph_covers_point(Vector2.ZERO, direction, Vector2.LEFT * 120.0, annular, Vector2.INF, 0.0), "环形扇区 90 度安全缺口错误命中")


func _create_session(level_id: String, hero_id: String, seed_value: int) -> Node:
	var session := RunSession.new()
	root.add_child(session)
	var audio := AudioStub.new()
	session.add_child(audio)
	var effects := CombatEffects.new()
	session.add_child(effects)
	session.configure(hero_id, LevelCatalog.by_id(level_id), RunRecords.new(""), audio, effects, _random_streams(seed_value))
	return session


func _spawn_only(session: Node, enemy_id: String, position: Vector2, elite := false) -> Node:
	for existing in session.enemies.snapshot():
		session.enemies.remove_enemy(existing)
	var enemy: Node
	if elite:
		enemy = session.enemies.spawn_enemy(enemy_id, session.level.elite, 0.0)
	else:
		enemy = session.enemies.spawn_enemy(enemy_id, null, 0.0)
	enemy.position = position
	return enemy


func _prime_and_start(session: Node, enemy: Node) -> void:
	_prime_visibility(session, 0.0)
	_advance_abilities(session, 0.0, 1.26)
	_require(_phase_of(session, enemy) == "warning", "%s 没有进入技能预警" % enemy.kind)


func _prime_visibility(session: Node, elapsed: float) -> void:
	_advance_abilities(session, 0.0, elapsed)


func _advance_abilities(session: Node, delta: float, elapsed: float) -> void:
	session.state.elapsed = elapsed
	session.enemy_abilities.advance(delta, elapsed)


func _phase_of(session: Node, enemy: Node) -> String:
	return session.enemy_abilities.states.get(enemy.get_instance_id(), {}).get("phase", "missing")


func _phase_count(session: Node, phase: String) -> int:
	var count := 0
	for state in session.enemy_abilities.states.values():
		count += int(state["phase"] == phase)
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
	push_error("ENEMY_ABILITIES_FAILED: " + message)
