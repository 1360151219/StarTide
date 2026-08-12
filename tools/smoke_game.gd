extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const CueCatalog = preload("res://scripts/audio_cue_catalog.gd")

var frame_count := 0
var failed := false
var paused_elapsed := 0.0


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	var game := current_scene
	if game == null:
		if frame_count >= 120:
			push_error("SMOKE_FAILED: 主场景加载超时")
			quit(1)
		return
	if frame_count == 3:
		_test_start_screen(game)
	if frame_count == 5:
		game.start_run("star_warden", "level_01")
	if frame_count == 8:
		_test_running_session(game)
	if frame_count == 12:
		_begin_pause(game)
	if frame_count == 14:
		_finish_pause_and_upgrade(game)
	if frame_count == 36:
		_verify_upgrade_completed(game)
	if frame_count == 40:
		_test_victory(game)
	if frame_count == 44:
		if not failed:
			print("SMOKE_OK levels=%d menu=route_map destinations=5 session=modular pause=stable upgrade=true victory=true unlock=true audio=%d volume_sync=true" % [LevelCatalog.all().size(), CueCatalog.ids().size()])
		quit(1 if failed else 0)


func _test_start_screen(game: Node) -> void:
	_require(CueCatalog.ids().size() == 56, "声音 Cue 没有完整初始化")
	var original_music: float = game.audio_manager.music_volume
	var original_sfx: float = game.audio_manager.sfx_volume
	game.audio_manager.set_music_volume(0.37, false)
	game.audio_manager.set_sfx_volume(0.42, false)
	_require(game.start_screen.audio_settings.music_slider.value == 37.0, "开始页音乐音量没有同步")
	_require(game.pause_overlay.audio_settings.music_slider.value == 37.0, "暂停页音乐音量没有同步")
	_require(game.start_screen.audio_settings.sfx_slider.value == 42.0, "开始页音效音量没有同步")
	_require(game.pause_overlay.audio_settings.sfx_slider.value == 42.0, "暂停页音效音量没有同步")
	_require(not game.start_screen.audio_settings.settings_card.visible, "开始页声音设置默认展开")
	game.start_screen.audio_settings.launcher_button.pressed.emit()
	_require(game.start_screen.audio_settings.settings_card.visible, "开始页声音设置入口无法展开")
	game.start_screen.audio_settings.close_button.pressed.emit()
	_require(not game.start_screen.audio_settings.settings_card.visible, "开始页声音设置无法关闭")
	game.audio_manager.set_music_volume(original_music, false)
	game.audio_manager.set_sfx_volume(original_sfx, false)
	_require(game.start_screen.route_map.route_pins.size() == 5, "远征地图没有配置五个生态节点")
	_require(bool(game.start_screen.route_map.route_pins[0].get("selected")), "第一关路线节点没有选中")
	_require(bool(game.start_screen.route_map.route_pins[1].get("locked")), "后续关卡没有保持锁定预览")
	_require(game.start_screen.route_map.animation_player.is_playing(), "远征路线动画没有播放")
	_require(game.start_screen.bottom_bar.buttons.size() == 3, "远征底栏没有提供三个主入口")
	game.start_screen.route_map.move_by(1)
	_require(game.start_screen.selected_level_id == "level_02" and game.start_screen.start_button.disabled, "未解锁关卡预览没有阻止进入")
	game.start_screen.route_map.move_by(-1)
	game.start_screen.bottom_bar.buttons["character"].pressed.emit()
	_require(game.start_screen.character_page.visible and not game.start_screen.lobby_view.visible, "角色菜单没有显示角色配置页")
	_require(not game.start_screen.route_map.animation_player.is_playing(), "离开关卡大厅后路线动画仍在播放")
	game.start_screen.character_page.select_hero("ember_ranger")
	_require(game.run_records.get_active_hero_id() == "ember_ranger", "角色页没有更新出战英雄")
	game.start_screen.bottom_bar.buttons["start"].pressed.emit()
	_require(game.start_screen.lobby_view.visible and not game.start_screen.character_page.visible, "底部导航无法返回开始页")
	game.start_screen.bottom_bar.buttons["compendium"].pressed.emit()
	game.start_screen.compendium.show_category("skills")
	_require(game.start_screen.compendium.visible and game.start_screen.compendium.list.get_child_count() == 6, "技能图鉴不完整")
	_require(game.start_screen.bottom_bar.current_page == "compendium" and game.start_screen.bottom_bar.visible, "图鉴没有作为第三主导航显示")
	game.start_screen.bottom_bar.buttons["start"].pressed.emit()
	_require(not game.hud.joystick.active and is_zero_approx(game.hud.joystick.fade_time), "浮动摇杆默认仍然可见")
	var touch := InputEventScreenTouch.new()
	touch.index = 7
	touch.pressed = true
	touch.position = Vector2(430, 620)
	game.hud.joystick._gui_input(touch)
	_require(game.hud.joystick.active and game.hud.joystick.base_position.x > 400.0, "浮动摇杆没有在任意战场触点出现")
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = Vector2(520, 620)
	game.hud.joystick._gui_input(drag)
	_require(game.hud.joystick.value.length() > 0.95, "浮动摇杆拖动无效")
	touch.pressed = false
	game.hud.joystick._gui_input(touch)
	_require(game.hud.joystick.value == Vector2.ZERO and not game.hud.joystick.active and game.hud.joystick.fade_time > 0.0, "浮动摇杆未复位或缺少松手淡出")


func _test_running_session(game: Node) -> void:
	var session: Node = game.session
	_require(session.level.level_id == "level_01", "运行会话没有读取第一关配置")
	_require(session.level.map.world_bounds.size == Vector2(3200, 3200), "地图配置未注入运行会话")
	_require(session.enemies.enemies.size() == session.level.initial_enemy_count, "初始刷怪数量错误")
	_require(session.skills.levels["star_lance"] == 1 and not session.skills.levels.has("sun_orbit"), "第一关技能池没有只启用签名技能")
	_require(session.stage_director.current_stage().stage_id == "awakening", "初始阶段错误")
	_require(not game.hud.skill_dock.detail_panel.visible, "技能明细默认展开并遮挡战场")
	game.hud.skill_dock.launcher_button.pressed.emit()
	_require(game.hud.skill_dock.detail_panel.visible and game.hud.skill_dock.icons.size() == 3 and game.hud.skill_dock.badges[0].text == "I", "技能入口无法显示完整技能明细")
	game.hud.skill_dock.launcher_button.pressed.emit()
	_require(not game.hud.skill_dock.detail_panel.visible, "技能明细无法收起")


func _begin_pause(game: Node) -> void:
	game.hud.pause_requested.emit()
	_require(game.session.state.paused and game.pause_overlay.visible, "暂停功能无效")
	_require(game.audio_manager.music_ducked, "暂停时背景音乐没有降噪")
	paused_elapsed = game.session.state.elapsed


func _finish_pause_and_upgrade(game: Node) -> void:
	_require(is_equal_approx(game.session.state.elapsed, paused_elapsed), "暂停期间关卡时间仍在推进")
	game.pause_overlay.resume_requested.emit()
	_require(not game.session.state.paused and not game.pause_overlay.visible, "继续游戏无效")
	_require(not game.audio_manager.music_ducked, "继续游戏后背景音乐没有恢复")
	game.session.add_experience(40)
	_require(game.upgrade_overlay.visible and game.upgrade_overlay.buttons.size() == 3, "升级三选一没有出现")
	for card in game.upgrade_overlay.choice_cards:
		_require(not card.visible or card.metric_count() in [1, 2, 3], "升级卡没有使用图形化属性指标")
	_require(game.audio_manager.music_ducked, "升级选择时背景音乐没有降噪")
	_require(not game.upgrade_overlay.reroll_button.disabled and game.session.build_state.rerolls_remaining == 1, "本局免费重抽没有显示")
	game.upgrade_overlay.reroll_button.pressed.emit()
	_require(game.upgrade_overlay.visible and game.session.build_state.rerolls_remaining == 0, "重抽没有刷新候选或消费次数")
	game.upgrade_overlay.buttons[0].pressed.emit()
	_require(game.upgrade_overlay.selection_locked, "升级选择没有进入确认动画")
	game.upgrade_overlay.finish_selection()


func _verify_upgrade_completed(game: Node) -> void:
	_require(not game.upgrade_overlay.visible and not game.session.state.paused, "选择升级后没有恢复游戏")
	_require(not game.audio_manager.music_ducked, "选择升级后背景音乐没有恢复")


func _test_victory(game: Node) -> void:
	game.session.player.max_health = 99999.0
	game.session.player.health = 99999.0
	game.session.advance(game.session.level.duration, Vector2.ZERO)
	_require(game.session.state.finished and game.session.state.victory, "第一关 90 秒胜利未生效")
	_require(game.result_overlay.visible, "胜利结算没有出现")
	game.result_overlay.finish_reveal()
	_require(not game.result_overlay.replay_button.disabled and not game.result_overlay.home_button.disabled, "跳过结算演出后按钮仍不可操作")
	_require(game.result_overlay.hero_preview.visible and game.result_overlay.hero_rig.hero_id == "star_warden", "结算页没有展示本局英雄")
	_require(game.result_overlay.hero_rig.current_state == "victory", "胜利结算没有触发骨骼胜利动画")
	var reward_tooltips: PackedStringArray = game.result_overlay.reward_strip.tile_tooltips()
	_require("\n".join(reward_tooltips).contains("风弦短弓") and game.result_overlay.reward_strip.tile_count() >= 3, "首次通关结算没有用图标展示固定装备与随机掉落")
	_require(game.run_records.is_level_unlocked("level_02"), "第一关通关没有解锁第二关")


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("SMOKE_FAILED: " + message)
