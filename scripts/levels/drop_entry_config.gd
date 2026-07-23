class_name DropEntryConfig
extends Resource

@export var pickup_id := ""
@export_range(0.0, 1.0, 0.001) var chance := 0.0
@export_range(0, 20, 1) var max_per_run := 0


func validation_errors(valid_pickup_ids: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	if pickup_id.is_empty():
		errors.append("道具 ID 不能为空")
	elif not valid_pickup_ids.has(pickup_id):
		errors.append("未知道具：%s" % pickup_id)
	elif pickup_id == "xp":
		errors.append("经验为必掉内容，不能加入额外掉落池")
	if chance <= 0.0:
		errors.append("%s 的掉落概率必须大于 0" % pickup_id)
	if max_per_run <= 0:
		errors.append("%s 的单局上限必须大于 0" % pickup_id)
	return errors
