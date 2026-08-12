extends SceneTree

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const EquipmentInventory = preload("res://scripts/profile/equipment_inventory.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const ProfileSchema = preload("res://scripts/profile/profile_schema.gd")
const RunRecords = preload("res://scripts/run_records.gd")

var failed := false
var cleanup_paths: Array[String] = []


func _initialize() -> void:
	_test_catalog_and_inventory_repair()
	_test_power_commands_and_persistence()
	_test_schema_four_migration()
	_test_missing_starter_repair()
	_test_first_clear_reward()
	_test_thousand_mile_windseal()
	for path in cleanup_paths:
		DirAccess.remove_absolute(path)
	if not failed:
		print("POWER_EQUIPMENT_OK schema=6 power_v1=frozen score_semantics=uncalibrated slots=3 commands=true migration=true active_hero=true")
	quit(1 if failed else 0)


func _test_catalog_and_inventory_repair() -> void:
	_require(EquipmentCatalog.validation_errors().is_empty(), "装备目录配置无效")
	_require(LevelCatalog.validation_errors().is_empty(), "战役装备奖励配置无效")
	_require(not EquipmentCatalog.ids().is_empty() and EquipmentCatalog.SLOTS.size() == 3 and EquipmentCatalog.RARITIES.size() == 3, "装备目录、槽位或品质配置错误")
	var items := {
		"shared": {"definition_id": "apprentice_starwand", "enhance_level": 99},
		"wrong_slot": {"definition_id": "meadow_guard", "enhance_level": -8},
		"unknown": {"definition_id": "not_real", "enhance_level": 0},
	}
	var loadouts := {
		"star_warden": {"weapon": "shared", "armor": "wrong_slot", "charm": ""},
		"ember_ranger": {"weapon": "shared", "armor": "", "charm": ""},
	}
	var inventory := EquipmentInventory.new(HeroCatalog.ids(), items, loadouts)
	_require(inventory.items.size() == 2, "未知装备实例没有被清除")
	_require(inventory.items["shared"]["rarity"] == "common" and inventory.items["shared"]["level"] == 5, "旧强化等级没有迁移到普通品质等级上限")
	_require(inventory.loadout_snapshot("star_warden")["weapon"] == "shared", "合法装配被错误清除")
	_require(inventory.loadout_snapshot("ember_ranger")["weapon"].is_empty(), "同一装备被重复装配")


func _test_power_commands_and_persistence() -> void:
	var path := _new_test_path("power_equipment")
	var records := RunRecords.new(path)
	var initial := records.get_permanent_snapshot("star_warden")
	_require(initial["hero_xp"] == 0 and initial["power"]["total"] == 1000, "初始等级或战力错误")
	_require(
		initial["power"]["formula_version"] == 1
		and initial["power"]["purpose"] == "progression_score"
		and not initial["power"]["calibrated"],
		"战力 v1 没有冻结为未校准养成评分"
	)
	_require(
		is_equal_approx(float(initial["resolved_stats"]["attack_power"]), 100.0)
		and is_equal_approx(float(initial["resolved_stats"]["skill_frequency"]), 1.0)
		and is_equal_approx(float(initial["resolved_stats"]["attack_power"]), 100.0 * float(initial["damage_multiplier"]))
		and is_equal_approx(float(initial["resolved_stats"]["skill_frequency"]), 1.0 / float(initial["resolved_stats"]["cooldown_multiplier"])),
		"初始攻击力或施法频率没有使用标准化实际值"
	)
	_require(initial["equipment"]["inventory"].size() == 3, "新档没有幂等发放三件新手装备")
	_require(records.set_active_hero("ember_ranger"), "合法英雄无法设为当前英雄")
	_require(not records.set_active_hero("missing"), "未知英雄被设为当前英雄")
	records.hero_progressions["star_warden"] = {
		"hero_xp": 900,
		"training": {"star_lance": 3, "sun_orbit": 2, "frost_tide": 0},
	}
	var trained := records.get_permanent_snapshot("star_warden")
	_require(trained["level"] == 10 and trained["power"]["level"] == 360, "等级战力错误")
	_require(trained["power"]["training"] == 151 and trained["power"]["total"] == 1511, "技能训练战力错误")
	var granted: Dictionary = records.grant_equipment("apprentice_starwand")
	var instance_id := str(granted.get("instance_id", ""))
	_require(granted["success"] and not instance_id.is_empty(), "装备发放失败")
	var equipped: Dictionary = records.equip_item("star_warden", instance_id)
	_require(equipped["success"] and equipped["snapshot"]["power"]["equipment"] == 100, "装备或装备战力计算错误")
	var expected_damage := 1.135 * 1.04 * 1.05
	var lance_damage: float = equipped["snapshot"]["skill_modifiers"]["star_lance"]["damage_multiplier"]
	_require(is_equal_approx(lance_damage, expected_damage), "装备没有进入永久技能属性快照")
	var expected_attack := 100.0 * 1.135 * 1.05
	var attack_breakdown: Dictionary = equipped["snapshot"]["stat_breakdown"]["attack_power"]
	_require(
		is_equal_approx(float(equipped["snapshot"]["resolved_stats"]["attack_power"]), expected_attack)
		and is_equal_approx(float(attack_breakdown["final"]), expected_attack)
		and is_equal_approx(float(attack_breakdown["level_multiplier"]), 1.135)
		and is_equal_approx(float(attack_breakdown["equipment_multiplier"]), 1.05),
		"攻击力实际值或来源拆分没有与现有伤害倍率保持等价"
	)
	_require(not records.equip_item("ember_ranger", instance_id)["success"], "同一装备可以跨英雄重复穿戴")
	var reloaded := RunRecords.new(path)
	_require(reloaded.get_active_hero_id() == "ember_ranger", "当前英雄没有持久化")
	var persisted := reloaded.get_permanent_snapshot("star_warden")
	_require(persisted["power"]["total"] == 1611, "装备、训练或战力没有持久化")
	_require(reloaded.unequip_item("star_warden", "weapon")["success"], "卸下装备失败")
	_require(reloaded.get_permanent_snapshot("star_warden")["power"]["total"] == 1511, "卸装后战力没有恢复")


func _test_schema_four_migration() -> void:
	var path := _new_test_path("schema4_power")
	var legacy := ConfigFile.new()
	legacy.set_value("meta", "schema_version", 4)
	legacy.set_value("meta", "profile_id", "schema-four")
	legacy.set_value("meta", "last_hero_id", "ember_ranger")
	legacy.set_value("progression/star_warden", "mastery_xp", 450)
	legacy.set_value("progression/star_warden", "training_star_lance", 2)
	legacy.save(path)
	var records := RunRecords.new(path)
	var snapshot := records.get_permanent_snapshot("star_warden")
	_require(snapshot["hero_xp"] == 450 and snapshot["level"] == 5, "schema 4 熟练度没有迁移为英雄经验")
	_require(snapshot["equipment"]["inventory"].size() == 3, "schema 4 迁移没有补发新手装备")
	_require(records.get_active_hero_id() == "ember_ranger", "旧档当前英雄没有回退到最近英雄")
	var migrated := ConfigFile.new()
	migrated.load(path)
	_require(int(migrated.get_value("meta", "schema_version", 0)) == ProfileSchema.VERSION, "旧档没有写回 schema 6")
	_require(int(migrated.get_value("progression/star_warden", "hero_xp", -1)) == 450, "新存档没有写入 hero_xp")
	_require(not migrated.has_section_key("progression/star_warden", "mastery_xp"), "新存档仍写入废弃 mastery_xp")
	var reloaded := RunRecords.new(path)
	_require(reloaded.equipment_inventory_snapshot().size() == 3, "重复加载导致新手装备重复发放")


func _test_missing_starter_repair() -> void:
	var path := _new_test_path("missing_starter_repair")
	var damaged := ConfigFile.new()
	damaged.set_value("meta", "schema_version", ProfileSchema.VERSION)
	damaged.set_value("meta", "profile_id", "missing-starter")
	damaged.set_value("rewards", "granted_ids", PackedStringArray([LevelCatalog.starter_equipment_reward().reward_id]))
	damaged.save(path)
	var repaired := RunRecords.new(path)
	_require(repaired.equipment_inventory_snapshot().size() == 3, "已领取标记存在时没有修复缺失的新手装备")
	var reloaded := RunRecords.new(path)
	_require(reloaded.equipment_inventory_snapshot().size() == 3, "新手装备修复没有持久化或发生重复")


func _test_first_clear_reward() -> void:
	var path := _new_test_path("first_clear_equipment")
	var records := RunRecords.new(path)
	records.equipment_drop_rng.seed = 3107
	var level := LevelCatalog.first()
	var first := records.record_level_run("star_warden", level, true, false, 1, 1, level.duration)
	_require(first["equipment_reward"]["granted"], "首次通关没有发放固定装备奖励")
	_require(first["equipment_reward"]["item_names"] == PackedStringArray(["风弦短弓"]), "首通装备名称没有进入结算数据")
	var first_drop_count := int(first["random_equipment_reward"]["count"])
	_require(first_drop_count >= 1 and first_drop_count <= 4, "首次通关没有保证掉落一到四件随机装备")
	_require(records.equipment_inventory_snapshot().size() == 4 + first_drop_count, "首通固定装备或随机装备没有进入背包")
	var repeated := records.record_level_run("star_warden", level, true, false, 1, 1, level.duration)
	var repeated_drop_count := int(repeated["random_equipment_reward"]["count"])
	_require(not repeated["first_clear"] and records.equipment_inventory_snapshot().size() == 4 + first_drop_count + repeated_drop_count, "重复通关没有只追加随机装备")
	var reloaded := RunRecords.new(path)
	_require(reloaded.equipment_inventory_snapshot().size() == 4 + first_drop_count + repeated_drop_count, "通关装备奖励没有持久化")
	var retry_path := _new_test_path("first_clear_equipment_retry")
	var retry_records := RunRecords.new(retry_path)
	retry_records.equipment.grant("clear-level-01-weapon", "meadow_guard")
	var conflicted := retry_records.record_level_run("star_warden", level, true, false, 1, 1, level.duration)
	_require(not conflicted["equipment_reward"]["success"], "冲突的首通装备实例没有阻止错误发放")
	retry_records.equipment.items.erase("clear-level-01-weapon")
	var recovered := retry_records.record_level_run("star_warden", level, true, false, 1, 1, level.duration)
	_require(not recovered["first_clear"] and recovered["equipment_reward"]["granted"], "首通装备失败后没有在后续通关自动补发")


func _test_thousand_mile_windseal() -> void:
	var level_one := EquipmentCatalog.resolved_stats("thousand_mile_windseal", "top", 1)
	var level_two := EquipmentCatalog.resolved_stats("thousand_mile_windseal", "top", 2)
	_require(is_equal_approx(float(level_one["move_speed_percent"]), 0.06) and is_equal_approx(float(level_one["cooldown_reduction"]), 0.04), "千里风印顶级基础属性不是移动速度 6% 与冷却缩减 4%")
	_require(is_equal_approx(float(level_two["move_speed_percent"]) - float(level_one["move_speed_percent"]), 0.004) and is_equal_approx(float(level_two["cooldown_reduction"]) - float(level_one["cooldown_reduction"]), 0.003), "千里风印每级成长不是移动速度 0.4% 与冷却缩减 0.3%")
	var reward := LevelCatalog.by_id("level_05").reward.first_clear_equipment_reward.entries[0]
	_require(reward.definition_id == "thousand_mile_windseal" and reward.rarity_id == "top", "第五关首通没有固定发放顶级千里风印")


func _new_test_path(label: String) -> String:
	var path := "user://%s_%d.cfg" % [label, OS.get_process_id()]
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute)
	cleanup_paths.append(absolute)
	return path


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("POWER_EQUIPMENT_FAILED: " + message)
