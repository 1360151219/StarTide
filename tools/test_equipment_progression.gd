extends SceneTree

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const EquipmentDropService = preload("res://scripts/profile/equipment_drop_service.gd")
const EquipmentInventory = preload("res://scripts/profile/equipment_inventory.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")

var failed := false


func _initialize() -> void:
	_test_quality_and_level_stats()
	_test_same_name_upgrade()
	_test_drop_quantity_and_quality_weights()
	if not failed:
		print("EQUIPMENT_PROGRESSION_OK drops=1-4 qualities=75/20/5 levels=5/10/15 upgrade=same_name")
	quit(1 if failed else 0)


func _test_quality_and_level_stats() -> void:
	_require(EquipmentCatalog.max_level("common") == 5, "普通品质等级上限错误")
	_require(EquipmentCatalog.max_level("rare") == 10, "稀有品质等级上限错误")
	_require(EquipmentCatalog.max_level("top") == 15, "顶级品质等级上限错误")
	_require(
		EquipmentCatalog.drop_weight("common") == 75
		and EquipmentCatalog.drop_weight("rare") == 20
		and EquipmentCatalog.drop_weight("top") == 5,
		"品质掉落权重错误"
	)
	var common_level_one := float(EquipmentCatalog.resolved_stats("apprentice_starwand", "common", 1)["damage_percent"])
	var rare_level_one := float(EquipmentCatalog.resolved_stats("apprentice_starwand", "rare", 1)["damage_percent"])
	var top_level_one := float(EquipmentCatalog.resolved_stats("apprentice_starwand", "top", 1)["damage_percent"])
	var common_level_five := float(EquipmentCatalog.resolved_stats("apprentice_starwand", "common", 5)["damage_percent"])
	_require(is_equal_approx(common_level_one, 0.05), "Lv.1 普通装备基础属性错误")
	_require(common_level_one < rare_level_one and rare_level_one < top_level_one, "品质没有提高同等级装备属性")
	_require(common_level_five > common_level_one, "升级没有逐级提高装备属性")


func _test_same_name_upgrade() -> void:
	var inventory := EquipmentInventory.new(HeroCatalog.ids())
	_require(inventory.grant("target", "apprentice_starwand", "top", 1)["success"], "升级目标发放失败")
	_require(inventory.grant("material", "apprentice_starwand", "common", 1)["success"], "同名材料发放失败")
	inventory.set_locked("material", true)
	_require(not inventory.upgrade("target", "material")["success"] and inventory.items.has("material"), "锁定材料仍被消耗")
	inventory.set_locked("material", false)
	inventory.equip("star_warden", "material")
	_require(not inventory.upgrade("target", "material")["success"] and inventory.items.has("material"), "穿戴中的材料仍被消耗")
	inventory.unequip("star_warden", "weapon")
	var upgraded := inventory.upgrade("target", "material")
	_require(upgraded["success"] and not inventory.items.has("material"), "合法同名材料没有被消耗")
	_require(inventory.items["target"]["rarity"] == "top" and inventory.items["target"]["level"] == 2, "升级错误改变品质或等级")
	inventory.grant("capped", "meadow_guard", "common", 5)
	inventory.grant("capped-material", "meadow_guard", "top", 1)
	_require(not inventory.upgrade("capped", "capped-material")["success"] and inventory.items.has("capped-material"), "满级装备仍消耗了材料")
	inventory.grant("wrong-material", "windstring_bow", "common", 1)
	_require(not inventory.upgrade("target", "wrong-material")["success"] and inventory.items.has("wrong-material"), "不同名称装备被当作升级材料")


func _test_drop_quantity_and_quality_weights() -> void:
	var count_rng := RandomNumberGenerator.new()
	count_rng.seed = 4831
	var seen_counts := {}
	for _index in range(512):
		var count := EquipmentDropService.roll_count(count_rng)
		_require(count >= 1 and count <= 4, "单次掉落数量超出一到四件")
		seen_counts[count] = true
	_require(seen_counts.size() == 4, "掉落数量没有覆盖一到四件")
	var rarity_rng := RandomNumberGenerator.new()
	rarity_rng.seed = 9217
	var rarity_counts := {"common": 0, "rare": 0, "top": 0}
	var sample_size := 20000
	for _index in range(sample_size):
		var rarity_id := EquipmentDropService.roll_rarity(rarity_rng)
		rarity_counts[rarity_id] += 1
	var common_rate := float(rarity_counts["common"]) / sample_size
	var rare_rate := float(rarity_counts["rare"]) / sample_size
	var top_rate := float(rarity_counts["top"]) / sample_size
	_require(common_rate > 0.72 and common_rate < 0.78, "普通品质实际掉率偏离 75%")
	_require(rare_rate > 0.17 and rare_rate < 0.23, "稀有品质实际掉率偏离 20%")
	_require(top_rate > 0.03 and top_rate < 0.07, "顶级品质实际掉率偏离 5%")
	var inventory := EquipmentInventory.new(HeroCatalog.ids())
	var apply_rng := RandomNumberGenerator.new()
	apply_rng.seed = 701
	var reward := EquipmentDropService.apply(inventory, 1, apply_rng)
	_require(reward["success"] and int(reward["count"]) >= 1 and int(reward["count"]) <= 4, "随机装备批量发放失败")
	_require(inventory.items.size() == int(reward["count"]), "随机掉落没有完整进入背包")
	for item in reward["items"]:
		var stored: Dictionary = inventory.items[item["instance_id"]]
		_require(int(stored["level"]) == 1 and str(stored["rarity"]) == str(item["rarity"]), "掉落实例没有保存初始等级与品质")


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("EQUIPMENT_PROGRESSION_FAILED: " + message)
