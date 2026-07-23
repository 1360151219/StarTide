class_name LootConfig
extends Resource

const PickupCatalog = preload("res://scripts/pickup_catalog.gd")

@export_range(0.1, 3.0, 0.01) var experience_multiplier := 1.0
@export var bonus_entries: Array[DropEntryConfig] = []
@export var normal_pickup_radius := 92.0
@export var magnet_pickup_radius := 520.0


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if experience_multiplier <= 0.0:
		errors.append("经验倍率必须大于 0")
	var total_chance := 0.0
	var seen: Dictionary = {}
	for entry in bonus_entries:
		if entry == null:
			errors.append("掉落池条目不能为空")
			continue
		for message in entry.validation_errors(PickupCatalog.ids()):
			errors.append(message)
		if seen.has(entry.pickup_id):
			errors.append("掉落池道具重复：%s" % entry.pickup_id)
		seen[entry.pickup_id] = true
		total_chance += entry.chance
	if total_chance > 1.0:
		errors.append("额外掉落概率总和不能超过 1")
	if normal_pickup_radius <= 0.0 or magnet_pickup_radius < normal_pickup_radius:
		errors.append("拾取范围配置无效")
	return errors
