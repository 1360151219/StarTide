extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const HeroProgression = preload("res://scripts/profile/hero_progression.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")
const ProfileSchema = preload("res://scripts/profile/profile_schema.gd")

var failed := false
var cleanup_paths: Array[String] = []


func _initialize() -> void:
	_test_rewards_and_training()
	_test_schema_migration_and_repair()
	var host := Node2D.new()
	root.add_child(host)
	var effects := CombatEffects.new()
	host.add_child(effects)
	_test_star_skill_modifiers(host, effects)
	_test_ember_skill_modifiers(host, effects)
	host.free()
	for path in cleanup_paths:
		DirAccess.remove_absolute(path)
	if not failed:
		print("PROGRESSION_OK schema=4 migration=true levels=10 skill_points=9 reset=free skills=6 snapshot=true")
	quit(1 if failed else 0)


func _test_rewards_and_training() -> void:
	var test_path := _new_test_path("progression")
	var records := RunRecords.new(test_path)
	var level := LevelCatalog.first()
	var no_reward := records.record_level_run("ember_ranger", level.level_id, false, false, 0, 1, 29.9, level.reward)
	_require(no_reward["progression_reward"]["mastery_xp_gained"] == 0, "30 秒内失败仍获得熟练度")
	var failure_reward := records.record_level_run("ember_ranger", level.level_id, false, false, 0, 1, 90.0, level.reward)
	_require(failure_reward["progression_reward"]["mastery_xp_gained"] == 30, "失败熟练度没有按存活时间封顶")
	for _index in range(9):
		records.record_level_run("star_warden", level.level_id, true, false, 1, 1, 90.0, level.reward)
	var snapshot := records.progression_snapshot("star_warden")
	_require(snapshot["level"] == 10 and snapshot["total_skill_points"] == 9, "九次通关没有达到十级或获得九点技能点")
	_require(not records.train_skill("star_warden", "star_lance")["success"], "未发现技能被永久培养")
	for skill_id in HeroCatalog.hero("star_warden")["skills"]:
		records.discover_content("skills", skill_id)
	for skill_id in ["star_lance", "star_lance", "star_lance", "sun_orbit", "sun_orbit"]:
		_require(records.train_skill("star_warden", skill_id)["success"], "合法技能训练失败")
	_require(not records.train_skill("star_warden", "frost_tide")["success"], "超预算技能训练成功")
	snapshot = records.progression_snapshot("star_warden")
	_require(snapshot["spent_skill_points"] == 9 and snapshot["available_skill_points"] == 0, "技能点成本计算错误")
	var profile_id: String = records.profile_id
	var revision: int = records.revision
	var reloaded := RunRecords.new(test_path)
	_require(reloaded.profile_id == profile_id and reloaded.revision == revision, "档案标识或修订号没有持久化")
	_require(reloaded.progression_snapshot("star_warden")["spent_skill_points"] == 9, "永久技能训练没有持久化")
	_require(reloaded.reset_skill_training("star_warden")["success"], "免费重置失败")
	_require(reloaded.progression_snapshot("star_warden")["available_skill_points"] == 9, "免费重置没有返还全部技能点")


func _test_schema_migration_and_repair() -> void:
	var legacy_path := _new_test_path("legacy")
	var legacy := ConfigFile.new()
	legacy.set_value("meta", "schema_version", 2)
	legacy.set_value("hero/star_warden", "wins", 2)
	legacy.save(legacy_path)
	var migrated := RunRecords.new(legacy_path)
	_require(migrated.progression_snapshot("star_warden")["mastery_xp"] == 200, "旧通关次数没有迁移为熟练度")
	var migrated_file := ConfigFile.new()
	migrated_file.load(legacy_path)
	_require(migrated_file.get_value("meta", "schema_version", 0) == ProfileSchema.VERSION, "旧存档没有立即写回最新 schema")
	_require(not str(migrated_file.get_value("meta", "profile_id", "")).is_empty(), "迁移后没有稳定档案标识")

	var broken_path := _new_test_path("over_budget")
	var broken := ConfigFile.new()
	broken.set_value("meta", "schema_version", 3)
	broken.set_value("meta", "profile_id", "repair-me")
	broken.set_value("progression/star_warden", "mastery_xp", 100)
	for skill_id in HeroCatalog.hero("star_warden")["skills"]:
		broken.set_value("progression/star_warden", "training_" + skill_id, 99)
	broken.save(broken_path)
	var repaired_records := RunRecords.new(broken_path)
	var repaired := repaired_records.progression_snapshot("star_warden")
	_require(repaired["spent_skill_points"] <= repaired["total_skill_points"], "越级或超预算训练没有自动修复")
	var repaired_file := ConfigFile.new()
	repaired_file.load(broken_path)
	_require(int(repaired_file.get_value("meta", "revision", 0)) > 0, "自动修复没有持久化")


func _test_star_skill_modifiers(host: Node2D, effects: Node2D) -> void:
	var lance := _trained_session(host, effects, "star_warden", "star_lance", 41)
	_require(_close(lance.player.max_health, HeroCatalog.hero("star_warden")["max_health"] * 1.09), "英雄等级生命倍率未应用")
	var lance_data: Dictionary = HeroCatalog.skill("star_lance")["runtime"]
	lance.skills.runtime.bolt_timer = 0.0
	lance.skills.advance(0.0, 0.0, 1.0)
	var bolt = lance.projectiles.projectiles[0]
	_require(_close(bolt.damage, lance_data["damage"][1] * 1.135 * 1.04), "星芒枪伤害训练未应用")
	_require(_close(bolt.velocity.length(), lance_data["speed"][1] * 1.10), "星芒枪弹速训练未应用")
	_require(_close(lance.skills.runtime.bolt_timer, lance_data["cooldown"][1] * 0.96), "星芒枪冷却训练未应用")
	lance.free()

	var orbit := _trained_session(host, effects, "star_warden", "sun_orbit", 42)
	var orbit_data: Dictionary = HeroCatalog.skill("sun_orbit")["runtime"]
	var orbit_enemy = _durable_enemy(orbit, orbit.player.position + Vector2(orbit_data["orbit_radius"][1] * 1.08, 0.0))
	orbit.skills.runtime.orbit_phase = 0.0
	orbit.skills.runtime.orbit_hit_timer = 0.0
	orbit.skills.advance(0.0, 0.0, 1.0)
	_require(_close(999.0 - orbit_enemy.health, orbit_data["damage"][1] * 1.135 * 1.04), "日轮伤害或范围训练未应用")
	_require(_close(orbit.skills.runtime.orbit_hit_timer, orbit_data["hit_interval"][1] * 0.96), "日轮命中间隔训练未应用")
	orbit.free()

	var frost := _trained_session(host, effects, "star_warden", "frost_tide", 43)
	var frost_data: Dictionary = HeroCatalog.skill("frost_tide")["runtime"]
	var frost_enemy = _durable_enemy(frost, frost.player.position + Vector2(frost_data["radius"][1] * 1.04, 0.0))
	frost.skills.runtime.pulse_timer = 0.0
	frost.skills.advance(0.0, 0.0, 1.0)
	_require(_close(999.0 - frost_enemy.health, frost_data["damage"][1] * 1.135 * 1.04), "霜潮伤害或范围训练未应用")
	_require(_close(frost.skills.runtime.pulse_timer, frost_data["cooldown"][1] * 0.96), "霜潮冷却训练未应用")
	frost.free()


func _test_ember_skill_modifiers(host: Node2D, effects: Node2D) -> void:
	var volley := _trained_session(host, effects, "ember_ranger", "ember_volley", 51)
	var volley_data: Dictionary = HeroCatalog.skill("ember_volley")["runtime"]
	volley.skills.runtime.volley_timer = 0.0
	volley.skills.advance(0.0, 0.0, 1.0)
	var arrow = volley.projectiles.projectiles[0]
	_require(_close(arrow.damage, volley_data["damage"][1] * 1.135 * 1.04), "烬羽连矢伤害训练未应用")
	_require(_close(arrow.blast_radius, volley_data["blast_radius"][1] * 1.08), "烬羽连矢范围训练未应用")
	_require(_close(volley.skills.runtime.volley_timer, volley_data["cooldown"][1] * 0.96), "烬羽连矢冷却训练未应用")
	volley.free()

	var meteor := _trained_session(host, effects, "ember_ranger", "meteor_rain", 52)
	var meteor_data: Dictionary = HeroCatalog.skill("meteor_rain")["runtime"]
	var meteor_enemy = _durable_enemy(meteor, meteor.player.position)
	meteor.skills.runtime.meteor_timer = 0.0
	meteor.skills.advance(0.0, 0.0, 1.0)
	_require(_close(999.0 - meteor_enemy.health, meteor_data["damage"][1] * 1.135 * 1.04), "陨星雨伤害训练未应用")
	_require(_has_effect_radius(effects, "meteor", meteor_data["radius"][1] * 1.08), "陨星雨范围训练未应用")
	_require(_close(meteor.skills.runtime.meteor_timer, meteor_data["cooldown"][1] * 0.96), "陨星雨冷却训练未应用")
	meteor.free()

	var phoenix := _trained_session(host, effects, "ember_ranger", "phoenix_heart", 53)
	var phoenix_data: Dictionary = HeroCatalog.skill("phoenix_heart")["runtime"]
	var phoenix_enemy = _durable_enemy(phoenix, phoenix.player.position)
	phoenix.player.health -= 20.0
	var health_before: float = phoenix.player.health
	phoenix.skills.runtime.phoenix_timer = 0.0
	phoenix.skills.advance(0.0, 0.0, 1.0)
	_require(_close(phoenix.player.health - health_before, phoenix_data["healing"][1] * 1.04), "凤凰之心治疗训练未应用")
	_require(_close(999.0 - phoenix_enemy.health, phoenix_data["damage"][1] * 1.135 * 1.04), "凤凰之心伤害训练未应用")
	_require(_has_effect_radius(effects, "phoenix", phoenix_data["radius"][1] * 1.08), "凤凰之心范围训练未应用")
	phoenix.free()


func _trained_session(host: Node2D, effects: Node2D, hero_id: String, skill_id: String, seed_value: int) -> Node:
	var records := RunRecords.new("")
	var training := {}
	for active_skill_id in HeroCatalog.hero(hero_id)["skills"]:
		training[active_skill_id] = 3 if active_skill_id == skill_id else 0
	records.hero_progressions[hero_id] = {"mastery_xp": 900, "training": training}
	var session := RunSession.new()
	host.add_child(session)
	var audio := AudioStub.new()
	session.add_child(audio)
	session.configure(hero_id, LevelCatalog.first(), records, audio, effects, _random_streams(seed_value))
	var default_skill_id: String = session.skills.active_skill_ids[0]
	for active_skill_id in session.skills.active_skill_ids:
		if not str(active_skill_id).is_empty():
			_require(session.skills.levels[active_skill_id] == (1 if active_skill_id == default_skill_id else 0), "永久训练提前解锁或提升了局内技能")
	session.build_state.skill_slots = [skill_id, "", ""]
	session.build_state.skill_levels.clear()
	session.build_state.skill_levels[skill_id] = 1
	session.skills.sync_after_upgrade(skill_id)
	return session


func _durable_enemy(session: Node, position: Vector2) -> Node:
	var enemy = session.enemies.enemies[0]
	for other_enemy in session.enemies.enemies.duplicate():
		if other_enemy != enemy:
			session.enemies.remove_enemy(other_enemy)
	enemy.position = position
	enemy.max_health = 999.0
	enemy.health = 999.0
	return enemy


func _random_streams(seed_value: int) -> Dictionary:
	var streams := {}
	for stream_id in ["spawn", "loot", "skill", "upgrade", "enemy_ability"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + streams.size()
		streams[stream_id] = rng
	return streams


func _has_effect_radius(effects: Node, kind: String, radius: float) -> bool:
	for effect in effects.effects:
		if effect["kind"] == kind and _close(effect["radius"], radius):
			return true
	return false


func _new_test_path(label: String) -> String:
	var path := "user://%s_%d.cfg" % [label, OS.get_process_id()]
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute)
	cleanup_paths.append(absolute)
	return path


func _close(left: float, right: float) -> bool:
	return is_equal_approx(left, right)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PROGRESSION_FAILED: " + message)
