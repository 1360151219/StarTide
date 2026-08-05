extends SceneTree

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const PickupCatalog = preload("res://scripts/pickup_catalog.gd")
const RunState = preload("res://scripts/run/run_state.gd")

var failed := false


func _initialize() -> void:
	_test_experience_curve()
	_test_skill_growth_caps()
	_test_healing_budget()
	_test_biomes()
	if not failed:
		print("BALANCE_OK experience=36+28 growth_cap=4.5 phoenix_hps=1.8 levels=%d data_driven=true" % LevelCatalog.all().size())
	quit(1 if failed else 0)


func _test_experience_curve() -> void:
	var state := RunState.new()
	_require(state.experience_needed == 36, "一级经验需求不是 36")
	state.add_experience(36)
	_require(state.player_level == 2 and state.experience_needed == 64, "经验需求没有按 36 + 28 × 等级差增长")


func _test_skill_growth_caps() -> void:
	for skill_id in HeroCatalog.SKILLS:
		var base_output := _effective_skill_output(skill_id, 1)
		var ultimate_output := _effective_skill_output(skill_id, 3)
		_require(ultimate_output / base_output <= 4.5001, "%s 终极输出超过一级的 4.5 倍" % skill_id)
	var phoenix: Dictionary = HeroCatalog.skill("phoenix_heart")["runtime"]
	var trained_healing_rate: float = phoenix["healing"][3] * 1.04 / (phoenix["cooldown"][3] * 0.96)
	_require(trained_healing_rate <= 1.8001, "凤凰之心终极训练后恢复超过 1.8 HP/秒")


func _effective_skill_output(skill_id: String, skill_level: int) -> float:
	var data: Dictionary = HeroCatalog.skill(skill_id)["runtime"]
	match skill_id:
		"star_lance", "ember_volley":
			return data["damage"][skill_level] * data["count"][skill_level] * (data["pierce"][skill_level] + 1) / data["cooldown"][skill_level]
		"sun_orbit":
			return data["damage"][skill_level] * data["count"][skill_level] / data["hit_interval"][skill_level]
		"meteor_rain":
			return data["damage"][skill_level] * data["count"][skill_level] / data["cooldown"][skill_level]
		_:
			return data["damage"][skill_level] / data["cooldown"][skill_level]


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
