extends RefCounted

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const LevelBalance = preload("res://scripts/levels/level_balance.gd")
const CampaignContentValidator = preload("res://scripts/levels/campaign_content_validator.gd")


static func validation_errors(manifest: CampaignManifest) -> PackedStringArray:
	var errors := manifest.validation_errors()
	var indexes := _indexes(manifest, errors)
	_validate_levels(manifest, indexes, errors)
	_validate_chapters(manifest, indexes, errors)
	_validate_difficulty_profiles(manifest, indexes, errors)
	for message in CampaignContentValidator.validation_errors(manifest, indexes["levels"]):
		errors.append(message)
	return errors


static func _indexes(manifest: CampaignManifest, errors: PackedStringArray) -> Dictionary:
	var result := {"levels": {}, "orders": {}, "maps": {}, "profiles": {}, "chapters": {}}
	for profile in manifest.difficulty_profiles:
		if profile == null:
			errors.append("难度曲线不能为空")
			continue
		if result["profiles"].has(profile.profile_id):
			errors.append("难度曲线 ID 重复：%s" % profile.profile_id)
		result["profiles"][profile.profile_id] = profile
		_append(errors, "难度曲线 %s" % profile.profile_id, profile.validation_errors())
	for chapter in manifest.chapters:
		if chapter == null:
			errors.append("章节不能为空")
			continue
		if result["chapters"].has(chapter.chapter_id):
			errors.append("章节 ID 重复：%s" % chapter.chapter_id)
		result["chapters"][chapter.chapter_id] = chapter
	for level in manifest.levels:
		if level == null:
			errors.append("关卡资源不能为空")
			continue
		if result["levels"].has(level.level_id):
			errors.append("关卡 ID 重复：%s" % level.level_id)
		if result["orders"].has(level.order):
			errors.append("关卡顺序重复：%d" % level.order)
		result["levels"][level.level_id] = level
		result["orders"][level.order] = level
	return result


static func _validate_levels(manifest: CampaignManifest, indexes: Dictionary, errors: PackedStringArray) -> void:
	var expected_order := 1
	var previous_content_tier := 0
	var previous_difficulty_rating := 0
	for level in manifest.levels:
		if level == null:
			continue
		_append(errors, level.resource_path, level.validation_errors(EnemyCatalog.ids(), EnemyAbilityCatalog.ids()))
		if level.order != expected_order:
			errors.append("关卡清单顺序必须连续，期望 %d，实际 %d" % [expected_order, level.order])
		expected_order += 1
		if level.content_tier < previous_content_tier:
			errors.append("%s 的内容阶级低于前一关" % level.level_id)
		if level.difficulty_rating < previous_difficulty_rating:
			errors.append("%s 的难度评级低于前一关" % level.level_id)
		previous_content_tier = level.content_tier
		previous_difficulty_rating = level.difficulty_rating
		if not indexes["chapters"].has(level.chapter_id):
			errors.append("%s 引用了未知章节：%s" % [level.level_id, level.chapter_id])
		if level.map != null:
			if indexes["maps"].has(level.map.map_id):
				errors.append("地图 ID 重复：%s" % level.map.map_id)
			indexes["maps"][level.map.map_id] = true


static func _validate_chapters(manifest: CampaignManifest, indexes: Dictionary, errors: PackedStringArray) -> void:
	var assigned_levels: Dictionary = {}
	var level_ids := PackedStringArray(indexes["levels"].keys())
	var profile_ids := PackedStringArray(indexes["profiles"].keys())
	for chapter in manifest.chapters:
		if chapter == null:
			continue
		_append(errors, "章节 %s" % chapter.chapter_id, chapter.validation_errors(level_ids, profile_ids))
		var previous_order := 0
		for level_id in chapter.level_ids:
			if assigned_levels.has(level_id):
				errors.append("关卡被多个章节引用：%s" % level_id)
			assigned_levels[level_id] = chapter.chapter_id
			if not indexes["levels"].has(level_id):
				continue
			var level: LevelConfig = indexes["levels"][level_id]
			if level.chapter_id != chapter.chapter_id:
				errors.append("%s 的章节字段与战役清单不一致" % level_id)
			if level.order <= previous_order:
				errors.append("章节 %s 的关卡顺序没有递增" % chapter.chapter_id)
			previous_order = level.order
	for level_id in indexes["levels"]:
		if not assigned_levels.has(level_id):
			errors.append("关卡未加入任何章节：%s" % level_id)


static func _validate_difficulty_profiles(manifest: CampaignManifest, indexes: Dictionary, errors: PackedStringArray) -> void:
	for chapter in manifest.chapters:
		if chapter == null:
			continue
		var base_pressures: Dictionary = {}
		for level_id in chapter.level_ids:
			var level: LevelConfig = indexes["levels"].get(level_id)
			if level == null or level.difficulty_step != 0:
				continue
			var profile_id := _profile_id(level, chapter)
			base_pressures[profile_id] = LevelBalance.level_pressure(level)
		var seen_steps: Dictionary = {}
		for level_id in chapter.level_ids:
			var level: LevelConfig = indexes["levels"].get(level_id)
			if level == null:
				continue
			var profile_id := _profile_id(level, chapter)
			var profile: DifficultyProfileConfig = indexes["profiles"].get(profile_id)
			if profile == null or level.difficulty_step >= profile.pressure_curve.size():
				errors.append("%s 的难度曲线或阶数无效" % level.level_id)
				continue
			var step_key := "%s:%d" % [profile_id, level.difficulty_step]
			if seen_steps.has(step_key):
				errors.append("难度曲线阶数重复：%s" % step_key)
			seen_steps[step_key] = true
			if level.recommended_power != profile.power_target(level.difficulty_step):
				errors.append("%s 推荐战力偏离难度曲线" % level.level_id)
			if not base_pressures.has(profile_id):
				errors.append("难度曲线 %s 缺少第 0 阶基准关卡" % profile_id)
				continue
			var actual_ratio := LevelBalance.level_pressure(level) / float(base_pressures[profile_id])
			var target_ratio := profile.pressure_target(level.difficulty_step)
			if absf(actual_ratio - target_ratio) > target_ratio * profile.pressure_tolerance:
				errors.append("%s 压力 %.3f 偏离目标 %.3f" % [level.level_id, actual_ratio, target_ratio])


static func _profile_id(level: LevelConfig, chapter: ChapterConfig) -> String:
	return level.difficulty_profile_id if not level.difficulty_profile_id.is_empty() else chapter.default_difficulty_profile_id


static func _append(target: PackedStringArray, prefix: String, source: PackedStringArray) -> void:
	for message in source:
		target.append("%s：%s" % [prefix, message])
