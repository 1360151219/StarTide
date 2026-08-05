extends SceneTree

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const EquipmentDropService = preload("res://scripts/profile/equipment_drop_service.gd")
const EquipmentInventory = preload("res://scripts/profile/equipment_inventory.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")

var failed := false


func _initialize() -> void:
	_test_quality_and_level_stats()
	_test_same_name_upgrade()
	_test_level_drop_tables()
	if not failed:
		print("EQUIPMENT_PROGRESSION_OK levels=%d drops=1-4 tiered=true quality_curves=true" % LevelCatalog.all().size())
	quit(1 if failed else 0)


func _test_quality_and_level_stats() -> void:
	_require(EquipmentCatalog.max_level("common") == 5, "普通品质等级上限错误")
	_require(EquipmentCatalog.max_level("rare") == 10, "稀有品质等级上限错误")
	_require(EquipmentCatalog.max_level("top") == 15, "顶级品质等级上限错误")
	var common_level_one := float(EquipmentCatalog.resolved_stats("apprentice_starwand", "common", 1)["damage_percent"])
	var rare_level_one := float(EquipmentCatalog.resolved_stats("apprentice_starwand", "rare", 1)["damage_percent"])
	var top_level_one := float(EquipmentCatalog.resolved_stats("apprentice_starwand", "top", 1)["damage_percent"])
	var common_level_five := float(EquipmentCatalog.resolved_stats("apprentice_starwand", "common", 5)["damage_percent"])
	_require(common_level_one < rare_level_one and rare_level_one < top_level_one, "品质没有提高同等级装备属性")
	_require(common_level_five > common_level_one, "升级没有逐级提高装备属性")
	for equipment_id in EquipmentCatalog.ids():
		_require(EquipmentCatalog.content_tier(equipment_id) >= 1, "%s 内容阶级无效" % equipment_id)


func _test_same_name_upgrade() -> void:
	var inventory := EquipmentInventory.new(HeroCatalog.ids())
	_require(inventory.grant("target", "apprentice_starwand", "top", 1)["success"], "升级目标发放失败")
	_require(inventory.grant("material", "apprentice_starwand", "common", 1)["success"], "同名材料发放失败")
	inventory.set_locked("material", true)
	_require(not inventory.upgrade("target", "material")["success"], "锁定材料仍被消耗")
	inventory.set_locked("material", false)
	inventory.equip("star_warden", "material")
	_require(not inventory.upgrade("target", "material")["success"], "穿戴中的材料仍被消耗")
	inventory.unequip("star_warden", "weapon")
	_require(inventory.upgrade("target", "material")["success"], "合法同名材料没有被消耗")
	_require(inventory.items["target"]["level"] == 2, "升级没有提高装备等级")


func _test_level_drop_tables() -> void:
	var previous_quality_shares: Dictionary = {}
	for level in LevelCatalog.all():
		var table := level.equipment_drop_table
		_require(table.min_drops >= 1 and table.max_drops <= 4, "%s 掉落数量不是 1 到 4" % level.level_id)
		var total_weight := 0.0
		for rarity_id in EquipmentCatalog.RARITIES:
			total_weight += float(table.rarity_weights.get(rarity_id, 0.0))
		for rarity_id in EquipmentCatalog.RARITIES:
			if EquipmentCatalog.rarity_order(rarity_id) <= 0:
				continue
			var share := float(table.rarity_weights.get(rarity_id, 0.0)) / total_weight
			_require(share + 0.000001 >= float(previous_quality_shares.get(rarity_id, 0.0)), "%s 的 %s 品质掉落占比倒退" % [level.level_id, rarity_id])
			previous_quality_shares[rarity_id] = share
		_test_table_distribution(level)
		_test_table_apply(level)


func _test_table_distribution(level: LevelConfig) -> void:
	var table := level.equipment_drop_table
	var rng := RandomNumberGenerator.new()
	rng.seed = level.order * 9217
	var samples := 20000
	var counts := {"common": 0, "rare": 0, "top": 0}
	var expected_total := 0.0
	for rarity_id in EquipmentCatalog.RARITIES:
		expected_total += float(table.rarity_weights.get(rarity_id, 0.0))
	for _index in range(samples):
		counts[EquipmentDropService.roll_rarity(rng, table)] += 1
	for rarity_id in EquipmentCatalog.RARITIES:
		var actual := float(counts[rarity_id]) / samples
		var expected := float(table.rarity_weights.get(rarity_id, 0.0)) / expected_total
		_require(absf(actual - expected) < 0.02, "%s 的 %s 实际掉率偏离配置" % [level.level_id, rarity_id])


func _test_table_apply(level: LevelConfig) -> void:
	var inventory := EquipmentInventory.new(HeroCatalog.ids())
	var rng := RandomNumberGenerator.new()
	rng.seed = level.order * 701
	var reward := EquipmentDropService.apply(inventory, 1, rng, level.equipment_drop_table)
	_require(reward["success"] and int(reward["count"]) >= 1 and int(reward["count"]) <= 4, "%s 随机装备批量发放失败" % level.level_id)
	_require(reward["drop_table_id"] == level.equipment_drop_table.table_id, "%s 结算没有记录掉落表来源" % level.level_id)
	var allowed_ids := PackedStringArray()
	for entry in level.equipment_drop_table.equipment_entries:
		allowed_ids.append(entry.content_id)
	for item in reward["items"]:
		_require(allowed_ids.has(item["definition_id"]), "%s 掉出了池外装备" % level.level_id)
		_require(EquipmentCatalog.content_tier(item["definition_id"]) <= level.content_tier, "%s 掉出了未来阶级装备" % level.level_id)
		_require(item["level"] >= level.equipment_drop_table.min_level and item["level"] <= level.equipment_drop_table.max_level, "%s 装备等级越界" % level.level_id)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("EQUIPMENT_PROGRESSION_FAILED: " + message)
