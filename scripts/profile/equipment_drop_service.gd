extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")


static func apply(equipment_inventory: RefCounted, next_sequence: int, rng: RandomNumberGenerator, table: EquipmentDropTableConfig) -> Dictionary:
	if table == null or table.equipment_entries.is_empty():
		return _result(false, [], PackedStringArray(), {}, next_sequence, "装备掉落表无效", "")
	var count := roll_count(rng, table)
	var sequence := maxi(1, next_sequence)
	var dropped_items: Array = []
	var item_names := PackedStringArray()
	var rarity_counts := {}
	for _index in range(count):
		var definition_id := roll_equipment_id(rng, table)
		var rarity_id := roll_rarity(rng, table)
		var item_level := roll_level(rng, table, rarity_id)
		var grant_result := grant_one(equipment_inventory, sequence, definition_id, rarity_id, item_level)
		sequence = int(grant_result.get("next_sequence", sequence))
		if not bool(grant_result.get("success", false)):
			return _result(false, dropped_items, item_names, rarity_counts, sequence, str(grant_result.get("reason", "随机装备发放失败")), table.table_id)
		var item := {
			"instance_id": grant_result["instance_id"],
			"definition_id": definition_id,
			"name": EquipmentCatalog.equipment(definition_id)["name"],
			"rarity": rarity_id,
			"rarity_name": EquipmentCatalog.rarity_name(rarity_id),
			"level": item_level,
		}
		dropped_items.append(item)
		item_names.append(item["name"])
		rarity_counts[rarity_id] = int(rarity_counts.get(rarity_id, 0)) + 1
	return _result(true, dropped_items, item_names, rarity_counts, sequence, "获得 %d 件随机装备" % dropped_items.size(), table.table_id)


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


static func roll_count(rng: RandomNumberGenerator, table: EquipmentDropTableConfig) -> int:
	return rng.randi_range(table.min_drops, table.max_drops)


static func roll_equipment_id(rng: RandomNumberGenerator, table: EquipmentDropTableConfig) -> String:
	var total_weight := 0.0
	for entry in table.equipment_entries:
		total_weight += entry.weight
	var roll := rng.randf() * total_weight
	var cursor := 0.0
	for entry in table.equipment_entries:
		cursor += entry.weight
		if roll < cursor:
			return entry.content_id
	return table.equipment_entries[-1].content_id


static func roll_rarity(rng: RandomNumberGenerator, table: EquipmentDropTableConfig) -> String:
	var total_weight := 0.0
	for rarity_id in EquipmentCatalog.RARITIES:
		total_weight += maxf(0.0, float(table.rarity_weights.get(rarity_id, 0.0)))
	var roll := rng.randf() * total_weight
	var cursor := 0.0
	for rarity_id in EquipmentCatalog.RARITIES:
		cursor += maxf(0.0, float(table.rarity_weights.get(rarity_id, 0.0)))
		if roll < cursor:
			return rarity_id
	return EquipmentCatalog.RARITIES[-1]


static func roll_level(rng: RandomNumberGenerator, table: EquipmentDropTableConfig, rarity_id: String) -> int:
	var maximum := mini(table.max_level, EquipmentCatalog.max_level(rarity_id))
	return rng.randi_range(mini(table.min_level, maximum), maximum)


static func _result(success: bool, items: Array, item_names: PackedStringArray, rarity_counts: Dictionary, next_sequence: int, reason: String, table_id: String) -> Dictionary:
	return {
		"success": success, "count": items.size(), "items": items,
		"item_names": item_names, "rarity_counts": rarity_counts,
		"next_sequence": next_sequence, "reason": reason, "drop_table_id": table_id,
	}
