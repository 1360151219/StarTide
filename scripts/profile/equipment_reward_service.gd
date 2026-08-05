extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")


static func apply(reward: EquipmentRewardConfig, equipment_inventory: RefCounted, granted_reward_ids: Dictionary) -> Dictionary:
	if reward == null or reward.reward_id.is_empty() or reward.entries.is_empty():
		return _result(false, false, "未知装备奖励")
	var previously_granted := bool(granted_reward_ids.get(reward.reward_id, false))
	for entry in reward.entries:
		if entry == null or not EquipmentCatalog.has(entry.definition_id):
			return _result(false, false, "装备奖励配置无效")
		if equipment_inventory.items.has(entry.instance_id):
			var item: Dictionary = equipment_inventory.items[entry.instance_id]
			if str(item["definition_id"]) != entry.definition_id or str(item["rarity"]) != entry.rarity_id or int(item["level"]) != entry.level:
				return _result(false, false, "装备奖励实例冲突")
	var granted_items: Array = []
	var item_names := PackedStringArray()
	var item_rows: Array[Dictionary] = []
	var repaired_missing := false
	for entry in reward.entries:
		if not equipment_inventory.items.has(entry.instance_id):
			equipment_inventory.grant(entry.instance_id, entry.definition_id, entry.rarity_id, entry.level)
			repaired_missing = true
		granted_items.append(entry.instance_id)
		item_names.append(str(EquipmentCatalog.equipment(entry.definition_id)["name"]))
		item_rows.append({
			"instance_id": entry.instance_id,
			"definition_id": entry.definition_id,
			"name": EquipmentCatalog.equipment(entry.definition_id)["name"],
			"rarity": entry.rarity_id,
			"level": entry.level,
		})
	granted_reward_ids[reward.reward_id] = true
	return {
		"success": true, "granted": not previously_granted,
		"repaired": previously_granted and repaired_missing,
		"reason": "装备奖励已修复" if previously_granted and repaired_missing else "装备奖励已领取",
		"items": granted_items, "item_names": item_names, "item_rows": item_rows,
	}


static func _result(success: bool, granted: bool, reason: String) -> Dictionary:
	return {
		"success": success, "granted": granted, "repaired": false,
		"reason": reason, "items": [], "item_names": PackedStringArray(), "item_rows": [],
	}
