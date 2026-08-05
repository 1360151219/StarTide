class_name EquipmentDropTableConfig
extends Resource

@export var table_id := ""
@export_range(1, 4, 1) var min_drops := 1
@export_range(1, 4, 1) var max_drops := 4
@export var equipment_entries: Array[WeightedContentEntryConfig] = []
@export var rarity_weights := {"common": 75.0, "rare": 20.0, "top": 5.0}
@export_range(1, 99, 1) var min_level := 1
@export_range(1, 99, 1) var max_level := 1


func validation_errors(valid_equipment_ids: PackedStringArray, valid_rarity_ids: PackedStringArray, equipment_tiers: Dictionary, content_tier: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if table_id.is_empty():
		errors.append("装备掉落表 ID 不能为空")
	if min_drops < 1 or max_drops > 4 or min_drops > max_drops:
		errors.append("每次胜利的装备掉落数量必须为 1 到 4 件")
	if min_level < 1 or max_level < min_level:
		errors.append("装备掉落等级区间无效")
	var seen_ids: Dictionary = {}
	for entry in equipment_entries:
		if entry == null:
			errors.append("装备掉落条目不能为空")
			continue
		for message in entry.validation_errors(valid_equipment_ids, "装备"):
			errors.append(message)
		if seen_ids.has(entry.content_id):
			errors.append("装备掉落条目重复：%s" % entry.content_id)
		if int(equipment_tiers.get(entry.content_id, 0)) > content_tier:
			errors.append("装备 %s 的内容阶级高于关卡阶级" % entry.content_id)
		seen_ids[entry.content_id] = true
	if equipment_entries.is_empty():
		errors.append("装备掉落表不能为空")
	var rarity_total := 0.0
	for rarity_id in rarity_weights:
		if not valid_rarity_ids.has(str(rarity_id)):
			errors.append("掉落表引用了未知品质：%s" % rarity_id)
		var weight := float(rarity_weights[rarity_id])
		if weight < 0.0:
			errors.append("品质权重不能为负数：%s" % rarity_id)
		rarity_total += weight
	if rarity_total <= 0.0:
		errors.append("品质权重总和必须大于 0")
	return errors
