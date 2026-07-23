class_name LevelContentPoolConfig
extends Resource

@export var inherit_from_level_id := ""
@export var added_skill_ids := PackedStringArray()
@export var added_relic_ids := PackedStringArray()


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	_validate_unique_nonempty(errors, added_skill_ids, "技能")
	_validate_unique_nonempty(errors, added_relic_ids, "遗物")
	return errors


func _validate_unique_nonempty(errors: PackedStringArray, ids: PackedStringArray, label: String) -> void:
	var seen: Dictionary = {}
	for content_id in ids:
		if content_id.is_empty():
			errors.append("%s ID 不能为空" % label)
		elif seen.has(content_id):
			errors.append("%s ID 重复：%s" % [label, content_id])
		seen[content_id] = true
