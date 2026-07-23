class_name LevelPresentationManifest
extends Resource

@export var entries: Array[LevelPresentationConfig] = []


func all() -> Array[LevelPresentationConfig]:
	return entries.duplicate()


func by_id(level_id: String) -> LevelPresentationConfig:
	for entry in entries:
		if entry != null and entry.level_id == level_id:
			return entry
	return null


func validation_errors(valid_level_ids: PackedStringArray, valid_enemy_ids: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}
	for entry in entries:
		if entry == null:
			errors.append("关卡展示配置不能为空")
			continue
		for message in entry.validation_errors(valid_level_ids, valid_enemy_ids):
			errors.append("%s：%s" % [entry.level_id, message])
		if seen_ids.has(entry.level_id):
			errors.append("关卡展示 ID 重复：%s" % entry.level_id)
		seen_ids[entry.level_id] = true
	for level_id in valid_level_ids:
		if not seen_ids.has(level_id):
			errors.append("关卡缺少展示配置：%s" % level_id)
	return errors
