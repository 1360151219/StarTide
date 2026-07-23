extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")

var failed := false


func _initialize() -> void:
	var root_node := Node2D.new()
	root.add_child(root_node)
	var audio := AudioStub.new()
	root_node.add_child(audio)
	var effects := CombatEffects.new()
	root_node.add_child(effects)
	var records := RunRecords.new("")
	for level in LevelCatalog.all():
		_require(records.is_level_unlocked(level.level_id), "%s 尚未按顺序解锁" % level.display_name)
		var session := RunSession.new()
		root_node.add_child(session)
		session.configure("star_warden", level, records, audio, effects, _random_streams(level.order))
		_require(session.level == level and session.stage_director.current_stage() == level.stages[0], "%s 未由统一会话加载" % level.display_name)
		session.player.max_health = 99999.0
		session.player.health = 99999.0
		session.advance(level.elite.spawn_time + 0.01, Vector2.ZERO)
		_require(session.state.elite_spawned and is_instance_valid(session.elite_enemy), "%s 精英未按配置生成" % level.display_name)
		session.enemies.damage_enemy(session.elite_enemy, session.elite_enemy.max_health + 1.0)
		var upgrade_steps := 0
		while session.state.pending_upgrades > 0 and not session.state.finished:
			var choices: Array = session.build_state.pending_choices.values()
			if choices.is_empty() or upgrade_steps >= 10:
				_require(false, "%s 精英奖励升级无法收敛" % level.display_name)
				break
			session.select_upgrade(choices[0]["choice_key"])
			upgrade_steps += 1
		if not session.state.finished:
			session.advance(level.duration - session.state.elapsed, Vector2.ZERO)
		_require(session.state.finished and session.state.victory, "%s 未能按独立胜利条件通关" % level.display_name)
		session.queue_free()
	if not failed:
		print("CAMPAIGN_OK levels=3 unlock_chain=true elites=configured upgrades=bounded victory=per_level")
	quit(1 if failed else 0)


func _random_streams(seed_value: int) -> Dictionary:
	var streams := {}
	for stream_id in ["spawn", "loot", "skill", "upgrade", "enemy_ability"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value * 100 + streams.size()
		streams[stream_id] = rng
	return streams


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("CAMPAIGN_FAILED: " + message)
