extends SceneTree

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const LevelBalance = preload("res://scripts/levels/level_balance.gd")
const PickupCatalog = preload("res://scripts/pickup_catalog.gd")
const RunState = preload("res://scripts/run/run_state.gd")

var failed := false


func _initialize() -> void:
	_test_experience_curve()
	_test_ultimate_upgrade_budget()
	_test_skill_growth_caps()
	_test_healing_budget()
	_test_biomes()
	if not failed:
		print("BALANCE_OK experience=frontloaded_1332 ultimate_budget=6.5 skill_levels=5 reference_growth_cap=6.5 phoenix_hps=1.8 levels=%d data_driven=true" % LevelCatalog.all().size())
	quit(1 if failed else 0)


func _test_experience_curve() -> void:
	var expected := [24, 48, 76, 108, 144, 184, 220, 248, 280]
	var state := RunState.new()
	_require(RunState.EXPERIENCE_REQUIREMENTS == expected and state.experience_needed == 24, "前置经验梯度配置错误")
	var cumulative := 0
	for current_level in range(1, 10):
		_require(RunState.experience_required_for_level(current_level) == expected[current_level - 1], "%d 级经验需求错误" % current_level)
		cumulative += expected[current_level - 1]
	_require(cumulative == 1332, "到达 10 级的累计经验预算发生变化")
	state.add_experience(cumulative)
	_require(state.player_level == 10 and state.experience == 0 and state.experience_needed == 308, "经验无法正确跨级或延伸高等级梯度")


func _test_ultimate_upgrade_budget() -> void:
	var required_experience := 0
	for current_level in range(1, 6):
		required_experience += RunState.experience_required_for_level(current_level)
	_require(LevelBalance.expected_experience_budget(LevelCatalog.first()) >= required_experience, "第一关经验预算不足以覆盖 V 级技能的五次候选窗口")


func _test_skill_growth_caps() -> void:
	for skill_id in HeroCatalog.SKILLS:
		var skill := HeroCatalog.skill(skill_id)
		var max_level := int(skill["max_level"])
		var base_output := _effective_skill_output(skill_id, 1)
		for branch_id in skill["branches"]:
			var overrides: Dictionary = skill["branches"][branch_id]["level_overrides"][max_level]
			var ultimate_output := _effective_skill_output(skill_id, max_level, overrides)
			_require(ultimate_output / base_output <= 6.5001, "%s/%s 终极输出超过一级的 6.5 倍" % [skill_id, branch_id])
			if skill_id == "phoenix_heart":
				var runtime: Dictionary = skill["runtime"]
				var trained_healing_rate := float(runtime["healing"][max_level]) * float(overrides.get("healing_multiplier", 1.0)) * 1.04 / (float(runtime["cooldown"][max_level]) * float(overrides.get("cooldown_multiplier", 1.0)) * 0.96)
				_require(trained_healing_rate <= 1.8001, "%s 终极训练后恢复超过 1.8 HP/秒" % branch_id)


func _effective_skill_output(skill_id: String, skill_level: int, overrides := {}) -> float:
	var data: Dictionary = HeroCatalog.skill(skill_id)["runtime"]
	var damage := float(data["damage"][skill_level]) * float(overrides.get("damage_multiplier", 1.0))
	match skill_id:
		"star_lance", "ember_volley":
			var pierce := int(overrides.get("pierce", data["pierce"][skill_level]))
			var reference_targets := 2 if pierce < 0 else pierce + 1
			return damage * int(overrides.get("count", data["count"][skill_level])) * reference_targets / (float(data["cooldown"][skill_level]) * float(overrides.get("cooldown_multiplier", 1.0)))
		"sun_orbit":
			return damage * int(overrides.get("count", data["count"][skill_level])) / (float(data["hit_interval"][skill_level]) * float(overrides.get("hit_interval_multiplier", 1.0)))
		"meteor_rain":
			return damage * int(overrides.get("count", data["count"][skill_level])) / (float(data["cooldown"][skill_level]) * float(overrides.get("cooldown_multiplier", 1.0)))
		_:
			return damage / (float(data["cooldown"][skill_level]) * float(overrides.get("cooldown_multiplier", 1.0)))


func _test_healing_budget() -> void:
	var levels := LevelCatalog.all()
	var previous_budget := 0
	for index in range(levels.size()):
		var heart_entry: DropEntryConfig
		for entry in levels[index].loot.bonus_entries:
			if entry.pickup_id == "heart":
				heart_entry = entry
				break
		_require(heart_entry != null and heart_entry.max_per_run >= previous_budget, "%s 治疗心预算随关卡倒退" % levels[index].display_name)
		previous_budget = heart_entry.max_per_run
	_require(PickupCatalog.pickup("heart")["amount"] == 20.0, "治疗心效果没有由道具目录统一维护")


func _test_biomes() -> void:
	for level in LevelCatalog.all():
		_require(not level.map.biome_id.is_empty(), "%s 生态 ID 为空" % level.level_id)
		_require(level.map.floor_texture != null, "%s 生态缺少地面贴图" % level.level_id)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("BALANCE_FAILED: " + message)
