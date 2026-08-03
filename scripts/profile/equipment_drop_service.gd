extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const MIN_DROPS := 1
const MAX_DROPS := 4


static func apply(equipment_inventory: RefCounted, next_sequence: int, rng: RandomNumberGenerator) -> Dictionary:
	var count := roll_count(rng)
	var sequence := maxi(1, next_sequence)
	var dropped_items: Array = []
	var item_names := PackedStringArray()
	var rarity_counts := {}
	var definition_ids := EquipmentCatalog.ids()
	for _index in range(count):
		var definition_id := definition_ids[rng.randi_range(0, definition_ids.size() - 1)]
		var rarity_id := roll_rarity(rng)
		var grant_result := grant_one(equipment_inventory, sequence, definition_id, rarity_id, 1)
		sequence = int(grant_result.get("next_sequence", sequence))
		if not bool(grant_result.get("success", false)):
			return _result(false, dropped_items, item_names, rarity_counts, sequence, str(grant_result.get("reason", "随机装备发放失败")))
		var item := {
			"instance_id": grant_result["instance_id"],
			"definition_id": definition_id,
			"name": EquipmentCatalog.equipment(definition_id)["name"],
			"rarity": rarity_id,
			"rarity_name": EquipmentCatalog.rarity_name(rarity_id),
			"level": 1,
		}
		dropped_items.append(item)
		item_names.append(item["name"])
		rarity_counts[rarity_id] = int(rarity_counts.get(rarity_id, 0)) + 1
	return _result(true, dropped_items, item_names, rarity_counts, sequence, "获得 %d 件随机装备" % dropped_items.size())


static func grant_one(equipment_inventory: RefCounted, next_sequence: int, definition_id: String, rarity_id := "", level := 1) -> Dictionary:
	if not EquipmentCatalog.has(definition_id):
		return {"success": false, "reason": "未知装备", "next_sequence": next_sequence}
	var resolved_rarity := EquipmentCatalog.default_rarity(definition_id) if rarity_id.is_empty() else rarity_id
	if not EquipmentCatalog.RARITIES.has(resolved_rarity):
		return {"success": false, "reason": "未知装备品质", "next_sequence": next_sequence}
	var sequence := maxi(1, next_sequence)
	var instance_id := "eq-%06d" % sequence
	while equipment_inventory.items.has(instance_id):
		sequence += 1
		instance_id = "eq-%06d" % sequence
	var result: Dictionary = equipment_inventory.grant(instance_id, definition_id, resolved_rarity, level)
	result["next_sequence"] = sequence + 1 if result["success"] else sequence
	result["rarity"] = resolved_rarity
	result["level"] = clampi(level, 1, EquipmentCatalog.max_level(resolved_rarity))
	return result


static func roll_count(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(MIN_DROPS, MAX_DROPS)


static func roll_rarity(rng: RandomNumberGenerator) -> String:
	var total_weight := 0
	for rarity_id in EquipmentCatalog.RARITIES:
		total_weight += EquipmentCatalog.drop_weight(rarity_id)
	var roll := rng.randi_range(1, total_weight)
	var cursor := 0
	for rarity_id in EquipmentCatalog.RARITIES:
		cursor += EquipmentCatalog.drop_weight(rarity_id)
		if roll <= cursor:
			return rarity_id
	return EquipmentCatalog.RARITIES[-1]


static func _result(success: bool, items: Array, item_names: PackedStringArray, rarity_counts: Dictionary, next_sequence: int, reason: String) -> Dictionary:
	return {
		"success": success,
		"count": items.size(),
		"items": items,
		"item_names": item_names,
		"rarity_counts": rarity_counts,
		"next_sequence": next_sequence,
		"reason": reason,
	}
