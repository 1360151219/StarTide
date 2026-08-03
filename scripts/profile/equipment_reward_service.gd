extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const RewardCatalog = preload("res://scripts/profile/equipment_reward_catalog.gd")


static func apply(reward_id: String, equipment_inventory: RefCounted, granted_reward_ids: Dictionary) -> Dictionary:
	if reward_id.is_empty() or not RewardCatalog.REWARDS.has(reward_id):
		return _result(false, false, "未知装备奖励")
	var previously_granted := bool(granted_reward_ids.get(reward_id, false))
	var entries := RewardCatalog.reward(reward_id)
	for entry in entries:
		var instance_id := str(entry["instance_id"])
		var definition_id := str(entry["definition_id"])
		var rarity_id := str(entry["rarity"])
		var level := int(entry["level"])
		if not EquipmentCatalog.has(definition_id):
			return _result(false, false, "装备奖励配置无效")
		if equipment_inventory.items.has(instance_id):
			var item: Dictionary = equipment_inventory.items[instance_id]
			if str(item["definition_id"]) != definition_id or str(item["rarity"]) != rarity_id or int(item["level"]) != level:
				return _result(false, false, "装备奖励实例冲突")
	var granted_items: Array = []
	var item_names := PackedStringArray()
	var item_rows: Array[Dictionary] = []
	var repaired_missing := false
	for entry in entries:
		var instance_id := str(entry["instance_id"])
		var definition_id := str(entry["definition_id"])
		if not equipment_inventory.items.has(instance_id):
			equipment_inventory.grant(instance_id, definition_id, str(entry["rarity"]), int(entry["level"]))
			repaired_missing = true
		granted_items.append(instance_id)
		item_names.append(str(EquipmentCatalog.equipment(definition_id)["name"]))
		item_rows.append({
			"instance_id": instance_id,
			"definition_id": definition_id,
			"name": EquipmentCatalog.equipment(definition_id)["name"],
			"rarity": str(entry["rarity"]),
			"level": int(entry["level"]),
		})
	granted_reward_ids[reward_id] = true
	return {
		"success": true, "granted": not previously_granted, "repaired": previously_granted and repaired_missing,
		"reason": "装备奖励已修复" if previously_granted and repaired_missing else "装备奖励已领取",
		"items": granted_items, "item_names": item_names, "item_rows": item_rows,
	}


static func _result(success: bool, granted: bool, reason: String) -> Dictionary:
	return {"success": success, "granted": granted, "repaired": false, "reason": reason, "items": [], "item_names": PackedStringArray(), "item_rows": []}
