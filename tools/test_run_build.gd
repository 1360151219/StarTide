extends SceneTree

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const RunBuildState = preload("res://scripts/run/run_build_state.gd")
const BuildSummary = preload("res://scripts/run/build_summary.gd")
const UpgradeSystem = preload("res://scripts/systems/upgrade_system.gd")

var failed := false


func _initialize() -> void:
	_test_catalogs()
	_test_branch_balance()
	_test_build_state()
	_test_structured_choices()
	_test_exhausted_pool_fallbacks()
	_test_reroll_determinism()
	if not failed:
		print("RUN_BUILD_OK catalogs=data_driven skill_slots=3 relic_slots=4 output_cap=4.5 phoenix_hps=1.8 structured=true validation=strict reroll=deterministic")
	quit(1 if failed else 0)


func _test_catalogs() -> void:
	_require(not SkillCatalog.ids().is_empty() and SkillCatalog.validation_errors().is_empty(), "技能目录配置无效")
	for skill_id in SkillCatalog.ids():
		var skill := SkillCatalog.skill(skill_id)
		_require(skill["branches"].size() == 2, "%s 未配置双分支" % skill_id)
		_require(skill["icon"] != null, "%s 缺少图标" % skill_id)
		_require(HeroCatalog.ids().has(str(skill["owner_hero_id"])), "%s 引用了未知英雄" % skill_id)
		_require(HeroCatalog.skill(skill_id) == skill, "HeroCatalog.skill 兼容入口未委托到 SkillCatalog")
	for hero_id in HeroCatalog.ids():
		_require(not SkillCatalog.signature_for_hero(hero_id).is_empty(), "%s 缺少签名技能" % hero_id)
	_require(not RelicCatalog.ids().is_empty() and RelicCatalog.validation_errors().is_empty(), "遗物目录配置无效")
	for relic_id in RelicCatalog.ids():
		var relic := RelicCatalog.relic(relic_id)
		_require(int(relic["max_level"]) == 3, "%s 等级上限错误" % relic_id)
		var icon := RelicCatalog.icon(relic_id)
		_require(icon != null and icon.atlas == RelicCatalog.ITEM_ATLAS, "%s 未使用统一遗物图集" % relic_id)


func _test_branch_balance() -> void:
	for skill_id in SkillCatalog.ids():
		var base_output := _effective_output(skill_id, 1, {})
		_require(base_output > 0.0, "%s 的 I 级理论输出无效" % skill_id)
		for branch_id in SkillCatalog.branch_ids(skill_id):
			var branch := SkillCatalog.branch(skill_id, branch_id)
			var overrides: Dictionary = branch["level_overrides"][3]
			var ratio := _effective_output(skill_id, 3, overrides) / base_output
			_require(ratio <= 4.5 + 0.0001, "%s/%s 的 I→III 理论输出达到 %.3f 倍" % [skill_id, branch_id, ratio])
			if skill_id == "phoenix_heart":
				var runtime: Dictionary = SkillCatalog.skill(skill_id)["runtime"]
				var healing := float(runtime["healing"][3]) * float(overrides.get("healing_multiplier", 1.0)) * 1.04
				var cooldown := float(runtime["cooldown"][3]) * float(overrides.get("cooldown_multiplier", 1.0)) * 0.96
				var healing_per_second := healing / cooldown
				_require(healing_per_second <= 1.8 + 0.0001, "%s 训练 III 后治疗达到 %.3f HP/s" % [branch_id, healing_per_second])


func _test_build_state() -> void:
	var build := RunBuildState.new("star_warden")
	_require(build.skill_slots.size() == 3, "主动技能槽数量不是 3")
	_require(build.skill_slots[0] == "star_lance" and build.skill_levels["star_lance"] == 1, "签名技能没有以 I 级进入首槽")
	_require(build.add_skill("sun_orbit") and build.add_skill("frost_tide"), "合法英雄技能无法填入空槽")
	_require(not build.add_skill("ember_volley") and not build.has_free_skill_slot(), "错误英雄技能或第四技能进入了构筑")
	_require(build.add_or_upgrade_relic("energy_prism"), "遗物无法加入构筑")
	_require(build.add_or_upgrade_relic("energy_prism"), "遗物无法升级")
	_require(_close(build.modifier("damage_multiplier"), 1.14), "遗物伤害修正没有按等级重算")
	_require(build.add_or_upgrade_relic("time_gear"), "时砂齿轮无法加入构筑")
	_require(_close(build.modifier("cooldown_multiplier"), 0.95), "冷却修正错误")
	_require(build.add_or_upgrade_relic("star_core"), "星核扩容无法加入构筑")
	_require(_close(build.modifier("max_health_flat"), 15.0), "生命平铺修正错误")
	_require(build.add_or_upgrade_relic("flow_feather"), "第四类遗物无法加入构筑")
	_require(build.unique_relic_count() == 4 and not build.add_or_upgrade_relic("echo_lens"), "第五类遗物突破了四槽上限")
	var summary := BuildSummary.text(build)
	_require(summary.contains("星芒枪 I") and summary.contains("聚能棱晶 II"), "暂停与结算构筑摘要缺少技能或遗物等级")
	_require(summary.contains("重抽 1"), "构筑摘要没有展示剩余重抽次数")


func _test_structured_choices() -> void:
	var initial_skill_pool := ["star_lance"]
	var initial_relic_pool := ["star_core", "flow_feather"]
	var branch_case := _find_initial_offer(initial_skill_pool, initial_relic_pool, true)
	var regular_case := _find_initial_offer(initial_skill_pool, initial_relic_pool, false)
	_require(not branch_case.is_empty(), "初次升级的随机池无法生成签名技能分支候选")
	_require(not regular_case.is_empty(), "初次升级仍被固定为首个技能分支")
	if branch_case.is_empty():
		return
	var build: RefCounted = branch_case["build"]
	var upgrades: RefCounted = branch_case["upgrades"]
	var choices: Array = branch_case["choices"]
	var skill_pool := SkillCatalog.skills_for_hero("star_warden")
	var relic_pool := RelicCatalog.ids()
	_require(choices.size() == 3, "结构化三选一没有生成三个候选")
	_require(_count_kind(choices, UpgradeSystem.SKILL_BRANCH) == 2, "I→II 没有同时给出两个技能分支")
	for choice in choices:
		_require(choice.has("choice_key") and choice.has("kind") and choice.has("content_id") and choice.has("target_level"), "候选缺少结构化字段")
	_require(not upgrades.apply_structured_choice("forged:choice", build)["success"], "未知候选被错误应用")
	var branch_choice := _first_kind(choices, UpgradeSystem.SKILL_BRANCH)
	var result: Dictionary = upgrades.apply_structured_choice(branch_choice["choice_key"], build)
	_require(result["success"], "合法技能分支无法应用")
	_require(build.skill_levels["star_lance"] == 2 and build.skill_branches["star_lance"] == branch_choice["branch_id"], "分支没有写入局内构筑状态")
	_require(not upgrades.apply_structured_choice(branch_choice, build)["success"], "已消费候选被重复应用")

	var next_choices: Array = upgrades.build_structured_choices(build, skill_pool, relic_pool, 1.0)
	_require(_has_skill_growth(next_choices) and _count_kind(next_choices, UpgradeSystem.RELIC_UPGRADE) >= 1, "常规候选没有同时包含技能成长与遗物")
	build.clear_offer()
	build.skill_levels["star_lance"] = 3
	var legal: Array = upgrades.legal_structured_candidates(build, skill_pool, relic_pool, 1.0)
	_require(not _has_content(legal, "star_lance"), "满级技能仍进入候选")
	var locked: Array = upgrades.legal_structured_candidates(RunBuildState.new("star_warden"), ["star_lance"], relic_pool, 1.0)
	_require(not _has_content(locked, "sun_orbit") and not _has_content(locked, "frost_tide"), "未进入技能池的技能仍可出现")

	var relic_full := RunBuildState.new("star_warden")
	for relic_id in ["star_core", "flow_feather", "energy_prism", "time_gear"]:
		_require(relic_full.add_or_upgrade_relic(relic_id), "测试遗物槽填充失败")
	var full_candidates: Array = upgrades.legal_structured_candidates(relic_full, skill_pool, relic_pool, 1.0)
	for choice in full_candidates:
		if choice["kind"] == UpgradeSystem.RELIC_UPGRADE and not relic_full.relic_levels.has(choice["content_id"]):
			_require(false, "遗物槽满后仍出现新遗物：" + str(choice["content_id"]))


func _test_reroll_determinism() -> void:
	var first_build := RunBuildState.new("star_warden")
	var first_upgrades := UpgradeSystem.new(_rng(2048))
	var first_choices := first_upgrades.build_structured_choices(first_build, SkillCatalog.skills_for_hero("star_warden"), RelicCatalog.ids(), 1.0)
	var first_key := _group_key(first_choices)
	var first_reroll := first_upgrades.reroll_structured_choices(first_build, SkillCatalog.skills_for_hero("star_warden"), RelicCatalog.ids(), 1.0)
	_require(first_reroll["success"], "首次重抽失败")
	var reroll_key := _group_key(first_reroll["choices"])
	_require(reroll_key != first_key, "重抽返回了完全相同的一组候选")
	_require(first_build.rerolls_remaining == 0, "重抽没有消费唯一次数")
	_require(not first_upgrades.reroll_structured_choices(first_build, SkillCatalog.skills_for_hero("star_warden"), RelicCatalog.ids(), 1.0)["success"], "第二次重抽被允许")

	var second_build := RunBuildState.new("star_warden")
	var second_upgrades := UpgradeSystem.new(_rng(2048))
	var second_choices := second_upgrades.build_structured_choices(second_build, SkillCatalog.skills_for_hero("star_warden"), RelicCatalog.ids(), 1.0)
	var second_reroll := second_upgrades.reroll_structured_choices(second_build, SkillCatalog.skills_for_hero("star_warden"), RelicCatalog.ids(), 1.0)
	_require(_group_key(second_choices) == first_key and _group_key(second_reroll["choices"]) == reroll_key, "相同随机种子的候选或重抽不确定")


func _test_exhausted_pool_fallbacks() -> void:
	var branch_build := RunBuildState.new("star_warden")
	for relic_id in ["star_core", "flow_feather"]:
		for level in range(3):
			_require(branch_build.add_or_upgrade_relic(relic_id), "分支兜底测试无法填满遗物")
	var upgrades := UpgradeSystem.new(_rng(3048))
	var branch_choices := upgrades.build_structured_choices(branch_build, ["star_lance"], ["star_core", "flow_feather"], 1.0)
	_require(branch_choices.size() == 3 and _count_kind(branch_choices, UpgradeSystem.SKILL_BRANCH) == 2, "遗物池耗尽后分支三选一中断")
	_require(_count_kind(branch_choices, UpgradeSystem.UTILITY_RECOVERY) == 1, "分支池耗尽兜底没有提供应急修复")

	var skill_only := RunBuildState.new("star_warden")
	var skill_choices := upgrades.build_structured_choices(skill_only, ["star_lance"], [], 1.0)
	_require(skill_choices.size() == 3 and _count_kind(skill_choices, UpgradeSystem.SKILL_BRANCH) == 2, "无遗物池时没有维持三选一")


func _find_initial_offer(skill_pool, relic_pool, wants_branch: bool) -> Dictionary:
	for seed_value in range(1, 129):
		var build := RunBuildState.new("star_warden")
		var upgrades := UpgradeSystem.new(_rng(seed_value))
		var choices := upgrades.build_structured_choices(build, skill_pool, relic_pool, 1.0)
		var branch_count := _count_kind(choices, UpgradeSystem.SKILL_BRANCH)
		_require(branch_count == 0 or branch_count == 2, "技能分支被拆成单个随机候选")
		if (branch_count == 2) == wants_branch:
			return {"build": build, "upgrades": upgrades, "choices": choices}
	return {}


func _first_kind(choices: Array, kind: String) -> Dictionary:
	for choice in choices:
		if str(choice["kind"]) == kind:
			return choice
	return {}


func _count_kind(choices: Array, kind: String) -> int:
	var count := 0
	for choice in choices:
		count += int(str(choice["kind"]) == kind)
	return count


func _has_skill_growth(choices: Array) -> bool:
	for choice in choices:
		if [UpgradeSystem.SKILL_UNLOCK, UpgradeSystem.SKILL_UPGRADE, UpgradeSystem.SKILL_BRANCH].has(str(choice["kind"])):
			return true
	return false


func _has_content(choices: Array, content_id: String) -> bool:
	for choice in choices:
		if str(choice["content_id"]) == content_id:
			return true
	return false


func _group_key(choices: Array) -> String:
	var keys := PackedStringArray()
	for choice in choices:
		keys.append(str(choice["choice_key"]))
	keys.sort()
	return "|".join(keys)


func _effective_output(skill_id: String, level: int, overrides: Dictionary) -> float:
	var runtime: Dictionary = SkillCatalog.skill(skill_id)["runtime"]
	var damage := float(runtime["damage"][level]) * float(overrides.get("damage_multiplier", 1.0))
	if skill_id == "sun_orbit":
		var orbit_count := int(overrides.get("count", runtime["count"][level]))
		var hit_interval := float(runtime["hit_interval"][level]) * float(overrides.get("hit_interval_multiplier", 1.0))
		return damage * orbit_count / hit_interval
	var cooldown := float(runtime["cooldown"][level]) * float(overrides.get("cooldown_multiplier", 1.0))
	if ["star_lance", "ember_volley"].has(skill_id):
		var projectile_count := int(overrides.get("count", runtime["count"][level]))
		var pierce := int(overrides.get("pierce", runtime["pierce"][level]))
		return damage * projectile_count * (pierce + 1) / cooldown
	if skill_id == "meteor_rain":
		return damage * int(overrides.get("count", runtime["count"][level])) / cooldown
	return damage / cooldown


func _rng(seed_value: int) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	return random


func _close(left: float, right: float) -> bool:
	return absf(left - right) < 0.0001


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("RUN_BUILD_FAILED: " + message)
