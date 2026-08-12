extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")
const PlayerEntity = preload("res://scripts/player.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const TestRandomStreams = preload("res://tools/support/test_random_streams.gd")

var failed := false


func _initialize() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var effects := CombatEffects.new()
	host.add_child(effects)
	_test_star_passive_and_turning(host, effects)
	_test_star_lance(host, effects)
	_test_sun_orbit(host, effects)
	_test_frost_tide(host, effects)
	_test_ember_passive_and_turning(host, effects)
	_test_ember_volley(host, effects)
	_test_meteor_rain(host, effects)
	_test_phoenix_heart(host, effects)
	_test_projectile_resolution(host, effects)
	_test_frame_stops_on_upgrade(host, effects)
	_test_permanent_move_speed()
	host.free()
	if not failed:
		print("HEROES_OK heroes=%d skills=%d isolated=true passives=2 turning=both effects=true slows=stacked projectiles=swept frame_stop=true" % [HeroCatalog.ids().size(), HeroCatalog.SKILLS.size()])
	quit(1 if failed else 0)


func _test_star_passive_and_turning(host: Node2D, effects: Node2D) -> void:
	var session := _create_session(host, effects, "star_warden", 11)
	var enemy = session.enemies.enemies[0]
	_require(session.passives.try_absorb(enemy, 1.0), "星潮结界没有抵挡接触")
	session.player.move(Vector2.LEFT, 0.016)
	_require(session.player.horizontal_facing == -1, "星潮守望者没有向左转身")
	session.player.move(Vector2.RIGHT, 0.016)
	_require(session.player.horizontal_facing == 1, "星潮守望者没有向右转身")
	_test_slow_stack(enemy)
	session.free()


func _test_star_lance(host: Node2D, effects: Node2D) -> void:
	var session := _create_session(host, effects, "star_warden", 12)
	_select_only_skill(session, "star_lance")
	session.skills.runtime.bolt_timer = 0.0
	session.skills.advance(0.0, 0.0, 1.0)
	_require(session.projectiles.projectiles.size() == 3, "星陨万华没有生成三枚星枪")
	_require(session.player.hero_rig.current_state == "cast", "技能真实释放没有触发施法骨骼动画")
	session.free()
func _test_sun_orbit(host: Node2D, effects: Node2D) -> void:
	var session := _create_session(host, effects, "star_warden", 13)
	_select_only_skill(session, "sun_orbit")
	var enemy = _durable_enemy(session, session.player.position + Vector2(92.0, 0.0))
	var health_before: float = enemy.health
	session.skills.runtime.orbit_phase = 0.0
	session.skills.runtime.orbit_hit_timer = 0.0
	session.skills.advance(0.0, 0.0, 1.0)
	_require(enemy.health == health_before - 16.0, "日冕圣环没有造成独立接触伤害")
	session.free()
func _test_frost_tide(host: Node2D, effects: Node2D) -> void:
	var session := _create_session(host, effects, "star_warden", 14)
	_select_only_skill(session, "frost_tide")
	var radius: float = HeroCatalog.skill("frost_tide")["runtime"]["radius"][5]
	var targets: Array[Node] = []
	for index in range(4):
		var enemy: Node = session.enemies.enemies[0] if index == 0 else session.enemies.spawn_enemy("green_grub", null, 0.0)
		targets.append(_durable_enemy(session, session.player.position + Vector2.from_angle(index * TAU / 4.0) * radius * 0.72, enemy))
	session.player.facing = Vector2.RIGHT
	session.skills.runtime.pulse_timer = 0.0
	session.skills.advance(0.0, 0.0, 2.0)
	_require(targets.all(func(enemy: Node) -> bool: return enemy.health == 999.0) and session.skills.runtime.timeline.pending_count("frost_tide") == 4, "时凝星海在波前抵达前提前结算伤害")
	session.skills.advance(0.0, 0.3, 2.3)
	_require(targets.all(func(enemy: Node) -> bool: return enemy.health == 950.0), "时凝星海没有覆盖角色四周的 360 度范围")
	_require(targets.all(func(enemy: Node) -> bool: return is_equal_approx(enemy.slow_factor, 0.28)) and session.skills.runtime.pulse_visual_time > 0.0, "时凝星海减速或视觉没有生效")
	session.free()
func _test_ember_passive_and_turning(host: Node2D, effects: Node2D) -> void:
	var session := _create_session(host, effects, "ember_ranger", 23)
	session.player.position.x = session.level.map.world_bounds.end.x - 24.0
	var blocked_movement: Vector2 = session.player.move(Vector2.RIGHT, 0.91)
	session.passives.advance(blocked_movement, 0.91, 0.91)
	_require(not session.passives.runtime.active, "燎原步可以通过贴墙空跑充能")
	session.player.position = Vector2.ZERO
	var before: float = session.passives.advance(Vector2.RIGHT, 0.89, 0.89)
	var after: float = session.passives.advance(Vector2.RIGHT, 0.02, 0.91)
	_require(is_equal_approx(before, 0.89) and after > 0.02, "燎原步充能或加速错误")
	var enemy = session.enemies.enemies[0]
	enemy.position = Vector2.ZERO
	enemy.advance(Vector2(-100, 0), 0.016, 1.0)
	_require(enemy.horizontal_facing == -1, "怪物没有向左转身")
	enemy.advance(Vector2(100, 0), 0.016, 1.0)
	_require(enemy.horizontal_facing == 1, "怪物没有向右转身")
	session.free()


func _test_ember_volley(host: Node2D, effects: Node2D) -> void:
	var session := _create_session(host, effects, "ember_ranger", 24)
	_select_only_skill(session, "ember_volley")
	session.skills.runtime.skill_modifiers["ember_volley"]["projectile_speed_multiplier"] = 1.25
	session.skills.runtime.volley_timer = 0.0
	session.skills.advance(0.0, 0.0, 1.0)
	_require(session.projectiles.projectiles.size() == 3, "百鸟朝阳没有生成三枚爆裂箭")
	for projectile in session.projectiles.projectiles:
		_require(projectile.blast_radius == 74.0 and projectile.pierce == 0, "百鸟朝阳终极参数没有应用")
		_require(is_equal_approx(projectile.velocity.length(), 737.5), "烬羽投射物没有应用永久弹速")
	session.free()


func _test_meteor_rain(host: Node2D, effects: Node2D) -> void:
	var session := _create_session(host, effects, "ember_ranger", 25)
	_select_only_skill(session, "meteor_rain")
	var targets: Array = session.enemies.snapshot()
	for index in range(targets.size()):
		_durable_enemy(session, session.player.position + Vector2(index * 180.0, 0.0), targets[index])
	var effect_count: int = effects.effects.size()
	session.skills.runtime.meteor_timer = 0.0
	session.skills.advance(0.0, 0.0, 1.0)
	var damaged_before_impact := 0
	for enemy in targets:
		damaged_before_impact += int(enemy.health < enemy.max_health)
	_require(damaged_before_impact == 0 and session.skills.runtime.timeline.pending_count("meteor_rain") == 3, "天火坠世在陨星落地前提前结算伤害")
	session.skills.advance(0.0, 0.52, 1.52)
	var damaged := 0
	for enemy in targets:
		damaged += int(enemy.health < enemy.max_health)
	_require(damaged == 3 and effects.effects.size() >= effect_count + 3, "天火坠世没有独立轰击三处目标")
	session.free()


func _test_phoenix_heart(host: Node2D, effects: Node2D) -> void:
	var session := _create_session(host, effects, "ember_ranger", 26)
	_select_only_skill(session, "phoenix_heart")
	var enemy = _durable_enemy(session, session.player.position)
	session.player.max_health = 999.0
	session.player.health = 900.0
	var enemy_health_before: float = enemy.health
	session.skills.runtime.phoenix_timer = 0.0
	session.skills.advance(0.0, 0.0, 1.0)
	_require(session.player.health == 900.0 and enemy.health == enemy_health_before, "不灭炎翼在凤凰展开前提前结算效果")
	session.skills.advance(0.0, 0.19, 1.19)
	_require(session.player.health == 902.5, "不灭炎翼没有独立治疗 2.5 点生命")
	_require(enemy.health == enemy_health_before - 38.0, "不灭炎翼没有独立造成范围伤害")
	session.free()


func _test_projectile_resolution(host: Node2D, effects: Node2D) -> void:
	var sweep_session := _create_session(host, effects, "star_warden", 27)
	var sweep_enemy = _durable_enemy(sweep_session, Vector2(60.0, 0.0))
	var sweep_projectile = sweep_session.projectiles.spawn_projectile({
		"position": Vector2.ZERO, "angle": 0.0, "speed": 610.0, "damage": 36.0,
		"radius": 9.0, "pierce": 0, "visual_kind": "star_lance",
	})
	sweep_session.projectiles.advance(0.2)
	_require(sweep_enemy.health == 963.0 and not sweep_session.projectiles.projectiles.has(sweep_projectile), "高速投射物没有使用连续碰撞")
	sweep_session.free()

	var blast_session := _create_session(host, effects, "ember_ranger", 28)
	var targets: Array = blast_session.enemies.snapshot().slice(0, 2)
	for enemy in targets:
		enemy.position = Vector2.ZERO
		enemy.health = 10.0
	var blast_projectile = blast_session.projectiles.spawn_projectile({
		"position": Vector2.ZERO, "angle": 0.0, "speed": 0.0, "damage": 34.0,
		"radius": 9.0, "pierce": 1, "blast_radius": 74.0, "visual_kind": "ember_arrow",
	})
	blast_session.projectiles.advance(0.0)
	_require(blast_session.state.kills == 2, "爆裂箭没有正确结算直击与溅射击杀")
	_require(blast_session.projectiles.projectiles.has(blast_projectile) and blast_projectile.pierce == 0, "溅射击杀目标被重复当作贯穿命中")
	blast_session.free()


func _test_frame_stops_on_upgrade(host: Node2D, effects: Node2D) -> void:
	var session := _create_session(host, effects, "star_warden", 29)
	_select_only_skill(session, "frost_tide")
	var elite = session.enemies.enemies[0]
	elite.position = session.player.position
	elite.health = 1.0
	elite.is_elite = true
	session.elite_enemy = elite
	session.safety.opening_movement_observed = true
	session.skills.runtime.pulse_timer = 0.0
	session.skills.advance(0.0, 0.0, 0.0)
	var projectile = session.projectiles.spawn_projectile({
		"position": Vector2.ZERO, "angle": 0.0, "speed": 100.0, "damage": 1.0,
		"radius": 2.0, "pierce": 0, "visual_kind": "star_lance",
	})
	session.pickups.spawn_pickup("xp", session.player.position, 8)
	session.advance(0.1, Vector2.ZERO)
	_require(session.state.paused and session.state.pending_upgrades == 1, "精英击破没有进入额外升级暂停")
	_require(projectile.position == Vector2.ZERO, "升级暂停触发后本帧投射物仍然推进")
	_require(session.state.experience == 0 and session.pickups.pickups.size() >= 1, "升级暂停触发后本帧仍然收集掉落")
	session.free()


func _test_permanent_move_speed() -> void:
	var player := PlayerEntity.new()
	player.configure("star_warden", HeroCatalog.hero("star_warden"), LevelCatalog.first().map, {"move_speed_multiplier": 1.12})
	_require(is_equal_approx(player.base_speed, 257.6), "永久装备移速没有进入战斗属性")
	player.free()


func _create_session(host: Node2D, effects: Node2D, hero_id: String, seed_value: int) -> Node:
	var session := RunSession.new()
	host.add_child(session)
	var audio := AudioStub.new()
	session.add_child(audio)
	session.configure(hero_id, LevelCatalog.first(), RunRecords.new(""), audio, effects, TestRandomStreams.create(seed_value))
	return session


func _select_only_skill(session: Node, selected_skill_id: String) -> void:
	session.build_state.skill_slots = [selected_skill_id, "", ""]
	session.build_state.skill_levels.clear()
	session.build_state.skill_levels[selected_skill_id] = int(HeroCatalog.skill(selected_skill_id)["max_level"])
	session.skills.sync_after_upgrade(selected_skill_id)


func _durable_enemy(session: Node, position: Vector2, enemy: Node = null) -> Node:
	var target: Node = enemy if enemy != null else session.enemies.enemies[0]
	target.position = position
	target.max_health = 999.0
	target.health = 999.0
	return target


func _test_slow_stack(enemy: Node) -> void:
	enemy.apply_slow(0.28, 1.0, 10.0)
	enemy.apply_slow(0.58, 3.0, 10.0)
	enemy.advance(Vector2.ZERO, 0.0, 10.5)
	_require(is_equal_approx(enemy.slow_factor, 0.28), "重叠减速没有优先使用较强效果")
	enemy.advance(Vector2.ZERO, 0.0, 11.1)
	_require(is_equal_approx(enemy.slow_factor, 0.58), "强减速结束后没有恢复为仍生效的弱减速")
	enemy.advance(Vector2.ZERO, 0.0, 13.1)
	_require(not enemy.slowed and is_equal_approx(enemy.slow_factor, 1.0), "全部减速结束后没有恢复正常速度")


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("HEROES_FAILED: " + message)
