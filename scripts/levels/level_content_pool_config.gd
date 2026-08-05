class_name LevelContentPoolConfig
extends Resource

@export var inherit_from_level_id := ""
@export var introduced_skill_ids := PackedStringArray()
@export var introduced_relic_ids := PackedStringArray()
@export var skill_entries: Array[WeightedContentEntryConfig] = []
@export var relic_entries: Array[WeightedContentEntryConfig] = []
@export_range(1, 12, 1) var skill_pool_limit := 6
@export_range(1, 12, 1) var relic_pool_limit := 4
@export_range(0, 8, 1) var discovered_skill_slots := 1
@export_range(0, 8, 1) var discovered_relic_slots := 1
@export_range(0.001, 1000.0, 0.001) var discovered_content_weight := 0.35


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	_validate_unique_nonempty(errors, introduced_skill_ids, "首次出现技能")
	_validate_unique_nonempty(errors, introduced_relic_ids, "首次出现遗物")
	_validate_entries(errors, skill_entries, skill_pool_limit, "技能")
	_validate_entries(errors, relic_entries, relic_pool_limit, "遗物")
	if discovered_content_weight <= 0.0:
		errors.append("已发现内容权重必须大于 0")
	return errors


func _validate_unique_nonempty(errors: PackedStringArray, ids: PackedStringArray, label: String) -> void:
	var seen: Dictionary = {}
	for content_id in ids:
		if content_id.is_empty():
			errors.append("%s ID 不能为空" % label)
		elif seen.has(content_id):
			errors.append("%s ID 重复：%s" % [label, content_id])
		seen[content_id] = true


func _validate_entries(errors: PackedStringArray, entries: Array[WeightedContentEntryConfig], limit: int, label: String) -> void:
	var seen: Dictionary = {}
	var guaranteed_count := 0
	for entry in entries:
		if entry == null:
			errors.append("%s候选条目不能为空" % label)
			continue
		if entry.content_id.is_empty():
			errors.append("%s候选 ID 不能为空" % label)
		elif seen.has(entry.content_id):
			errors.append("%s候选重复：%s" % [label, entry.content_id])
		if entry.weight <= 0.0:
			errors.append("%s候选权重必须大于 0：%s" % [label, entry.content_id])
		seen[entry.content_id] = true
		guaranteed_count += int(entry.guaranteed)
	if label == "遗物" and guaranteed_count > limit:
		errors.append("%s保底条目数量超过候选池上限" % label)
