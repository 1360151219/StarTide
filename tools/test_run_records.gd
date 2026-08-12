extends SceneTree

const RunRecords = preload("res://scripts/run_records.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const ProfileSchema = preload("res://scripts/profile/profile_schema.gd")

var test_path := ""
var absolute_path := ""
var schema3_test_path := ""
var schema3_absolute_path := ""


func _initialize() -> void:
	test_path = "user://run_records_test_%d.cfg" % OS.get_process_id()
	absolute_path = ProjectSettings.globalize_path(test_path)
	schema3_test_path = "user://run_records_schema3_test_%d.cfg" % OS.get_process_id()
	schema3_absolute_path = ProjectSettings.globalize_path(schema3_test_path)
	DirAccess.remove_absolute(absolute_path)
	DirAccess.remove_absolute(schema3_absolute_path)
	var first = RunRecords.new(test_path)
	if not first.is_level_unlocked("level_01") or first.is_level_unlocked("level_02"):
		push_error("RECORDS_FAILED: 新存档关卡解锁状态错误")
		_finish(1)
		return
	if first.discovered_content_count("enemies") != 0 or first.discovered_content_count("pickups") != 0 or first.discovered_content_count("skills") != 0 or first.discovered_content_count("relics") != 0:
		push_error("RECORDS_FAILED: 新存档不应预先解锁图鉴")
		_finish(1)
		return
	if not first.discover_content("enemies", "green_grub") or first.discover_content("enemies", "green_grub"):
		push_error("RECORDS_FAILED: 图鉴发现没有保持幂等")
		_finish(1)
		return
	if not first.is_content_discovered("enemies", "green_grub") or first.discovered_content_count("enemies") != 1:
		push_error("RECORDS_FAILED: 图鉴发现状态或计数错误")
		_finish(1)
		return
	var new_discoveries := first.new_content_discoveries()
	if new_discoveries.size() != 1 or new_discoveries[0] != {"category": "enemies", "content_id": "green_grub"}:
		push_error("RECORDS_FAILED: 本次新增图鉴记录错误")
		_finish(1)
		return
	if first.discover_content("heroes", "star_warden") or first.discover_content("skills", "非法 ID"):
		push_error("RECORDS_FAILED: 图鉴接受了未知分类或非法稳定 ID")
		_finish(1)
		return
	first.clear_new_content_discoveries()
	if not first.new_content_discoveries().is_empty():
		push_error("RECORDS_FAILED: 本次新增图鉴没有正确清空")
		_finish(1)
		return
	var discovery_reloaded = RunRecords.new(test_path)
	if not discovery_reloaded.is_content_discovered("enemies", "green_grub") or not discovery_reloaded.new_content_discoveries().is_empty():
		push_error("RECORDS_FAILED: 图鉴发现未持久化或跨启动重复报告")
		_finish(1)
		return
	var failed_run := first.record_level_run("star_warden", LevelCatalog.first(), false, false, 5, 2, 12.0)
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
	var unlock_result: Dictionary = reloaded.record_level_run("ember_ranger", first_level, true, true, 30, 6, 90.0)
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
	var unlock_config := ConfigFile.new()
	unlock_config.load(test_path)
	unlock_config.set_value("progress", "unlocked_level_02", false)
	unlock_config.save(test_path)
	progress_reloaded = RunRecords.new(test_path)
	if not progress_reloaded.is_level_unlocked("level_02"):
		push_error("RECORDS_FAILED: 新增关卡后没有按既有通关记录修复解锁链")
		_finish(1)
		return
	var repeat_result := progress_reloaded.record_level_run("ember_ranger", first_level, true, false, 20, 5, 90.0)
	if repeat_result["first_clear"] or not repeat_result["newly_unlocked"].is_empty() or progress_reloaded.is_level_unlocked("level_03"):
		push_error("RECORDS_FAILED: 重复通关再次发放首通或越级解锁")
		_finish(1)
		return
	var campaign_config := ConfigFile.new()
	campaign_config.load(test_path)
	campaign_config.set_value("level/level_03", "wins", 1)
	campaign_config.set_value("progress", "unlocked_level_04", false)
	campaign_config.set_value("progress", "unlocked_level_05", false)
	campaign_config.save(test_path)
	var campaign_reloaded := RunRecords.new(test_path)
	if not campaign_reloaded.is_level_unlocked("level_04") or campaign_reloaded.is_level_unlocked("level_05"):
		push_error("RECORDS_FAILED: 既有第三关通关存档没有自动补开第四关或错误越级解锁第五关")
		_finish(1)
		return
	var migrated_config := ConfigFile.new()
	if migrated_config.load(test_path) != OK or migrated_config.get_value("meta", "schema_version", 0) != ProfileSchema.VERSION:
		push_error("RECORDS_FAILED: 旧存档写回后没有升级 schema")
		_finish(1)
		return
	if reloaded.discovered_content_count("enemies") != 4 or reloaded.discovered_content_count("pickups") != 3 or reloaded.discovered_content_count("skills") != 6:
		push_error("RECORDS_FAILED: v3 以前公开图鉴没有按固定快照迁移")
		_finish(1)
		return
	if reloaded.discovered_content_count("relics") != 0:
		push_error("RECORDS_FAILED: 旧存档错误解锁了新增遗物")
		_finish(1)
		return
	if reloaded.is_content_discovered("skills", "future_skill"):
		push_error("RECORDS_FAILED: 图鉴迁移错误解锁了快照外内容")
		_finish(1)
		return
	_write_schema3_profile(schema3_test_path)
	var schema3_reloaded = RunRecords.new(schema3_test_path)
	var schema3_progress: Dictionary = schema3_reloaded.hero_progressions["star_warden"]
	if schema3_progress["hero_xp"] != 450 or schema3_progress["training"]["star_lance"] != 2 or schema3_progress["training"]["sun_orbit"] != 1:
		push_error("RECORDS_FAILED: schema 3 升级到 schema 6 时英雄成长或训练丢失")
		_finish(1)
		return
	if schema3_reloaded.discovered_content_count("enemies") != 4 or schema3_reloaded.discovered_content_count("skills") != 6:
		push_error("RECORDS_FAILED: schema 3 图鉴迁移快照错误")
		_finish(1)
		return
	if schema3_reloaded.discovered_content_count("relics") != 0:
		push_error("RECORDS_FAILED: schema 3 迁移错误解锁了新增遗物")
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
	print("RECORDS_OK persistence=true isolated=true migration=true unlocks=true level3_repair=true discovery=true schema3_growth=true corruption_safe=true")
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


func _write_schema3_profile(path: String) -> void:
	var legacy := ConfigFile.new()
	legacy.set_value("meta", "schema_version", 3)
	legacy.set_value("meta", "last_hero_id", "star_warden")
	legacy.set_value("meta", "last_level_id", "level_01")
	legacy.set_value("progression/star_warden", "mastery_xp", 450)
	legacy.set_value("progression/star_warden", "training_star_lance", 2)
	legacy.set_value("progression/star_warden", "training_sun_orbit", 1)
	legacy.set_value("progression/star_warden", "training_frost_tide", 0)
	legacy.save(path)


func _finish(code: int) -> void:
	if not absolute_path.is_empty():
		DirAccess.remove_absolute(absolute_path)
	if not schema3_absolute_path.is_empty():
		DirAccess.remove_absolute(schema3_absolute_path)
	quit(code)
