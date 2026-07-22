extends SceneTree

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunState = preload("res://scripts/run/run_state.gd")

var failed := false


func _initialize() -> void:
	_test_experience_curve()
	_test_skill_growth_caps()
	_test_healing_budget()
	_test_biomes()
	if not failed:
		print("BALANCE_OK experience=36+28 growth_cap=4.5 phoenix_hps=1.8 hearts=5/6/7 biomes=3")
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
	for index in range(levels.size()):
		_require(levels[index].loot.max_heart_drops == 5 + index, "%s 治疗心预算错误" % levels[index].display_name)
		_require(levels[index].loot.heart_value == 20 - index * 2, "%s 单个治疗心数值错误" % levels[index].display_name)


func _test_biomes() -> void:
	var expected := ["windbell_meadow", "golden_oasis", "crystal_volcano"]
	for index in range(expected.size()):
		_require(LevelCatalog.all()[index].map.biome_id == expected[index], "第 %d 关生态 ID 错误" % (index + 1))


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("BALANCE_FAILED: " + message)
