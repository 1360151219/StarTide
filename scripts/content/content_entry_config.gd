class_name ContentEntryConfig
extends Resource

@export var content_id := ""
@export var data: Dictionary = {}


func validation_errors(required_fields := PackedStringArray()) -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty() or not content_id.is_valid_identifier() or content_id != content_id.to_snake_case():
		errors.append("内容 ID 必须是非空 snake_case 标识符")
	for field in required_fields:
		if not data.has(field):
			errors.append("%s 缺少字段 %s" % [content_id, field])
	return errors
