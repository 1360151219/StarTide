extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")

var failed := false


func _initialize() -> void:
	_require(LevelCatalog.validation_errors().is_empty(), "战役或内容池配置校验失败")
	var introduced_skills := PackedStringArray()
	var introduced_relics := PackedStringArray()
	var previous_tier := 0
	for level in LevelCatalog.all():
		_require(level.content_tier >= previous_tier, "%s 内容阶级发生倒退" % level.level_id)
		previous_tier = level.content_tier
		_validate_stage_entries(level)
		_validate_introductions(level, "skills", level.content_pool.introduced_skill_ids, introduced_skills)
		_validate_introductions(level, "relics", level.content_pool.introduced_relic_ids, introduced_relics)
		var pool := LevelCatalog.resolved_content_pool(level.level_id)
		_require(_contains_all(pool["introduced_skill_ids"], introduced_skills), "%s 技能首次出现继承链断裂" % level.level_id)
		_require(_contains_all(pool["introduced_relic_ids"], introduced_relics), "%s 遗物首次出现继承链断裂" % level.level_id)
		_require(pool["skill_entries"].size() >= mini(pool["skill_pool_limit"], 1), "%s 技能候选池为空" % level.level_id)
		_require(pool["relic_entries"].size() >= mini(pool["relic_pool_limit"], 1), "%s 遗物候选池为空" % level.level_id)
		_require(LevelCatalog.level_content_ids(level.level_id, "pickups").has("xp"), "%s 缺少经验掉落" % level.level_id)
	_require(_same_ids(introduced_skills, SkillCatalog.ids()), "仍有技能未声明首次出现关卡")
	_require(_same_ids(introduced_relics, RelicCatalog.ids()), "仍有遗物未声明首次出现关卡")
	if not failed:
		print("CONTENT_POOLS_OK levels=%d weighted=true limited=true debuts=data_driven" % LevelCatalog.all().size())
	quit(1 if failed else 0)


func _validate_stage_entries(level: LevelConfig) -> void:
	for stage in level.stages:
		var total := 0.0
		for entry in stage.enemy_entries:
			_require(entry.weight > 0.0, "%s/%s 含零权重怪物" % [level.level_id, stage.stage_id])
			_require(entry.max_active >= 0, "%s/%s 怪物上限无效" % [level.level_id, stage.stage_id])
			total += entry.weight
		_require(is_equal_approx(total, 1.0), "%s/%s 怪物权重总和不是 1" % [level.level_id, stage.stage_id])


func _validate_introductions(level: LevelConfig, category: String, ids: PackedStringArray, accumulated: PackedStringArray) -> void:
	for content_id in ids:
		_require(not accumulated.has(content_id), "%s 重复声明首次出现：%s" % [level.level_id, content_id])
		_require(LevelCatalog.debut_level_id(category, content_id) == level.level_id, "%s 首次出现关卡解析错误" % content_id)
		accumulated.append(content_id)


func _contains_all(actual: PackedStringArray, expected: PackedStringArray) -> bool:
	for content_id in expected:
		if not actual.has(content_id):
			return false
	return true


func _same_ids(actual: PackedStringArray, expected: PackedStringArray) -> bool:
	var actual_ids := Array(actual)
	var expected_ids := Array(expected)
	actual_ids.sort()
	expected_ids.sort()
	return actual_ids == expected_ids


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("CONTENT_POOLS_FAILED: " + message)
