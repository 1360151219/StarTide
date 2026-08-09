extends SceneTree

const AudioManager = preload("res://scripts/audio_manager.gd")
const CueCatalog = preload("res://scripts/audio_cue_catalog.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const CombatTimeline = preload("res://scripts/combat/combat_timeline.gd")
const TelegraphRenderer = preload("res://scripts/presentation/enemy_telegraph_renderer.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")

var failed := false
var timeline_events: Array[String] = []


func _initialize() -> void:
	_test_audio_catalog_and_buses()
	_test_effect_budgets()
	_test_combat_timeline()
	_test_warning_progress()
	_test_color_roles()
	_test_visual_language_contract()
	if not failed:
		print("PRESENTATION_OK cues=%d voices=16 effects=64 numbers=18 timeline=deterministic warnings=progressive colors=accessible" % CueCatalog.ids().size())
	quit(1 if failed else 0)


func _test_audio_catalog_and_buses() -> void:
	_require(CueCatalog.validation_errors().is_empty(), "音频 Cue 目录存在无效配置")
	_require(CueCatalog.MUSIC.size() == 4, "大厅与三个生态没有独立音乐循环")
	_require(CueCatalog.music("level_01") != CueCatalog.music("level_02") and CueCatalog.music("level_02") != CueCatalog.music("level_03"), "三个生态错误复用同一条音乐")
	for cue_id in ["enemy_warning", "grub_roll_charge", "grub_roll_move", "grub_roll_miss", "bat_bolt_charge", "bat_bolt_launch", "bat_bolt_impact", "pickup_xp", "pickup_heal", "pickup_magnet", "pickup_haste", "pickup_bomb", "elite_appear", "elite_defeat", "result_victory", "result_failure"]:
		_require(not CueCatalog.cue(cue_id).is_empty(), "缺少关键声音 Cue：%s" % cue_id)
	_require(int(CueCatalog.cue("enemy_warning")["priority"]) > int(CueCatalog.cue("impact")["priority"]), "危险声音优先级没有高于普通命中")
	var manager := AudioManager.new()
	root.add_child(manager)
	manager._ensure_audio_buses()
	manager.audio_output_available = false
	manager.play_music("level_02")
	_require(manager.current_music_profile == "level_02", "关卡音乐配置没有在无声环境中保持")
	_require(AudioManager.VOICE_COUNT == 16, "音效保护池不是 16 路")
	for bus_name in [CueCatalog.BUS_MUSIC, CueCatalog.BUS_SFX, CueCatalog.BUS_UI, CueCatalog.BUS_COMBAT, CueCatalog.BUS_ALERT, CueCatalog.BUS_AMBIENCE]:
		_require(AudioServer.get_bus_index(bus_name) >= 0, "缺少音频总线：%s" % bus_name)
	var master_index := AudioServer.get_bus_index(&"Master")
	var has_limiter := false
	for effect_index in range(AudioServer.get_bus_effect_count(master_index)):
		has_limiter = has_limiter or AudioServer.get_bus_effect(master_index, effect_index) is AudioEffectLimiter
	_require(has_limiter, "Master 总线没有 Limiter")
	manager.free()


func _test_effect_budgets() -> void:
	var effects := CombatEffects.new()
	root.add_child(effects)
	for index in range(80):
		effects.add_effect(Vector2(index, 0), 8.0, Color.WHITE, 1.0, "defeat")
	_require(effects.effects.size() == 64, "短效实例没有遵守 64 个硬上限")
	effects.clear_all()
	effects.add_damage_number(Vector2.ZERO, 5.0, Color.WHITE, false, 77)
	effects.add_damage_number(Vector2(2, 0), 7.0, Color.WHITE, false, 77)
	_require(effects.effects.size() == 1 and is_equal_approx(float(effects.effects[0]["amount"]), 12.0), "同目标 120ms 伤害数字没有合并")
	effects.clear_all()
	for index in range(24):
		effects.add_damage_number(Vector2(index * 50.0, 0), 1.0, Color.WHITE, false, index + 1)
	for index in range(4):
		effects.add_heal_number(Vector2(index * 50.0, 50), 2.0)
	var number_count := 0
	for effect in effects.effects:
		number_count += int(effect["kind"] in ["damage_text", "heal_text"])
	_require(number_count == 18, "浮动数字没有遵守 18 个上限")
	effects.free()


func _test_combat_timeline() -> void:
	var timeline := CombatTimeline.new()
	timeline.schedule(0.1, _record_timeline.bind("late"), "test")
	timeline.schedule(0.05, _record_timeline.bind("early"), "test")
	_require(timeline.pending_count("test") == 2 and timeline_events.is_empty(), "表现时间轴调度时提前执行")
	timeline.advance(0.049)
	_require(timeline_events.is_empty(), "表现时间轴在命中帧前执行")
	timeline.advance(0.001)
	_require(timeline_events == ["early"], "表现时间轴没有先执行较早事件")
	timeline.advance(0.05)
	_require(timeline_events == ["early", "late"], "表现时间轴顺序不确定")


func _test_warning_progress() -> void:
	var renderer := TelegraphRenderer.new()
	root.add_child(renderer)
	var enemy := Node2D.new()
	root.add_child(enemy)
	renderer.set_states({1: {
		"phase": "warning", "enemy": enemy, "ability_id": "green_grub_roll",
		"phase_left": 0.1, "direction": Vector2.RIGHT,
	}})
	_require(renderer.warnings.size() == 1, "敌方预警没有从施法状态生成")
	var warning: Dictionary = renderer.warnings[0]
	_require(float(warning["progress"]) > 0.8 and bool(warning["locked"]), "敌方预警缺少末段进度或锁定状态")
	enemy.free()
	renderer.free()


func _test_color_roles() -> void:
	_require(UiFactory.BACKGROUND == Color("ddefe7") and UiFactory.SURFACE == Color("fff6e2") and UiFactory.PRIMARY == Color("4fa7b5"), "方案 D 基础色没有使用审阅后的稳定 Token")
	_require(UiFactory.ACCENT == Color("f2b84b") and UiFactory.DANGER == Color("e45b5b") and UiFactory.SUPPORTING == Color("76b77a"), "方案 D 功能色没有使用审阅后的稳定 Token")
	_require(_contrast(UiFactory.INK, UiFactory.SURFACE) >= 7.0, "正文与帆布底对比度不足 7:1")
	_require(_contrast(UiFactory.ACCENT_DARK, UiFactory.SURFACE) >= 4.5, "强调色正文与帆布底对比度不足 4.5:1")
	_require(_contrast(UiFactory.DANGER_DARK, UiFactory.SURFACE) >= 4.5, "危险正文与帆布底对比度不足 4.5:1")
	var levels := LevelCatalog.all()
	_require(levels.size() >= 3, "缺少三套生态配置")
	_require(levels[0].map.decoration_count <= 48 and levels[2].map.decoration_count <= 64, "草原或火山装饰降噪预算未生效")
	_require(levels[0].map.scene_saturation >= 0.64 and levels[2].map.scene_saturation >= 0.64, "清新动漫场景被过度去饱和")
	_require(levels[1].map.background_color.get_luminance() < 0.62, "金砂绿洲背景仍然过曝")


func _test_visual_language_contract() -> void:
	for required_path in [
		"res://scripts/ui/sunlit_frame.gd",
		"res://scripts/ui/sunlit_card_style.gd",
		"res://scripts/ui/sunlit_glyph.gd",
		"res://scripts/ui/expedition_route_map.gd",
		"res://scripts/ui/expedition_route_pin.gd",
		"res://scripts/ui/battle_route_progress.gd",
		"res://scripts/presentation/world_landmarks.gd",
		"res://assets/art/sunlit/backgrounds/expedition_route_map.png",
	]:
		_require(FileAccess.file_exists(required_path), "缺少方案 D 共用组件：%s" % required_path)
	for file_name in DirAccess.get_files_at("res://scripts/ui"):
		if not file_name.ends_with(".gd"):
			continue
		var file := FileAccess.open("res://scripts/ui/" + file_name, FileAccess.READ)
		if file == null:
			continue
		var source := file.get_as_text()
		for forbidden in ["StarTide", "apply_glass_button", "glass_panel_style", "✦", "◇", "◆", "＋", "♥", "♫", "♬"]:
			_require(not source.contains(forbidden), "%s 仍包含暂停方案或字体占位图标：%s" % [file_name, forbidden])
	var world_file := FileAccess.open("res://scripts/presentation/world_renderer.gd", FileAccess.READ)
	_require(world_file != null and not world_file.get_as_text().contains("draw_rect(map.world_bounds, map.border_color"), "开放地图仍绘制可见竞技场边界")
	var start_file := FileAccess.open("res://scripts/ui/start_screen.gd", FileAccess.READ)
	_require(start_file != null and start_file.get_as_text().contains("ExpeditionRouteMap"), "远征首页没有接入三生态路线地图")
	_require(not FileAccess.file_exists("res://scripts/ui/level_preview.gd") and not FileAccess.file_exists("res://scripts/ui/level_selector.gd"), "旧门户轮播实现仍与远征地图并存")


func _record_timeline(event_id: String) -> void:
	timeline_events.append(event_id)


func _contrast(left: Color, right: Color) -> float:
	var light := maxf(_relative_luminance(left), _relative_luminance(right))
	var dark := minf(_relative_luminance(left), _relative_luminance(right))
	return (light + 0.05) / (dark + 0.05)


func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)


func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PRESENTATION_FAILED: " + message)
