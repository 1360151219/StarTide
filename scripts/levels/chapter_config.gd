class_name ChapterConfig
extends Resource

@export var chapter_id := ""
@export var display_name := ""
@export var level_ids := PackedStringArray()
@export var default_difficulty_profile_id := ""


func validation_errors(valid_level_ids: PackedStringArray, valid_profile_ids: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	if chapter_id.is_empty():
		errors.append("章节 ID 不能为空")
	if display_name.is_empty():
		errors.append("章节名称不能为空")
	if level_ids.is_empty():
		errors.append("章节至少需要一个关卡")
	var seen_ids: Dictionary = {}
	for level_id in level_ids:
		if not valid_level_ids.has(level_id):
			errors.append("章节引用了未知关卡：%s" % level_id)
		elif seen_ids.has(level_id):
			errors.append("章节内关卡重复：%s" % level_id)
		seen_ids[level_id] = true
	if not valid_profile_ids.has(default_difficulty_profile_id):
		errors.append("章节引用了未知难度曲线：%s" % default_difficulty_profile_id)
	return errors
