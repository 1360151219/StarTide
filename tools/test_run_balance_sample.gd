extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const BalanceSampleStore = preload("res://scripts/run/balance_sample_store.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const PlayerHitData = preload("res://scripts/combat/player_hit.gd")
const PlayerEntity = preload("res://scripts/player.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")
const BalanceProfileFactory = preload("res://tools/support/balance_profile_factory.gd")

var failed := false
var storage_path := ""
var presentation: Dictionary = {}


func _initialize() -> void:
	_test_legacy_heal_semantics()
	_test_score_profiles()
	storage_path = "user://balance_sample_test_%d.jsonl" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(storage_path))
	var host := Node2D.new()
	root.add_child(host)
	var audio := AudioStub.new()
	host.add_child(audio)
	var effects := CombatEffects.new()
	host.add_child(effects)
	var store := BalanceSampleStore.new(storage_path)
	var session := RunSession.new()
	host.add_child(session)
	session.finished.connect(func(result: Dictionary) -> void: presentation = result)
	session.configure("star_warden", LevelCatalog.first(), RunRecords.new(""), audio, effects, _random_streams(901), store)

	session.advance(0.1, Vector2.ZERO)
	_require(session.result_service._balance_sample.skill_active_seconds.is_empty(), "开局安全门内错误累计技能有效时长")
	session.advance(0.2, Vector2.RIGHT)
	session.skills.skill_released.emit("star_lance")
	var defeated_target: Node = session.enemies.enemies[0]
	var target_health: float = defeated_target.health
	session.enemies.damage_enemy(defeated_target, -3.0, Color.WHITE, Vector2.ZERO, "test:negative_damage")
	_require(is_equal_approx(defeated_target.health, target_health + 3.0), "采样接入改变了负伤害的旧输入语义")
	defeated_target.health = target_health
	session.enemies.damage_enemy(defeated_target, target_health + 5.0, Color.WHITE, Vector2.ZERO, "skill:star_lance")
	var contact_source: Node = session.enemies.enemies[0]
	var contact_source_id := "contact:%s" % contact_source.kind
	_require(session._apply_player_hit(PlayerHitData.create(10.0, contact_source, PlayerHitData.CONTACT, contact_source.position)), "结界没有接受首个测试命中")
	_require(is_equal_approx(session.player.health, session.player.max_health), "结界吸收后仍然扣除生命")
	session.state.elapsed = 0.3
	_require(not session._apply_player_hit(PlayerHitData.create(7.0, contact_source, PlayerHitData.CONTACT, contact_source.position)), "无敌窗口错误接受命中")
	session.state.elapsed = 0.7
	_require(session._apply_player_hit(PlayerHitData.create(12.0, contact_source, PlayerHitData.CONTACT, contact_source.position)), "结界消耗后没有记录实际承伤")
	session.player.heal(20.0, "skill:phoenix_heart")
	session.result_service.record_upgrade(0.8, {"choice_key": "skill:star_lance:level:2", "kind": "skill_upgrade", "content_id": "star_lance", "target_level": 2, "branch_id": ""})
	session.player.health = 3.0
	session.state.elapsed = 1.2
	_require(session._apply_player_hit(PlayerHitData.create(5.0, contact_source, PlayerHitData.CONTACT, contact_source.position)), "致死命中没有进入统一承伤链")
	_require(not presentation.is_empty() and not bool(presentation.get("won", true)), "失败结算没有产出聚合样本")
	_validate_sample(presentation.get("balance_sample", {}), contact_source_id, target_health)
	_require(bool(presentation.get("balance_sample_persisted", false)), "聚合样本没有写入本地 JSONL")
	var stored := store.read_all()
	_require(stored.size() == 1 and int(stored[0].get("schema_version", 0)) == 2, "JSONL 没有保持一局一条的版本化记录")
	var incompatible := stored[0].duplicate(true)
	incompatible["build_id"] = "other-build"
	_require(store.append(incompatible) == ERR_INVALID_DATA, "不同构筑版本错误写入同一数据集")

	host.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(storage_path))
	if not failed:
		print("RUN_BALANCE_SAMPLE_OK schema=2 aggregate=true versions=true counts=true timeline=true persisted=true")
	quit(1 if failed else 0)


func _validate_sample(sample: Dictionary, contact_source_id: String, target_health: float) -> void:
	_require(int(sample.get("schema_version", 0)) == 2 and not str(sample.get("build_id", "")).is_empty() and int(sample.get("content_balance_version", 0)) == 1 and not str(sample.get("sample_id", "")).is_empty(), "聚合样本身份或版本错误")
	_require(sample.get("hero_id", "") == "star_warden" and sample.get("level_id", "") == "level_01", "样本英雄或关卡维度错误")
	_require(sample.get("context", {}).get("mode", "") == "player", "真人局样本上下文错误")
	var opening: Dictionary = sample.get("opening_permanent", {})
	_require(
		int(opening.get("score", 0)) == 1000
		and int(opening.get("score_formula_version", 0)) == 1
		and opening.get("score_purpose", "") == "progression_score"
		and not bool(opening.get("score_calibrated", true)),
		"开局永久快照没有锁定养成评分语义"
	)
	_require(sample.get("random_streams", {}).size() == 5, "固定种子流没有进入离线复现输入")
	_require(not sample.get("resolved_content_pool", {}).get("skill_ids", []).is_empty() and not sample.get("resolved_content_pool", {}).get("relic_ids", []).is_empty(), "解析后的技能或遗物池没有进入样本")
	_require(sample.get("upgrade_timeline", []).size() == 1 and sample["upgrade_timeline"][0]["content_id"] == "star_lance", "升级选择时间线没有进入样本")
	var combat: Dictionary = sample.get("combat", {})
	_require(is_equal_approx(float(combat.get("confirmed_hit_damage_by_source", {}).get("skill:star_lance", 0.0)), target_health + 5.0), "确认命中的伤害聚合错误")
	_require(is_equal_approx(float(combat.get("applied_damage_by_source", {}).get("skill:star_lance", 0.0)), target_health), "技能实际伤害聚合错误")
	_require(is_equal_approx(float(combat.get("overkill_damage_by_source", {}).get("skill:star_lance", 0.0)), 5.0), "过量伤害聚合错误")
	_require(is_equal_approx(float(combat.get("damage_absorbed_by_source", {}).get(contact_source_id, 0.0)), 10.0), "护盾吸收量或来源聚合错误")
	_require(is_equal_approx(float(combat.get("damage_taken_by_source", {}).get(contact_source_id, 0.0)), 15.0), "实际承伤量或来源聚合错误")
	_require(int(combat.get("skill_releases_by_source", {}).get("skill:star_lance", 0)) == 1 and int(combat.get("enemy_hits_by_source", {}).get("skill:star_lance", 0)) == 1, "技能释放数或命中数聚合错误")
	_require(int(combat.get("player_hits_absorbed_by_source", {}).get(contact_source_id, 0)) == 1 and int(combat.get("player_hits_taken_by_source", {}).get(contact_source_id, 0)) == 2, "护盾或承伤次数聚合错误")
	_require(int(combat.get("invulnerable_rejections_by_source", {}).get(contact_source_id, 0)) == 1 and is_equal_approx(float(combat.get("fatal_overkill_by_source", {}).get(contact_source_id, 0.0)), 2.0), "无敌拒绝或致死溢出聚合错误")
	_require(is_equal_approx(float(combat.get("healing_received_by_source", {}).get("skill:phoenix_heart", 0.0)), 12.0), "实际治疗聚合错误")
	_require(is_equal_approx(float(combat.get("overhealing_by_source", {}).get("skill:phoenix_heart", 0.0)), 8.0), "溢出治疗聚合错误")
	_require(float(combat.get("movement_seconds", 0.0)) >= 0.19, "有效移动时长没有聚合")
	_require(float(combat.get("skill_active_seconds", {}).get("skill:star_lance", 0.0)) >= 0.19, "技能有效时长没有聚合")
	var outcome: Dictionary = sample.get("outcome", {})
	_require(outcome.get("end_reason", "") == "defeated" and is_zero_approx(float(outcome.get("remaining_health", -1.0))), "死亡时间或剩余生命没有进入结局样本")


func _test_legacy_heal_semantics() -> void:
	var player := PlayerEntity.new()
	player.max_health = 100.0
	player.health = 105.0
	player.heal(1.0)
	_require(is_equal_approx(player.health, 100.0), "采样接入改变了超上限生命的旧治疗语义")
	player.health = 50.0
	player.heal(-5.0)
	_require(is_equal_approx(player.health, 45.0), "采样接入改变了负治疗的旧输入语义")
	player.free()


func _test_score_profiles() -> void:
	for hero_id in ["star_warden", "ember_ranger"]:
		var previous_score := 0
		for profile_id in BalanceProfileFactory.ids():
			var records: RefCounted = BalanceProfileFactory.create(hero_id, profile_id)
			var score := int(records.get_permanent_snapshot(hero_id)["power"]["total"])
			_require(score > previous_score, "固定策略养成评分档没有严格递增：%s/%s" % [hero_id, profile_id])
			previous_score = score


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
	push_error("RUN_BALANCE_SAMPLE_FAILED: " + message)
