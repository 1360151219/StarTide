extends RefCounted

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")

var rows: Array = []
var loadout: Dictionary = {}


func consume(snapshot: Dictionary) -> void:
	var equipment: Dictionary = snapshot.get("equipment", {})
	rows = equipment.get("inventory", [])
	loadout = equipment.get("loadout", {})


func shown_rows(filter_id: String) -> Array:
	var shown := rows.filter(func(item): return filter_id == "all" or str(item.get("slot", "")) == filter_id)
	shown.sort_custom(_sort_items)
	return shown


func item(instance_id: String) -> Dictionary:
	for row in rows:
		if str(row.get("instance_id", "")) == instance_id:
			return row
	return {}


func equipped_item(slot_id: String) -> Dictionary:
	return item(str(loadout.get(slot_id, "")))


func owner_id(target: Dictionary) -> String:
	return str(target.get("equipped_hero_id", ""))


func owner_name(target: Dictionary) -> String:
	var target_hero_id := owner_id(target)
	return str(HeroCatalog.hero(target_hero_id).get("name", "")) if HeroCatalog.ids().has(target_hero_id) else ""


func upgrade_material(target_instance_id: String) -> Dictionary:
	var target := item(target_instance_id)
	if target.is_empty() or int(target.get("level", 1)) >= int(target.get("max_level", 1)):
		return {}
	var candidates := rows.filter(func(row):
		return str(row.get("instance_id", "")) != target_instance_id \
			and str(row.get("definition_id", "")) == str(target.get("definition_id", "")) \
			and not bool(row.get("locked", false)) and owner_id(row).is_empty()
	)
	candidates.sort_custom(_sort_materials)
	return candidates[0] if not candidates.is_empty() else {}


func _sort_items(left: Dictionary, right: Dictionary) -> bool:
	var rarity_delta := EquipmentCatalog.rarity_order(str(left.get("rarity", ""))) - EquipmentCatalog.rarity_order(str(right.get("rarity", "")))
	if rarity_delta != 0:
		return rarity_delta > 0
	var slot_delta := EquipmentCatalog.slot_order(str(left.get("slot", ""))) - EquipmentCatalog.slot_order(str(right.get("slot", "")))
	if slot_delta != 0:
		return slot_delta < 0
	var level_delta := int(left.get("level", 1)) - int(right.get("level", 1))
	return level_delta > 0 if level_delta != 0 else str(left.get("name", "")) < str(right.get("name", ""))


func _sort_materials(left: Dictionary, right: Dictionary) -> bool:
	var rarity_delta := EquipmentCatalog.rarity_order(str(left.get("rarity", ""))) - EquipmentCatalog.rarity_order(str(right.get("rarity", "")))
	if rarity_delta != 0:
		return rarity_delta < 0
	var level_delta := int(left.get("level", 1)) - int(right.get("level", 1))
	return level_delta < 0 if level_delta != 0 else str(left.get("instance_id", "")) < str(right.get("instance_id", ""))
