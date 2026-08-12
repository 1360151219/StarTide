extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const PlayerHitData = preload("res://scripts/combat/player_hit.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")

var failed := false


func _initialize() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var effects := CombatEffects.new()
	host.add_child(effects)
	var session := RunSession.new()
	host.add_child(session)
	var audio := AudioStub.new()
	session.add_child(audio)
	session.configure("ember_ranger", LevelCatalog.first(), RunRecords.new(""), audio, effects, _random_streams(301))
	_test_opening_gate(session)
	_test_upgrade_resume(session)
	host.free()
	if not failed:
		print("RUN_SAFETY_OK opening_gate=true enemy_freeze=0 upgrade_grace=1.5 shared_damage=true")
	quit(1 if failed else 0)


func _test_opening_gate(session: Node) -> void:
	var enemy = session.enemies.enemies[0]
	var enemy_position: Vector2 = enemy.position
	session.advance(1.0, Vector2.ZERO)
	_require(enemy.position == enemy_position, "新手尚未移动时怪物仍在推进")
	session.advance(0.01, Vector2.RIGHT)
	_require(session.safety.opening_movement_observed, "首次有效移动没有结束教学保护")


func _test_upgrade_resume(session: Node) -> void:
	var enemy = session.enemies.enemies[0]
	enemy.position = session.player.position
	session.add_experience(session.state.experience_needed)
	_require(session.state.paused and not session.build_state.pending_choices.is_empty(), "升级恢复保护测试没有进入选择状态")
	var choice_key := str(session.build_state.pending_choices.keys()[0])
	_require(session.select_upgrade(choice_key), "升级恢复保护测试无法应用候选")
	_require(session.safety.combat_ready(Vector2.ZERO, session.state.elapsed, session.level), "升级完成后敌群没有立即恢复")
	_require(session.damage_resolver.is_invulnerable(session.state.elapsed + 1.49), "升级完成后没有获得 1.5 秒统一无敌")
	_require(enemy.position == session.player.position, "升级完成后敌人位置被突兀改写")
	var health_before: float = session.player.health
	var blocked: bool = session.damage_resolver.apply(
		PlayerHitData.create(9.0, enemy, PlayerHitData.CONTACT, enemy.position),
		session.state.elapsed + 1.49,
		false
	)
	_require(not blocked and session.player.health == health_before, "升级恢复无敌期间仍然承伤")
	var applied: bool = session.damage_resolver.apply(
		PlayerHitData.create(9.0, enemy, PlayerHitData.CONTACT, enemy.position),
		session.state.elapsed + 1.51,
		false
	)
	_require(applied and session.player.health < health_before, "升级恢复无敌到期后仍然无法承伤")


func _random_streams(seed_value: int) -> Dictionary:
	var streams := {}
	for stream_id in ["spawn", "loot", "skill", "upgrade", "enemy_ability"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + streams.size()
		streams[stream_id] = rng
	return streams


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("RUN_SAFETY_FAILED: " + message)
