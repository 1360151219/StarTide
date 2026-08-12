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
		print("BALANCE_OK experience=36+28 ultimate_budget=5 skill_levels=5 growth_cap=4.5 phoenix_hps=1.8 levels=%d data_driven=true" % LevelCatalog.all().size())
	quit(1 if failed else 0)


func _test_experience_curve() -> void:
	var state := RunState.new()
	_require(state.experience_needed == 36, "一级经验需求不是 36")
	state.add_experience(36)
	_require(state.player_level == 2 and state.experience_needed == 64, "经验需求没有按 36 + 28 × 等级差增长")


func _test_ultimate_upgrade_budget() -> void:
	var required_experience := 0
	for upgrade_index in range(5):
		required_experience += RunState.EXPERIENCE_BASE + upgrade_index * RunState.EXPERIENCE_STEP
	_require(LevelBalance.expected_experience_budget(LevelCatalog.first()) >= required_experience, "第一关经验预算不足以覆盖 V 级技能的五次候选窗口")


func _test_skill_growth_caps() -> void:
	for skill_id in HeroCatalog.SKILLS:
		var skill := HeroCatalog.skill(skill_id)
		var max_level := int(skill["max_level"])
		var base_output := _effective_skill_output(skill_id, 1)
		for branch_id in skill["branches"]:
			var overrides: Dictionary = skill["branches"][branch_id]["level_overrides"][max_level]
			var ultimate_output := _effective_skill_output(skill_id, max_level, overrides)
			_require(ultimate_output / base_output <= 4.5001, "%s/%s 终极输出超过一级的 4.5 倍" % [skill_id, branch_id])
			if skill_id == "phoenix_heart":
				var runtime: Dictionary = skill["runtime"]
				var trained_healing_rate := float(runtime["healing"][max_level]) * float(overrides.get("healing_multiplier", 1.0)) * 1.04 / (float(runtime["cooldown"][max_level]) * float(overrides.get("cooldown_multiplier", 1.0)) * 0.96)
				_require(trained_healing_rate <= 1.8001, "%s 终极训练后恢复超过 1.8 HP/秒" % branch_id)


func _effective_skill_output(skill_id: String, skill_level: int, overrides := {}) -> float:
	var data: Dictionary = HeroCatalog.skill(skill_id)["runtime"]
	var damage := float(data["damage"][skill_level]) * float(overrides.get("damage_multiplier", 1.0))
	match skill_id:
		"star_lance", "ember_volley":
			return damage * int(overrides.get("count", data["count"][skill_level])) * (int(overrides.get("pierce", data["pierce"][skill_level])) + 1) / (float(data["cooldown"][skill_level]) * float(overrides.get("cooldown_multiplier", 1.0)))
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
