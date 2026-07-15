extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const DEFAULT_PATH := "user://run_records.cfg"
const SCHEMA_VERSION := 2

static var pending_replay_hero_id := ""
static var pending_replay_level_id := ""

var hero_ids := HeroCatalog.ids()
var level_ids := LevelCatalog.ids()
var storage_path: String
var records: Dictionary = {}
var level_records: Dictionary = {}
var unlocked_levels: Dictionary = {}
var last_hero_id := ""
var last_level_id := ""


func _init(custom_path := DEFAULT_PATH) -> void:
	storage_path = custom_path
	last_hero_id = hero_ids[0]
	last_level_id = level_ids[0]
	_load()


func hero_record(hero_id: String) -> Dictionary:
	if not records.has(hero_id):
		records[hero_id] = _empty_record()
	return records[hero_id]


func level_record(level_id: String) -> Dictionary:
	if not level_records.has(level_id):
		level_records[level_id] = _empty_level_record()
	return level_records[level_id]


func is_level_unlocked(level_id: String) -> bool:
	return bool(unlocked_levels.get(level_id, false))


func record_run(hero_id: String, won: bool, killed_elite: bool, kills: int, run_level: int, survival_seconds: float) -> Dictionary:
	var result := _update_record(hero_record(hero_id), won, killed_elite, kills, run_level, survival_seconds)
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
	last_hero_id = hero_id
	last_level_id = level_id
	_save()
	return {
		"record": hero_result["record"],
		"level_record": level_result["record"],
		"new_record": hero_result["new_record"] or level_result["new_record"],
		"first_clear": first_clear,
		"newly_unlocked": newly_unlocked,
	}


func summary(hero_id: String) -> String:
	var record := hero_record(hero_id)
	if record["runs"] <= 0:
		return "尚未出征"
	return "通关 %d · 精英 %d · 最高击败 %d" % [record["wins"], record["elite_kills"], record["best_kills"]]


func level_summary(level_id: String) -> String:
	if not is_level_unlocked(level_id):
		return "尚未解锁"
	var record := level_record(level_id)
	if record["runs"] <= 0:
		return "等待首次远征"
	return "通关 %d · 精英 %d · 最高击败 %d" % [record["wins"], record["elite_kills"], record["best_kills"]]


func _update_record(record: Dictionary, won: bool, killed_elite: bool, kills: int, run_level: int, survival_seconds: float) -> Dictionary:
	var previous_best_kills: int = record["best_kills"]
	var previous_best_level: int = record["best_level"]
	var previous_best_survival: int = record["best_survival_ms"]
	record["runs"] += 1
	record["wins"] += int(won)
	record["elite_kills"] += int(killed_elite)
	record["best_kills"] = maxi(record["best_kills"], kills)
	record["best_level"] = maxi(record["best_level"], run_level)
	record["best_survival_ms"] = maxi(record["best_survival_ms"], roundi(survival_seconds * 1000.0))
	return {
		"record": record,
		"new_record": kills > previous_best_kills or run_level > previous_best_level or roundi(survival_seconds * 1000.0) > previous_best_survival,
	}


func _load() -> void:
	_initialize_defaults()
	if storage_path.is_empty():
		return
	var config := ConfigFile.new()
	if config.load(storage_path) != OK:
		return
	last_hero_id = str(config.get_value("meta", "last_hero_id", last_hero_id))
	last_level_id = str(config.get_value("meta", "last_level_id", last_level_id))
	if not hero_ids.has(last_hero_id):
		last_hero_id = hero_ids[0]
	if not level_ids.has(last_level_id):
		last_level_id = level_ids[0]
	for hero_id in hero_ids:
		_load_record(config, "hero/" + hero_id, records[hero_id])
	for level_id in level_ids:
		_load_record(config, "level/" + level_id, level_records[level_id])
		unlocked_levels[level_id] = bool(config.get_value("progress", "unlocked_" + level_id, level_id == level_ids[0]))
	unlocked_levels[level_ids[0]] = true
	if not is_level_unlocked(last_level_id):
		last_level_id = level_ids[0]


func _initialize_defaults() -> void:
	for hero_id in hero_ids:
		records[hero_id] = _empty_record()
	for level_id in level_ids:
		level_records[level_id] = _empty_level_record()
		unlocked_levels[level_id] = level_id == level_ids[0]


func _load_record(config: ConfigFile, section: String, record: Dictionary) -> void:
	for field in record:
		record[field] = maxi(0, int(config.get_value(section, field, 0)))


func _save() -> void:
	if storage_path.is_empty():
		return
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", SCHEMA_VERSION)
	config.set_value("meta", "last_hero_id", last_hero_id)
	config.set_value("meta", "last_level_id", last_level_id)
	for hero_id in hero_ids:
		_write_record(config, "hero/" + hero_id, hero_record(hero_id))
	for level_id in level_ids:
		_write_record(config, "level/" + level_id, level_record(level_id))
		config.set_value("progress", "unlocked_" + level_id, is_level_unlocked(level_id))
	config.save(storage_path)


func _write_record(config: ConfigFile, section: String, record: Dictionary) -> void:
	for field in record:
		config.set_value(section, field, record[field])


func _empty_record() -> Dictionary:
	return {"runs": 0, "wins": 0, "elite_kills": 0, "best_kills": 0, "best_level": 0, "best_survival_ms": 0}


func _empty_level_record() -> Dictionary:
	return _empty_record()
