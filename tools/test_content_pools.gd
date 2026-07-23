extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")

var failed := false


func _initialize() -> void:
	_require(LevelCatalog.validation_errors().is_empty(), "关卡或内容池配置校验失败")
	_expect_level_pool("level_01", ["green_grub", "slime"], ["xp", "heart"], 2, 2)
	_expect_level_pool("level_02", ["green_grub", "slime", "bat"], ["xp", "heart", "magnet", "haste_leaf"], 4, 4)
	_expect_level_pool("level_03", ["green_grub", "slime", "bat", "brute"], ["xp", "heart", "magnet", "haste_leaf", "star_bomb"], 6, 6)
	_require(LevelCatalog.debut_level_id("enemies", "green_grub") == "level_01", "张姐蛆首次出现关卡错误")
	_require(LevelCatalog.debut_level_id("enemies", "bat") == "level_02", "暮翼蝠首次出现关卡错误")
	_require(LevelCatalog.debut_level_id("enemies", "brute") == "level_03", "陨岩巨怪首次出现关卡错误")
	_require(LevelCatalog.debut_level_id("pickups", "haste_leaf") == "level_02", "疾风叶首次出现关卡错误")
	_require(LevelCatalog.debut_level_id("pickups", "star_bomb") == "level_03", "星爆糖首次出现关卡错误")
	_require(LevelCatalog.debut_level_id("skills", "sun_orbit") == "level_02", "日轮守卫首次出现关卡错误")
	_require(LevelCatalog.debut_level_id("skills", "frost_tide") == "level_03", "霜潮脉冲首次出现关卡错误")
	_require(LevelCatalog.debut_level_id("relics", "star_core") == "level_01", "星核扩容首次出现关卡错误")
	_require(LevelCatalog.debut_level_id("relics", "echo_lens") == "level_03", "回响透镜首次出现关卡错误")
	for level in LevelCatalog.all():
		for stage in level.stages:
			for weight in stage.enemy_weights.values():
				_require(float(weight) > 0.0, "%s 仍含零权重怪物占位" % level.level_id)
	if not failed:
		print("CONTENT_POOLS_OK enemies=progressive pickups=progressive skills=6 relics=6 zero_weights=false")
	quit(1 if failed else 0)


func _expect_level_pool(level_id: String, enemy_ids: Array, pickup_ids: Array, skill_count: int, relic_count: int) -> void:
	_require(_same_ids(LevelCatalog.level_content_ids(level_id, "enemies"), enemy_ids), "%s 怪物池错误" % level_id)
	_require(_same_ids(LevelCatalog.level_content_ids(level_id, "pickups"), pickup_ids), "%s 掉落池错误" % level_id)
	var pool := LevelCatalog.resolved_content_pool(level_id)
	_require(pool["skill_ids"].size() == skill_count, "%s 技能池累计数量错误" % level_id)
	_require(pool["relic_ids"].size() == relic_count, "%s 遗物池累计数量错误" % level_id)


func _same_ids(actual: PackedStringArray, expected: Array) -> bool:
	var actual_ids := Array(actual)
	actual_ids.sort()
	var expected_ids := expected.duplicate()
	expected_ids.sort()
	return actual_ids == expected_ids


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("CONTENT_POOLS_FAILED: " + message)
