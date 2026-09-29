extends SceneTree

const RunSession = preload("res://scripts/run/run_session.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const AudioStub = preload("res://tools/support/audio_stub.gd")
const Streams = preload("res://tools/support/test_random_streams.gd")
const StageHud = preload("res://scripts/ui/stage_hud.gd")

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_analog_movement()
	_test_opening_choice_and_ready_cast()
	_test_swept_order_and_blast()
	_test_healing_feedback()
	_test_elite_tracking()
	if not failed:
		print("COMBAT_EXPERIENCE_OK analog=true opening=two_skills idle_cooldowns=ready impact=ordered_and_anchored healing=actual elite=safe_area")
	quit(1 if failed else 0)

func _session(hero := "star_warden", seed_value := 912) -> Node:
	var session := RunSession.new()
	root.add_child(session)
	var audio := AudioStub.new()
	session.add_child(audio)
	var effects := CombatEffects.new()
	session.add_child(effects)
	session.configure(hero, LevelCatalog.first(), RunRecords.new(""), audio, effects, Streams.create(seed_value))
	for enemy in session.enemies.snapshot():
		session.enemies.remove_enemy(enemy)
	return session

func _test_analog_movement() -> void:
	var session := _session()
	var player: Node = session.player
	_require(player.move(Vector2(0.25, 0), 1.0).is_equal_approx(Vector2(player.speed * 0.25, 0)), "摇杆轻推没有按幅度移动")
	_require(player.move(Vector2(2, 2), 1.0).length() <= player.speed + 0.001, "对角输入超过最大移动速度")
	var before: Vector2 = player.position
	player.move(Vector2(0.05, 0), 1.0)
	_require(player.position == before, "摇杆死区内发生漂移")
	session.free()

func _test_opening_choice_and_ready_cast() -> void:
	for hero in ["star_warden", "ember_ranger"]:
		var signature := "star_lance" if hero == "star_warden" else "ember_volley"
		var second := "sun_orbit" if hero == "star_warden" else "meteor_rain"
		for seed_value in range(1, 33):
			var session := _session(hero, seed_value)
			_require(session.skill_pool_ids.size() == 2 and session.skill_pool_ids.has(second), "首关没有两项同英雄技能")
			session.add_experience(session.state.experience_needed)
			var unlock_key := "skill:%s:unlock" % second
			var unlocks: Array = session.build_state.pending_choices.values().filter(func(choice: Dictionary) -> bool: return choice["kind"] == "skill_unlock")
			_require(unlocks.size() == 1 and session.build_state.pending_choices.size() == 3, "第一次升级缺少第二技能或不是三选一")
			if not unlocks.is_empty():
				unlock_key = unlocks[0]["choice_key"]
				_require(session.build_state.pinned_choice_keys.has(unlock_key), "开局技能选项没有在重抽中锁定")
				session.reroll_upgrade()
				_require(session.build_state.pending_choices.has(unlock_key), "重抽丢失第二技能候选")
				_require(session.select_upgrade(unlock_key), "第二技能无法应用")
			if seed_value == 1:
				session.skills.advance(10.0, 0.0, 10.0)
				_require(is_equal_approx(session.skills.cooldown_progress(signature), 1.0), "无敌人时主技能浪费冷却")
				if hero == "ember_ranger":
					_require(is_equal_approx(session.skills.cooldown_progress(second), 1.0) and session.skills.runtime.timeline.pending_count(second) == 0, "无敌人时陨星雨空放")
				_target(session, Vector2(100, 0))
				session.skills.advance(0.0, 0.0, 10.0)
				_require(not session.projectiles.projectiles.is_empty(), "目标出现后已就绪技能没有立即发射")
				session.skills.sync_after_upgrade(signature)
				var timer: float = session.skills.runtime.bolt_timer if hero == "star_warden" else session.skills.runtime.volley_timer
				_require(timer <= 0.3, "升级主技能后仍等待完整旧冷却")
				if hero == "star_warden":
					session.build_state.select_branch(signature, "star_lance_pierce")
					session.skills.runtime.bolt_timer = 0.0
					session.skills.advance(0.0, 0.0, 10.0)
					var projectile: Node = session.projectiles.projectiles.back()
					_require(projectile.branch_id == "star_lance_pierce" and projectile.skill_level == 2, "星枪投射物丢失分支和等级")
			session.free()

func _target(session: Node, position: Vector2) -> Node:
	var enemy: Node = session.enemies.spawn_enemy("slime", null, 0.0)
	enemy.position = position
	enemy.radius = 10.0
	enemy.health = 999.0
	enemy.max_health = 999.0
	return enemy

func _shot(session: Node, pierce := 0, blast := 0.0) -> Node:
	return session.projectiles.spawn_projectile({"position": Vector2.ZERO, "angle": 0.0, "speed": 600.0, "damage": 20.0, "radius": 5.0, "pierce": pierce, "blast_radius": blast, "visual_kind": "ember_arrow" if blast > 0.0 else "star_lance"})

func _test_swept_order_and_blast() -> void:
	for step in [1.0 / 60.0, 0.2]:
		var session := _session()
		var far := _target(session, Vector2(105, 0))
		var near := _target(session, Vector2(45, 0))
		var adjacent := _target(session, Vector2(38, 25))
		_shot(session, 0, 30.0)
		for _frame in range(roundi(0.2 / step)):
			session.projectiles.advance(step)
		_require(near.health == 979.0 and far.health == 999.0, "弹体按出生顺序命中了后方目标")
		_require(is_equal_approx(adjacent.health, 988.0), "低帧率时爆点越过敌群，溅射漏伤")
		var impact: Dictionary = session.effects.effects.filter(func(effect: Dictionary) -> bool: return effect["kind"] == "ember_volley_blast")[0]
		_require(Vector2(impact["position"]).is_equal_approx(Vector2(30, 0)), "爆心特效没有落在首次接触点")
		session.free()
	var session := _session()
	var far := _target(session, Vector2(105, 0))
	var near := _target(session, Vector2(45, 0))
	var shot := _shot(session, -1)
	session.projectiles.advance(0.2)
	_require(far.health == 979.0 and near.health == 979.0 and shot.position == Vector2(120, 0), "贯穿结算停在了首个目标")
	session.projectiles.advance(0.0)
	_require(far.health == 979.0 and near.health == 979.0, "同一枚贯穿弹重复命中同一目标")
	shot.previous_position = Vector2.ZERO
	shot.position = Vector2(100, 0)
	_require(is_equal_approx(shot.collision_fraction(Vector2(50, 10), 10.0), 0.5), "擦边命中被漏判")
	_require(shot.collision_fraction(Vector2(50, 11), 10.0) == INF, "轨迹外的目标被误命中")
	shot.position = Vector2.ZERO
	_require(shot.collision_fraction(Vector2.ZERO, 10.0) == 0.0 and shot.collision_fraction(Vector2(20, 0), 10.0) == INF, "静止弹体重叠判定错误")
	session.free()

func _test_healing_feedback() -> void:
	var session := _session("ember_ranger")
	session.player.heal(15.0, "test")
	_require(session.effects.effects.is_empty(), "满血仍显示虚假治疗数字")
	session.player.health -= 1.0
	session.player.heal(15.0, "test")
	_require(session.effects.effects.size() == 1 and session.effects.effects[0]["text"] == "+1", "治疗数字没有使用真实恢复量")
	session.effects.clear_all()
	session.pickups.spawn_pickup("heart", session.player.position, 1)
	session.pickups.advance(0.0, 0.0)
	_require(not session.effects.effects.any(func(effect: Dictionary) -> bool: return effect["kind"] == "heal_text"), "满血拾取仍显示虚假加血")
	session.free()

func _test_elite_tracking() -> void:
	var hud := StageHud.new()
	root.add_child(hud)
	_require(is_equal_approx(hud.elite_health.size.y, 8.0), "强敌血条被默认文字高度撑出面板")
	hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var enemy := Node2D.new()
	root.add_child(enemy)
	for canvas in [Vector2(540, 960), Vector2(540, 1170), Vector2(540, 1200), Vector2(720, 960)]:
		hud.size = canvas
		hud.position = Vector2(0, 44)
		for offset in [Vector2(-2000, 0), Vector2(2000, 0), Vector2(0, -2000), Vector2(0, 2000), Vector2(2000, -2000)]:
			enemy.position = canvas * 0.5 + hud.position + offset
			hud._update_elite_marker(enemy)
			_require(hud.elite_marker_visible and Rect2(Vector2(39, 179), canvas - Vector2(78, 328)).has_point(hud.elite_marker_position), "精英方向标越过安全区或遮挡底部技能入口")
		enemy.position = canvas * 0.5 + hud.position
		hud._update_elite_marker(enemy)
		_require(not hud.elite_marker_visible, "强敌回到视野后方向标仍然遮挡战场")
		hud._update_elite_marker(null)
		_require(not hud.elite_marker_visible, "强敌离场后残留方向标")
	enemy.free()
	hud.free()

func _require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("COMBAT_EXPERIENCE_FAILED: " + message)
