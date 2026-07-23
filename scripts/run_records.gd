extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const HeroProgression = preload("res://scripts/profile/hero_progression.gd")
const LocalProfileRepository = preload("res://scripts/profile/local_profile_repository.gd")
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
var discovery: RefCounted
var last_hero_id := ""
var last_level_id := ""


func _init(custom_path := DEFAULT_PATH, custom_repository: RefCounted = null) -> void:
	storage_path = custom_path
	repository = custom_repository if custom_repository != null else LocalProfileRepository.new(custom_path)
	_load()


func hero_record(hero_id: String) -> Dictionary:
	if not records.has(hero_id):
		records[hero_id] = _empty_record()
	return records[hero_id]


func level_record(level_id: String) -> Dictionary:
	if not level_records.has(level_id):
		level_records[level_id] = _empty_record()
	return level_records[level_id]


func progression_snapshot(hero_id: String) -> Dictionary:
	if not hero_progressions.has(hero_id):
		return {}
	return HeroProgression.snapshot(hero_id, hero_progressions[hero_id])


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


func is_level_unlocked(level_id: String) -> bool:
	return bool(unlocked_levels.get(level_id, false))


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


func record_run(hero_id: String, won: bool, killed_elite: bool, kills: int, run_level: int, survival_seconds: float) -> Dictionary:
	var result := _update_record(hero_record(hero_id), won, killed_elite, kills, run_level, survival_seconds)
	result["progression_reward"] = _award_progression(hero_id, won, survival_seconds)
	last_hero_id = hero_id
	_save()
	return result


func record_level_run(hero_id: String, level_id: String, won: bool, killed_elite: bool, kills: int, run_level: int, survival_seconds: float, reward: RewardConfig) -> Dictionary:
	var hero_result := _update_record(hero_record(hero_id), won, killed_elite, kills, run_level, survival_seconds)
	var target_level_record := level_record(level_id)
	var first_clear: bool = won and int(target_level_record["wins"]) == 0
	var level_result := _update_record(target_level_record, won, killed_elite, kills, run_level, survival_seconds)
	var newly_unlocked := ""
	if won and reward != null and not reward.unlock_level_id.is_empty() and not is_level_unlocked(reward.unlock_level_id):
		unlocked_levels[reward.unlock_level_id] = true
		newly_unlocked = reward.unlock_level_id
	var progression_reward := _award_progression(hero_id, won, survival_seconds)
	last_hero_id = hero_id
	last_level_id = level_id
	_save()
	return {
		"record": hero_result["record"],
		"level_record": level_result["record"],
		"new_record": hero_result["new_record"] or level_result["new_record"],
		"first_clear": first_clear,
		"newly_unlocked": newly_unlocked,
		"progression_reward": progression_reward,
	}


func summary(hero_id: String) -> String:
	var record := hero_record(hero_id)
	var progress := progression_snapshot(hero_id)
	if record["runs"] <= 0:
		return "Lv.%d · 尚未出征 · 技能点 %d" % [progress["level"], progress["available_skill_points"]]
	return "Lv.%d · 通关 %d · 精英 %d · 最高击败 %d" % [progress["level"], record["wins"], record["elite_kills"], record["best_kills"]]


func level_summary(level_id: String) -> String:
	if not is_level_unlocked(level_id):
		return "尚未解锁"
	var record := level_record(level_id)
	if record["runs"] <= 0:
		return "等待首次远征"
	return "通关 %d · 精英 %d · 最高击败 %d" % [record["wins"], record["elite_kills"], record["best_kills"]]


func _award_progression(hero_id: String, won: bool, survival_seconds: float) -> Dictionary:
	if not hero_progressions.has(hero_id):
		return {}
	var award := HeroProgression.award_run(hero_id, hero_progressions[hero_id], won, survival_seconds)
	hero_progressions[hero_id] = award["progress"]
	return award["reward"]


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
	discovery = ContentDiscoveryService.new(profile.get("discovered_content", {}))
	var needs_repair := int(profile.get("source_schema_version", SCHEMA_VERSION)) < SCHEMA_VERSION
	for hero_id in hero_ids:
		var normalized: Dictionary = HeroProgression.sanitize(hero_id, hero_progressions[hero_id])
		needs_repair = needs_repair or normalized != hero_progressions[hero_id]
		hero_progressions[hero_id] = normalized
	last_hero_id = str(profile.get("last_hero_id", hero_ids[0]))
	last_level_id = str(profile.get("last_level_id", level_ids[0]))
	if not hero_ids.has(last_hero_id):
		last_hero_id = hero_ids[0]
	unlocked_levels[level_ids[0]] = true
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
	var profile := {
		"schema_version": SCHEMA_VERSION, "profile_id": "", "revision": 0,
		"last_hero_id": hero_ids[0], "last_level_id": level_ids[0],
		"records": {}, "level_records": {}, "unlocked_levels": {}, "hero_progressions": {},
		"discovered_content": _empty_discovered_content(),
	}
	for hero_id in hero_ids:
		profile["records"][hero_id] = _empty_record()
		profile["hero_progressions"][hero_id] = HeroProgression.default_progress(hero_id)
	for level_id in level_ids:
		profile["level_records"][level_id] = _empty_record()
		profile["unlocked_levels"][level_id] = level_id == level_ids[0]
	return profile


func _profile_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION, "profile_id": profile_id, "revision": revision,
		"last_hero_id": last_hero_id, "last_level_id": last_level_id,
		"records": records, "level_records": level_records, "unlocked_levels": unlocked_levels,
		"hero_progressions": hero_progressions, "discovered_content": discovery.snapshot(),
	}


func _empty_record() -> Dictionary:
	return {"runs": 0, "wins": 0, "elite_kills": 0, "best_kills": 0, "best_level": 0, "best_survival_ms": 0}


func _empty_discovered_content() -> Dictionary:
	var result := {}
	for category in ProfileSchema.DISCOVERY_CATEGORIES:
		result[category] = {}
	return result
