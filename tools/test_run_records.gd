extends SceneTree

const RunRecords = preload("res://scripts/run_records.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")

var test_path := ""
var absolute_path := ""


func _initialize() -> void:
	test_path = "user://run_records_test_%d.cfg" % OS.get_process_id()
	absolute_path = ProjectSettings.globalize_path(test_path)
	DirAccess.remove_absolute(absolute_path)
	var first = RunRecords.new(test_path)
	if not first.is_level_unlocked("level_01") or first.is_level_unlocked("level_02"):
		push_error("RECORDS_FAILED: 新存档关卡解锁状态错误")
		_finish(1)
		return
	var failed_run := first.record_level_run("star_warden", "level_01", false, false, 5, 2, 12.0, LevelCatalog.first().reward)
	if failed_run["first_clear"] or not failed_run["newly_unlocked"].is_empty() or first.is_level_unlocked("level_02"):
		push_error("RECORDS_FAILED: 失败局错误解锁关卡或发放首通")
		_finish(1)
		return
	_write_legacy_record(test_path)
	var reloaded = RunRecords.new(test_path)
	var star: Dictionary = reloaded.hero_record("star_warden")
	var ember: Dictionary = reloaded.hero_record("ember_ranger")
	if star["runs"] != 2 or star["wins"] != 1 or star["elite_kills"] != 1 or star["best_kills"] != 42 or star["best_level"] != 7 or ember["runs"] != 0:
		push_error("RECORDS_FAILED: 战绩未持久化或英雄数据串联")
		_finish(1)
		return
	var first_level := LevelCatalog.by_id("level_01")
	var unlock_result: Dictionary = reloaded.record_level_run("ember_ranger", "level_01", true, true, 30, 6, 90.0, first_level.reward)
	if not unlock_result["first_clear"] or unlock_result["newly_unlocked"] != "level_02":
		push_error("RECORDS_FAILED: 首通奖励或解锁结果错误")
		_finish(1)
		return
	var progress_reloaded = RunRecords.new(test_path)
	if not progress_reloaded.is_level_unlocked("level_02") or progress_reloaded.is_level_unlocked("level_03"):
		push_error("RECORDS_FAILED: 关卡解锁未持久化或越级解锁")
		_finish(1)
		return
	if progress_reloaded.level_record("level_01")["wins"] != 1 or progress_reloaded.hero_record("ember_ranger")["wins"] != 1:
		push_error("RECORDS_FAILED: 关卡战绩与英雄战绩没有独立保存")
		_finish(1)
		return
	var repeat_result := progress_reloaded.record_level_run("ember_ranger", "level_01", true, false, 20, 5, 90.0, first_level.reward)
	if repeat_result["first_clear"] or not repeat_result["newly_unlocked"].is_empty() or progress_reloaded.is_level_unlocked("level_03"):
		push_error("RECORDS_FAILED: 重复通关再次发放首通或越级解锁")
		_finish(1)
		return
	var migrated_config := ConfigFile.new()
	if migrated_config.load(test_path) != OK or migrated_config.get_value("meta", "schema_version", 0) != RunRecords.SCHEMA_VERSION:
		push_error("RECORDS_FAILED: 旧存档写回后没有升级 schema")
		_finish(1)
		return
	var broken := FileAccess.open(test_path, FileAccess.WRITE)
	broken.store_string("broken-config")
	broken.close()
	var recovered = RunRecords.new(test_path)
	if recovered.hero_record("star_warden")["runs"] != 0:
		push_error("RECORDS_FAILED: 损坏配置没有安全回退")
		_finish(1)
		return
	print("RECORDS_OK persistence=true isolated=true migration=true unlocks=true corruption_safe=true")
	_finish(0)


func _write_legacy_record(path: String) -> void:
	var legacy := ConfigFile.new()
	legacy.set_value("meta", "schema_version", 1)
	legacy.set_value("meta", "last_hero_id", "star_warden")
	legacy.set_value("hero/star_warden", "runs", 2)
	legacy.set_value("hero/star_warden", "wins", 1)
	legacy.set_value("hero/star_warden", "elite_kills", 1)
	legacy.set_value("hero/star_warden", "best_kills", 42)
	legacy.set_value("hero/star_warden", "best_level", 7)
	legacy.set_value("hero/star_warden", "best_survival_ms", 90000)
	legacy.save(path)


func _finish(code: int) -> void:
	if not absolute_path.is_empty():
		DirAccess.remove_absolute(absolute_path)
	quit(code)
