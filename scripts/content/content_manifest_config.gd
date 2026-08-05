class_name ContentManifestConfig
extends Resource

@export var catalog_id := ""
@export var entries: Array[ContentEntryConfig] = []


func as_dictionary() -> Dictionary:
	var result: Dictionary = {}
	for entry in entries:
		if entry != null and not entry.content_id.is_empty():
			result[entry.content_id] = entry.data
	return result


func validation_errors(required_fields := PackedStringArray()) -> PackedStringArray:
	var errors := PackedStringArray()
	if catalog_id.is_empty():
		errors.append("内容目录 ID 不能为空")
	var seen_ids: Dictionary = {}
	for entry in entries:
		if entry == null:
			errors.append("内容目录条目不能为空")
			continue
		for message in entry.validation_errors(required_fields):
			errors.append(message)
		if seen_ids.has(entry.content_id):
			errors.append("内容 ID 重复：%s" % entry.content_id)
		seen_ids[entry.content_id] = true
	return errors
