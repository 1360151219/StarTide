extends RefCounted
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const EquipmentDropService = preload("res://scripts/profile/equipment_drop_service.gd")
const EquipmentInventory = preload("res://scripts/profile/equipment_inventory.gd")
const EquipmentRewardService = preload("res://scripts/profile/equipment_reward_service.gd")
const HeroProgression = preload("res://scripts/profile/hero_progression.gd")
const HeroStatResolver = preload("res://scripts/profile/hero_stat_resolver.gd")
const LocalProfileRepository = preload("res://scripts/profile/local_profile_repository.gd")
const ProfileDefaults = preload("res://scripts/profile/profile_defaults.gd")
const ProfileSchema = preload("res://scripts/profile/profile_schema.gd")
const ContentDiscoveryService = preload("res://scripts/profile/content_discovery_service.gd")
const DEFAULT_PATH := "user://run_records.cfg"
const SCHEMA_VERSION := ProfileSchema.VERSION

static var pending_replay_hero_id := ""
static var pending_replay_level_id := ""

var hero_ids := HeroCatalog.ids()
var level_ids := LevelCatalog.ids()
var storage_path: String
var repository: RefCounted
var profile_id := ""
var revision := 0
var records: Dictionary = {}
var level_records: Dictionary = {}
var unlocked_levels: Dictionary = {}
var hero_progressions: Dictionary = {}
var equipment: RefCounted
var granted_reward_ids: Dictionary = {}
var discovery: RefCounted
var last_hero_id := ""
var active_hero_id := ""
var last_level_id := ""
var next_equipment_sequence := 1
var equipment_drop_rng := RandomNumberGenerator.new()
func _init(custom_path := DEFAULT_PATH, custom_repository: RefCounted = null) -> void:
	storage_path = custom_path
	repository = custom_repository if custom_repository != null else LocalProfileRepository.new(custom_path)
	equipment_drop_rng.randomize()
	_load()
func hero_record(hero_id: String) -> Dictionary:
	if not records.has(hero_id):
		records[hero_id] = ProfileDefaults.empty_record()
	return records[hero_id]
func level_record(level_id: String) -> Dictionary:
	if not level_records.has(level_id):
		level_records[level_id] = ProfileDefaults.empty_record()
	return level_records[level_id]
func progression_snapshot(hero_id: String) -> Dictionary:
	return get_permanent_snapshot(hero_id)
func get_active_hero_id() -> String:
	return active_hero_id
func set_active_hero(hero_id: String) -> bool:
	if not hero_ids.has(hero_id):
		return false
	active_hero_id = hero_id
	_save()
	return true
func get_permanent_snapshot(hero_id := "") -> Dictionary:
	var target_id := active_hero_id if hero_id.is_empty() else hero_id
	if not hero_progressions.has(target_id):
		return {}
	var progression := HeroProgression.snapshot(target_id, hero_progressions[target_id])
	return HeroStatResolver.resolve(target_id, progression, equipment)
func equipment_inventory_snapshot() -> Array:
	return equipment.inventory_rows()
func equipment_loadout_snapshot(hero_id: String) -> Dictionary:
	return equipment.loadout_snapshot(hero_id)
func grant_equipment(definition_id: String, rarity_id := "", level := 1) -> Dictionary:
	var result := EquipmentDropService.grant_one(equipment, next_equipment_sequence, definition_id, rarity_id, level)
	next_equipment_sequence = int(result.get("next_sequence", next_equipment_sequence))
	return _finish_equipment_command(result)
func equip_item(hero_id: String, instance_id: String) -> Dictionary:
	return _finish_equipment_command(equipment.equip(hero_id, instance_id), hero_id)
func unequip_item(hero_id: String, slot_id: String) -> Dictionary:
	return _finish_equipment_command(equipment.unequip(hero_id, slot_id), hero_id)
func upgrade_equipment(target_instance_id: String, material_instance_id: String) -> Dictionary:
	return _finish_equipment_command(equipment.upgrade(target_instance_id, material_instance_id))
func set_equipment_locked(instance_id: String, locked: bool) -> Dictionary:
	return _finish_equipment_command(equipment.set_locked(instance_id, locked))
func train_skill(hero_id: String, skill_id: String) -> Dictionary:
	if not hero_progressions.has(hero_id):
		return {"success": false, "reason": "未知英雄", "snapshot": {}}
	if not is_content_discovered("skills", skill_id):
		return {"success": false, "reason": "先在远征中发现该技能", "snapshot": progression_snapshot(hero_id)}
	var result := HeroProgression.train(hero_id, hero_progressions[hero_id], skill_id)
	hero_progressions[hero_id] = result["progress"]
	if result["success"]:
		_save()
	return {"success": result["success"], "reason": result["reason"], "snapshot": progression_snapshot(hero_id)}
func reset_skill_training(hero_id: String) -> Dictionary:
	if not hero_progressions.has(hero_id):
		return {"success": false, "reason": "未知英雄", "snapshot": {}}
	var result := HeroProgression.reset_training(hero_id, hero_progressions[hero_id])
	hero_progressions[hero_id] = result["progress"]
	if result["success"]:
		_save()
	return {"success": result["success"], "reason": result["reason"], "snapshot": progression_snapshot(hero_id)}
func is_level_unlocked(level_id: String) -> bool: return bool(unlocked_levels.get(level_id, false))
func has_cleared_level(level_id: String) -> bool: return int(level_records.get(level_id, {}).get("wins", 0)) > 0
func discover_content(category: String, content_id: String) -> bool:
	if not discovery.discover(category, content_id):
		return false
	_save()
	return true
func is_content_discovered(category: String, content_id: String) -> bool:
	return discovery.is_discovered(category, content_id)
func discovered_content_count(category: String) -> int:
	return discovery.count(category)
func discovered_content_ids(category: String) -> PackedStringArray:
	return discovery.ids(category)
func new_content_discoveries() -> Array[Dictionary]:
	return discovery.new_discoveries()
func clear_new_content_discoveries() -> void:
	discovery.clear_new_discoveries()
func record_level_run(hero_id: String, level: LevelConfig, won: bool, killed_elite: bool, kills: int, run_level: int, survival_seconds: float) -> Dictionary:
	var level_id := level.level_id
	var hero_result := _update_record(hero_record(hero_id), won, killed_elite, kills, run_level, survival_seconds)
	var target_level_record := level_record(level_id)
	var first_clear: bool = won and int(target_level_record["wins"]) == 0
	var level_result := _update_record(target_level_record, won, killed_elite, kills, run_level, survival_seconds)
	var newly_unlocked := ""
	if won and level.reward != null and not level.reward.unlock_level_id.is_empty() and not is_level_unlocked(level.reward.unlock_level_id):
		unlocked_levels[level.reward.unlock_level_id] = true
		newly_unlocked = level.reward.unlock_level_id
	var progression_reward := _award_progression(hero_id, won, survival_seconds)
	var equipment_reward := {}
	var fixed_reward := level.reward.first_clear_equipment_reward if level.reward != null else null
	if won and fixed_reward != null and not bool(granted_reward_ids.get(fixed_reward.reward_id, false)):
		equipment_reward = EquipmentRewardService.apply(fixed_reward, equipment, granted_reward_ids)
	var random_equipment_reward := _award_random_equipment(won, level.equipment_drop_table)
	last_hero_id = hero_id
	active_hero_id = hero_id
	last_level_id = level_id
	_save()
	return {
		"record": hero_result["record"],
		"level_record": level_result["record"],
		"new_record": hero_result["new_record"] or level_result["new_record"],
		"first_clear": first_clear,
		"newly_unlocked": newly_unlocked,
		"progression_reward": progression_reward,
		"equipment_reward": equipment_reward,
		"random_equipment_reward": random_equipment_reward,
	}
func summary(hero_id: String) -> String:
	var record := hero_record(hero_id)
	var progress := progression_snapshot(hero_id)
	if record["runs"] <= 0:
		return "LV.%d · 尚未出征 · 技能点 %d" % [progress["level"], progress["available_skill_points"]]
	return "LV.%d · 通关 %d · 精英 %d · 最高击败 %d" % [progress["level"], record["wins"], record["elite_kills"], record["best_kills"]]
func _award_progression(hero_id: String, won: bool, survival_seconds: float) -> Dictionary:
	if not hero_progressions.has(hero_id):
		return {}
	var award := HeroProgression.award_run(hero_id, hero_progressions[hero_id], won, survival_seconds)
	hero_progressions[hero_id] = award["progress"]
	return award["reward"]
func _award_random_equipment(won: bool, table: EquipmentDropTableConfig) -> Dictionary:
	if not won:
		return {}
	var reward := EquipmentDropService.apply(equipment, next_equipment_sequence, equipment_drop_rng, table)
	next_equipment_sequence = int(reward.get("next_sequence", next_equipment_sequence))
	return reward
func _finish_equipment_command(result: Dictionary, hero_id := "") -> Dictionary:
	if bool(result.get("success", false)):
		_save()
	result["snapshot"] = get_permanent_snapshot(hero_id)
	return result
func _update_record(record: Dictionary, won: bool, killed_elite: bool, kills: int, run_level: int, survival_seconds: float) -> Dictionary:
	var previous := [record["best_kills"], record["best_level"], record["best_survival_ms"]]
	record["runs"] += 1
	record["wins"] += int(won)
	record["elite_kills"] += int(killed_elite)
	record["best_kills"] = maxi(record["best_kills"], kills)
	record["best_level"] = maxi(record["best_level"], run_level)
	record["best_survival_ms"] = maxi(record["best_survival_ms"], roundi(survival_seconds * 1000.0))
	return {
		"record": record,
		"new_record": kills > previous[0] or run_level > previous[1] or roundi(survival_seconds * 1000.0) > previous[2],
	}
func _load() -> void:
	var profile: Dictionary = repository.load_profile(_default_profile())
	profile_id = str(profile.get("profile_id", ""))
	revision = maxi(0, int(profile.get("revision", 0)))
	records = profile["records"]
	level_records = profile["level_records"]
	unlocked_levels = profile["unlocked_levels"]
	hero_progressions = profile["hero_progressions"]
	var raw_equipment := {
		"items": profile.get("equipment_inventory", {}),
		"loadouts": profile.get("equipment_loadouts", {}),
	}
	equipment = EquipmentInventory.new(hero_ids, raw_equipment["items"], raw_equipment["loadouts"])
	granted_reward_ids = profile.get("granted_reward_ids", {}).duplicate(true)
	var starter_reward := EquipmentRewardService.apply(LevelCatalog.starter_equipment_reward(), equipment, granted_reward_ids)
	next_equipment_sequence = maxi(1, int(profile.get("next_equipment_sequence", 1)))
	discovery = ContentDiscoveryService.new(profile.get("discovered_content", {}))
	var needs_repair := int(profile.get("source_schema_version", SCHEMA_VERSION)) < SCHEMA_VERSION
	needs_repair = needs_repair or equipment.snapshot() != raw_equipment
	needs_repair = needs_repair or bool(starter_reward.get("granted", false)) or bool(starter_reward.get("repaired", false))
	for hero_id in hero_ids:
		var normalized: Dictionary = HeroProgression.sanitize(hero_id, hero_progressions[hero_id])
		needs_repair = needs_repair or normalized != hero_progressions[hero_id]
		hero_progressions[hero_id] = normalized
	last_hero_id = str(profile.get("last_hero_id", hero_ids[0]))
	active_hero_id = str(profile.get("active_hero_id", last_hero_id))
	last_level_id = str(profile.get("last_level_id", level_ids[0]))
	if not hero_ids.has(last_hero_id):
		last_hero_id = hero_ids[0]
	if not hero_ids.has(active_hero_id):
		active_hero_id = last_hero_id
	var unlocked_before := unlocked_levels.duplicate(true)
	unlocked_levels[level_ids[0]] = true
	for level in LevelCatalog.all():
		if int(level_records.get(level.level_id, {}).get("wins", 0)) > 0 and level.reward != null and not level.reward.unlock_level_id.is_empty():
			unlocked_levels[level.reward.unlock_level_id] = true
	needs_repair = needs_repair or unlocked_levels != unlocked_before
	if not level_ids.has(last_level_id) or not is_level_unlocked(last_level_id):
		last_level_id = level_ids[0]
	if needs_repair:
		_save()
func _save() -> void:
	var profile := _profile_data()
	if repository.save_profile(profile) == OK:
		profile_id = profile["profile_id"]
		revision = profile["revision"]
func _default_profile() -> Dictionary:
	return ProfileDefaults.build(hero_ids, level_ids)
func _profile_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION, "profile_id": profile_id, "revision": revision,
		"last_hero_id": last_hero_id, "active_hero_id": active_hero_id, "last_level_id": last_level_id,
		"records": records, "level_records": level_records, "unlocked_levels": unlocked_levels,
		"hero_progressions": hero_progressions, "discovered_content": discovery.snapshot(),
		"equipment_inventory": equipment.items, "equipment_loadouts": equipment.loadouts,
		"granted_reward_ids": granted_reward_ids,
		"next_equipment_sequence": next_equipment_sequence,
	}
