class_name WeightedContentEntryConfig
extends Resource

@export var content_id := ""
@export_range(0.001, 1000.0, 0.001) var weight := 1.0
@export var guaranteed := false


func validation_errors(valid_ids: PackedStringArray, label: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("%s ID 不能为空" % label)
	elif not valid_ids.has(content_id):
		errors.append("未知%s：%s" % [label, content_id])
	if weight <= 0.0:
		errors.append("%s %s 的权重必须大于 0" % [label, content_id])
	return errors
