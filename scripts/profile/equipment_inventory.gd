extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")

var hero_ids := PackedStringArray()
var items: Dictionary = {}
var loadouts: Dictionary = {}


func _init(valid_hero_ids := PackedStringArray(), raw_items := {}, raw_loadouts := {}) -> void:
	hero_ids = PackedStringArray(valid_hero_ids)
	_sanitize_items(raw_items)
	_sanitize_loadouts(raw_loadouts)


func snapshot() -> Dictionary:
	return {"items": items.duplicate(true), "loadouts": loadouts.duplicate(true)}


func inventory_rows() -> Array:
	var rows: Array = []
	var equipped := _equipped_owners()
	var instance_ids := PackedStringArray(items.keys())
	instance_ids.sort()
	for instance_id in instance_ids:
		var item: Dictionary = items[instance_id]
		var definition: Dictionary = EquipmentCatalog.equipment(item["definition_id"])
		var owner: Dictionary = equipped.get(instance_id, {})
		rows.append({
			"instance_id": instance_id,
			"definition_id": item["definition_id"],
			"name": definition["name"],
			"description": definition["description"],
			"icon": definition["icon"],
			"slot": definition["slot"],
			"rarity": item["rarity"],
			"level": item["level"],
			"max_level": EquipmentCatalog.max_level(item["rarity"]),
			"locked": item["locked"],
			"stats": EquipmentCatalog.resolved_stats(item["definition_id"], item["rarity"], item["level"]),
			"equipped_hero_id": str(owner.get("hero_id", "")),
			"equipped_slot": str(owner.get("slot", "")),
		})
	return rows


func loadout_snapshot(hero_id: String) -> Dictionary:
	return loadouts.get(hero_id, _empty_loadout()).duplicate(true)


func equipped_items(hero_id: String) -> Array:
	var result: Array = []
	var loadout := loadout_snapshot(hero_id)
	for slot_id in EquipmentCatalog.SLOTS:
		var instance_id := str(loadout.get(slot_id, ""))
		if instance_id.is_empty() or not items.has(instance_id):
			continue
		var item: Dictionary = items[instance_id]
		result.append({
			"instance_id": instance_id,
			"definition_id": item["definition_id"],
			"slot": slot_id,
			"rarity": item["rarity"],
			"level": item["level"],
			"stats": EquipmentCatalog.resolved_stats(item["definition_id"], item["rarity"], item["level"]),
		})
	return result


func grant(instance_id: String, definition_id: String, rarity_id := "", level := 1) -> Dictionary:
	if instance_id.is_empty() or items.has(instance_id):
		return _result(false, "装备实例 ID 无效或已存在")
	if not EquipmentCatalog.has(definition_id):
		return _result(false, "未知装备")
	var resolved_rarity := EquipmentCatalog.default_rarity(definition_id) if rarity_id.is_empty() else rarity_id
	if not EquipmentCatalog.RARITIES.has(resolved_rarity):
		return _result(false, "未知装备品质")
	items[instance_id] = {
		"definition_id": definition_id,
		"rarity": resolved_rarity,
		"level": clampi(int(level), 1, EquipmentCatalog.max_level(resolved_rarity)),
		"locked": false,
	}
	return _result(true, "装备已加入背包", {"instance_id": instance_id})


func equip(hero_id: String, instance_id: String) -> Dictionary:
	if not hero_ids.has(hero_id):
		return _result(false, "未知英雄")
	if not items.has(instance_id):
		return _result(false, "背包中不存在该装备")
	var owner: Dictionary = _equipped_owners().get(instance_id, {})
	if not owner.is_empty() and str(owner["hero_id"]) != hero_id:
		return _result(false, "该装备正由其他英雄使用")
	var item: Dictionary = items[instance_id]
	var slot_id := EquipmentCatalog.slot(item["definition_id"])
	if str(loadouts[hero_id].get(slot_id, "")) == instance_id:
		return _result(false, "该装备已穿戴")
	loadouts[hero_id][slot_id] = instance_id
	return _result(true, "装备已穿戴", {"slot": slot_id})


func unequip(hero_id: String, slot_id: String) -> Dictionary:
	if not hero_ids.has(hero_id):
		return _result(false, "未知英雄")
	if not EquipmentCatalog.SLOTS.has(slot_id):
		return _result(false, "未知装备槽")
	if str(loadouts[hero_id][slot_id]).is_empty():
		return _result(false, "该装备槽已经为空")
	loadouts[hero_id][slot_id] = ""
	return _result(true, "装备已卸下", {"slot": slot_id})


func upgrade(target_instance_id: String, material_instance_id: String) -> Dictionary:
	if target_instance_id == material_instance_id or not items.has(target_instance_id) or not items.has(material_instance_id):
		return _result(false, "升级装备或材料无效")
	var target: Dictionary = items[target_instance_id]
	var material: Dictionary = items[material_instance_id]
	if str(target["definition_id"]) != str(material["definition_id"]):
		return _result(false, "只能消耗同名装备")
	if bool(material["locked"]):
		return _result(false, "已锁定装备不能作为材料")
	if _equipped_owners().has(material_instance_id):
		return _result(false, "已穿戴装备不能作为材料")
	var maximum := EquipmentCatalog.max_level(str(target["rarity"]))
	if int(target["level"]) >= maximum:
		return _result(false, "装备已达到当前品质上限")
	target["level"] = int(target["level"]) + 1
	items[target_instance_id] = target
	items.erase(material_instance_id)
	return _result(true, "装备升级至 Lv.%d" % target["level"], {"instance_id": target_instance_id, "consumed_instance_id": material_instance_id, "level": target["level"]})


func set_locked(instance_id: String, locked: bool) -> Dictionary:
	if not items.has(instance_id):
		return _result(false, "背包中不存在该装备")
	items[instance_id]["locked"] = locked
	return _result(true, "装备已锁定" if locked else "装备已解锁", {"instance_id": instance_id, "locked": locked})


func _sanitize_items(raw_items) -> void:
	items.clear()
	if not raw_items is Dictionary:
		return
	for raw_instance_id in raw_items:
		var instance_id := str(raw_instance_id)
		var raw_item: Variant = raw_items[raw_instance_id]
		if instance_id.is_empty() or not raw_item is Dictionary:
			continue
		var definition_id := str(raw_item.get("definition_id", ""))
		if not EquipmentCatalog.has(definition_id):
			continue
		var rarity_id := str(raw_item.get("rarity", EquipmentCatalog.default_rarity(definition_id)))
		if not EquipmentCatalog.RARITIES.has(rarity_id):
			rarity_id = EquipmentCatalog.default_rarity(definition_id)
		var level := int(raw_item.get("level", int(raw_item.get("enhance_level", 0)) + 1))
		items[instance_id] = {
			"definition_id": definition_id,
			"rarity": rarity_id,
			"level": clampi(level, 1, EquipmentCatalog.max_level(rarity_id)),
			"locked": bool(raw_item.get("locked", false)),
		}


func _sanitize_loadouts(raw_loadouts) -> void:
	loadouts.clear()
	var claimed: Dictionary = {}
	for hero_id in hero_ids:
		loadouts[hero_id] = _empty_loadout()
		var raw_loadout: Variant = raw_loadouts.get(hero_id, {}) if raw_loadouts is Dictionary else {}
		if not raw_loadout is Dictionary:
			continue
		for slot_id in EquipmentCatalog.SLOTS:
			var instance_id := str(raw_loadout.get(slot_id, ""))
			if not items.has(instance_id) or claimed.has(instance_id):
				continue
			var item: Dictionary = items[instance_id]
			if EquipmentCatalog.slot(item["definition_id"]) != slot_id:
				continue
			loadouts[hero_id][slot_id] = instance_id
			claimed[instance_id] = true


func _equipped_owners() -> Dictionary:
	var result := {}
	for hero_id in hero_ids:
		for slot_id in EquipmentCatalog.SLOTS:
			var instance_id := str(loadouts[hero_id][slot_id])
			if not instance_id.is_empty():
				result[instance_id] = {"hero_id": hero_id, "slot": slot_id}
	return result


func _empty_loadout() -> Dictionary:
	var result := {}
	for slot_id in EquipmentCatalog.SLOTS:
		result[slot_id] = ""
	return result


func _result(success: bool, reason: String, extra := {}) -> Dictionary:
	var result := {"success": success, "reason": reason}
	result.merge(extra)
	return result
