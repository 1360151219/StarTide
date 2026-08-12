extends SceneTree

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const RunBuildState = preload("res://scripts/run/run_build_state.gd")
const UpgradeSystem = preload("res://scripts/systems/upgrade_system.gd")
const Projectile = preload("res://scripts/projectile.gd")

var failed := false


func _initialize() -> void:
	_test_two_offer_limit()
	_test_exhausted_pool_fallback()
	_test_star_lance_pierce_growth()
	if not failed:
		print("UPGRADE_PITY_OK level=4 offer_limit=2 reroll=pinned exhausted_pool=safe pierce=2_3_unlimited")
	quit(1 if failed else 0)


func _test_two_offer_limit() -> void:
	var pity_verified := false
	for seed_value in range(1, 257):
		var build := RunBuildState.new("star_warden")
		_require(build.select_branch("star_lance", "star_lance_fan"), "保底测试无法选择 II 级分支")
		var level_two_overrides := build.branch_overrides("star_lance")
		_require(build.upgrade_skill("star_lance"), "保底测试无法升到 III 级")
		_require(build.branch_overrides("star_lance") == level_two_overrides, "III 级改变了已选分支机制")
		_require(build.upgrade_skill("star_lance"), "保底测试无法升到 IV 级")
		_require(build.branch_overrides("star_lance") == SkillCatalog.branch("star_lance", "star_lance_fan")["level_overrides"][4], "IV 级没有强化已选分支")
		var upgrades := UpgradeSystem.new(_rng(seed_value))
		var skill_pool := SkillCatalog.skills_for_hero("star_warden")
		var relic_pool := RelicCatalog.ids()
		var first_choices: Array = upgrades.build_structured_choices(build, skill_pool, relic_pool, 1.0)
		if _has_skill_target(first_choices, "star_lance", 5):
			continue
		_require(not first_choices.is_empty() and upgrades.apply_structured_choice(first_choices[0]["choice_key"], build)["success"], "首个保底计数候选无法应用")
		_require(build.ultimate_pity_due_skill_ids().has("star_lance"), "IV 级后的首次未出现没有触发下次保底")
		var second_choices: Array = upgrades.build_structured_choices(build, skill_pool, relic_pool, 1.0)
		_require(_has_skill_target(second_choices, "star_lance", 5), "IV 级后的第二次升级没有保底出现 V 级")
		var ultimate_key := "skill:star_lance:level:5"
		_require(build.pinned_choice_keys.has(ultimate_key), "V 级保底候选没有在当前升级中锁定")
		var reroll: Dictionary = upgrades.reroll_structured_choices(build, skill_pool, relic_pool, 1.0)
		_require(reroll["success"] and _has_skill_target(reroll["choices"], "star_lance", 5), "重抽移除了 V 级保底候选")
		_require(upgrades.apply_structured_choice(ultimate_key, build)["success"], "V 级保底候选无法应用")
		_require(int(build.skill_levels["star_lance"]) == 5, "保底候选没有把技能升到 V 级")
		pity_verified = true
		break
	_require(pity_verified, "没有找到可验证两次升级保底的确定性候选序列")


func _test_exhausted_pool_fallback() -> void:
	var build := RunBuildState.new("star_warden")
	_require(build.select_branch("star_lance", "star_lance_fan"), "耗尽池保底测试无法选择分支")
	_require(build.upgrade_skill("star_lance") and build.upgrade_skill("star_lance"), "耗尽池保底测试无法升到 IV 级")
	build.record_upgrade_offer([])
	var upgrades := UpgradeSystem.new(_rng(512))
	var choices := upgrades.build_structured_choices(build, ["star_lance"], [], 1.0)
	_require(not choices.is_empty() and _has_skill_target(choices, "star_lance", 5), "其他候选耗尽时 V 级保底被吞掉")


func _test_star_lance_pierce_growth() -> void:
	var build := RunBuildState.new("star_warden")
	_require(build.select_branch("star_lance", "star_lance_pierce"), "贯星长枪分支无法选择")
	_require(int(build.branch_overrides("star_lance")["pierce"]) == 1, "贯星长枪 II 级没有连续命中 2 个目标")
	_require(build.upgrade_skill("star_lance") and int(build.branch_overrides("star_lance")["pierce"]) == 2, "贯星长枪 III 级没有连续命中 3 个目标")
	_require(build.upgrade_skill("star_lance") and int(build.branch_overrides("star_lance")["pierce"]) == Projectile.UNLIMITED_PIERCE, "贯星长枪 IV 级没有获得无限贯穿")
	var projectile := Projectile.new()
	root.add_child(projectile)
	projectile.pierce = Projectile.UNLIMITED_PIERCE
	for _index in range(4):
		var enemy := Node.new()
		root.add_child(enemy)
		_require(not projectile.register_hit(enemy) and projectile.pierce == Projectile.UNLIMITED_PIERCE, "无限贯穿投射物命中后被消耗")
		enemy.free()
	_require(build.upgrade_skill("star_lance") and int(build.branch_overrides("star_lance")["pierce"]) == Projectile.UNLIMITED_PIERCE, "贯星长枪 V 级丢失无限贯穿")
	projectile.free()


func _has_skill_target(choices: Array, skill_id: String, target_level: int) -> bool:
	for choice in choices:
		if str(choice["kind"]) == UpgradeSystem.SKILL_UPGRADE and str(choice["content_id"]) == skill_id and int(choice["target_level"]) == target_level:
			return true
	return false


func _rng(seed_value: int) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	return random


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("UPGRADE_PITY_FAILED: " + message)
