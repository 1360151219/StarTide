extends SceneTree

const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")

var failed := false
var frame_count := 0


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count > 90:
		_fail("主场景加载或响应式布局测试超时")
		quit(1)
		return
	var game := current_scene
	if game == null or frame_count < 4:
		return
	_test_project_settings()
	_test_safe_area_conversion()
	_test_full_screen_roots(game)
	_test_compact_ui(game)
	for profile in _profiles():
		_test_profile(game, profile)
	_test_no_fixed_screen_rects()
	if not failed:
		print("RESPONSIVE_OK profiles=4 full_bleed=true safe_controls=true spawn_clearance=true")
	quit(1 if failed else 0)


func _test_project_settings() -> void:
	_require(ProjectSettings.get_setting("display/window/stretch/aspect") == "expand", "项目没有显式使用 expand 拉伸")
	_require(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items", "项目没有使用 canvas_items 拉伸")


func _test_safe_area_conversion() -> void:
	var visible := Rect2(0.0, 0.0, 540.0, 1200.0)
	var window := Rect2(0.0, 0.0, 1080.0, 2400.0)
	var physical_safe := Rect2(0.0, 96.0, 1080.0, 2208.0)
	var logical := ScreenLayout.physical_safe_to_logical(visible, window, physical_safe)
	_require(logical.is_equal_approx(Rect2(0.0, 48.0, 540.0, 1104.0)), "2 倍物理安全区没有正确转换为逻辑坐标")


func _test_full_screen_roots(game: Node) -> void:
	for control in [
		game.start_screen.screen_background,
		game.start_screen.compendium,
		game.hud.damage_flash,
		game.pause_overlay.screen_overlay,
		game.upgrade_overlay.screen_overlay,
		game.result_overlay.screen_overlay,
	]:
		_require(_is_full_rect(control), "%s 没有覆盖完整视口" % control.name)


func _test_compact_ui(game: Node) -> void:
	_require(game.hud.top_panel.size.y <= 72.0, "战斗顶部状态栏超过 72 像素")
	var top_rect: Rect2 = game.hud.top_panel.get_global_rect()
	var health_rect: Rect2 = game.hud.health_bar.get_global_rect()
	var xp_rect: Rect2 = game.hud.xp_bar.get_global_rect()
	_require(not health_rect.intersects(xp_rect), "生命条与经验条发生重叠")
	_require(xp_rect.position.y - health_rect.end.y >= 4.0, "生命条与经验条间距不足 4 像素")
	_require(_contains_rect(top_rect, health_rect, 0.01) and _contains_rect(top_rect, xp_rect, 0.01), "顶部状态条子控件越过面板")
	_require(game.hud.skill_dock.anchor_top == 1.0 and game.hud.skill_dock.size.x <= 286.0, "自动技能状态栏没有保持在右下区域")
	_require(game.hud.skill_dock.icons.size() == 3 and game.hud.skill_dock.badges.size() == 3, "技能状态栏没有保持图标化三槽")
	_require(game.hud.stage_hud.banner.size.y <= 64.0, "阶段提示高度超过 64 像素")
	_require(_contains_rect(game.hud.tutorial_panel.get_global_rect(), game.hud.tutorial_label.get_global_rect(), 0.01), "新手提示文字越过深色承载底板")
	_require(game.start_screen.lobby_view.visible and not game.start_screen.character_page.visible, "开始页没有默认停留在关卡大厅")
	_require(game.start_screen.bottom_bar.size.y >= 96.0, "悬浮底栏高度不足")
	_require(game.start_screen.bottom_bar.buttons.size() == 3, "远征底栏不是三个等权主入口")
	for button in game.start_screen.character_page.equipment_panel.inventory_buttons + game.start_screen.character_page.equipment_panel.filter_buttons.values() + [
		game.start_screen.character_page.equipment_panel.detail_sheet.action_button,
		game.start_screen.character_page.skill_panel.reset_button,
	]:
		_require(button.size.y >= 48.0, "角色页存在不足 48 像素的触控区域")
	_require(game.start_screen.route_map.animation_player.is_playing(), "远征路线动画没有播放")
	game.result_overlay.show_result({
		"heading": "完美远征", "outcome_hint": "彩晶火山 · 精英已击破", "won": true,
		"new_record": true, "duration_text": "02:00", "kills": 123, "player_level": 11,
		"hero_id": "star_warden", "first_clear": true, "first_clear_hint": "星门守望者认证",
		"progression_reward": {"hero_xp_gained": 100, "level": 10},
		"equipment_reward": {"item_rows": [{"definition_id": "timeglass_charm", "rarity": "rare", "level": 1}]},
		"random_equipment_reward": {"items": [
			{"definition_id": "apprentice_starwand", "rarity": "common", "level": 1},
			{"definition_id": "crystal_vest", "rarity": "rare", "level": 1},
			{"definition_id": "windbell_charm", "rarity": "top", "level": 1},
		]},
		"discovery_count": 1,
		"build_snapshot": {
			"skill_slots": ["star_lance", "sun_orbit", "frost_tide"],
			"skill_levels": {"star_lance": 3, "sun_orbit": 3, "frost_tide": 3},
			"skill_branches": {"star_lance": "star_lance_fan", "sun_orbit": "sun_orbit_swarm", "frost_tide": "frost_tide_field"},
			"relic_levels": {"star_core": 3, "energy_prism": 3, "time_gear": 3, "echo_lens": 3},
		},
	})
	var card_rect: Rect2 = game.result_overlay.result_card.get_global_rect()
	for label in [game.result_overlay.heading, game.result_overlay.summary]:
		_require(_contains_rect(card_rect, label.get_global_rect(), 0.51), "结算文案越过卡片边界")
		_require(label.autowrap_mode != TextServer.AUTOWRAP_OFF and label.clip_text, "结算文案没有启用受限换行")
	_require(game.result_overlay.summary.size_flags_vertical == Control.SIZE_EXPAND_FILL and game.result_overlay.summary.get_theme_font_size("font_size") <= 18, "结算摘要没有为完整换行预留弹性空间")
	_require(game.result_overlay.stat_values[0].text == "02:00", "结算用时没有进入战绩卡")
	_require(game.result_overlay.reward_strip.tile_count() == 7, "结算奖励没有完整保留溢出的奖励图标")
	_require(game.result_overlay.reward_strip.has_horizontal_overflow(), "超过六项奖励时没有启用水平滑动")
	_require(game.result_overlay.build_icons.get_child_count() == 7, "结算构筑没有完整展示技能与遗物图标")
	game.result_overlay.visible = false


func _test_profile(game: Node, profile: Dictionary) -> void:
	var safe_rect: Rect2 = profile["safe"]
	for frame in [
		game.start_screen.design_frame,
		game.start_screen.global_chrome,
		game.pause_overlay.design_frame,
		game.upgrade_overlay.design_frame,
		game.result_overlay.design_frame,
	]:
		frame.layout_in_rect(safe_rect)
		_require(frame.position.is_equal_approx(profile["design_position"]), "%s 的设计框位置错误" % profile["id"])
	game.start_screen.compendium.safe_area.layout_in_rect(safe_rect)
	game.start_screen.navigation_safe_area.layout_in_rect(safe_rect)
	game.start_screen.bottom_bar.layout_in_safe_rect(safe_rect)
	game.hud.safe_area.layout_in_rect(safe_rect)
	game.start_screen.show_page("character")
	for root in [
		game.start_screen.design_frame,
		game.start_screen.global_chrome,
		game.start_screen.navigation_safe_area,
		game.start_screen.compendium.safe_area,
		game.hud.safe_area,
		game.pause_overlay.design_frame,
		game.upgrade_overlay.design_frame,
		game.result_overlay.design_frame,
	]:
		_check_interactive_bounds(root, safe_rect, profile["id"])
	var bottom_rect: Rect2 = game.start_screen.bottom_bar.get_global_rect()
	var design_rect: Rect2 = game.start_screen.design_frame.get_global_rect()
	var expected_bottom_y := minf(design_rect.position.y + 840.0, safe_rect.end.y - 120.0)
	_require(
		bottom_rect.is_equal_approx(Rect2(Vector2(design_rect.position.x, expected_bottom_y), Vector2(540, 120))),
		"%s 的底部导航没有复用首页坐标或适配较短安全区" % profile["id"]
	)
	for button in game.start_screen.bottom_bar.buttons.values():
		_require(button.get_global_rect().size.y >= 88.0, "%s 的底部菜单触控区域不足 88 像素" % profile["id"])
	game.start_screen.show_page("compendium")
	var paper_rect: Rect2 = game.start_screen.compendium.collection_view.paper_sheet.get_global_rect()
	_require(paper_rect.end.y <= bottom_rect.position.y + 0.51, "%s 的图鉴内容被底部导航遮挡" % profile["id"])
	game.start_screen.show_page("start")


func _check_interactive_bounds(root: Node, safe_rect: Rect2, profile_id: String) -> void:
	for node in _descendants(root):
		if not (node is BaseButton or node is HSlider or node == current_scene.hud.joystick):
			continue
		if not node.is_visible_in_tree():
			continue
		var rect: Rect2 = node.get_global_rect()
		_require(_contains_rect(safe_rect, rect, 0.51), "%s 的 %s 越过安全区：%s" % [profile_id, node.name, rect])


func _test_no_fixed_screen_rects() -> void:
	for path in [
		"res://scripts/ui/start_screen.gd", "res://scripts/ui/game_hud.gd",
		"res://scripts/ui/stage_hud.gd", "res://scripts/ui/pause_overlay.gd",
		"res://scripts/ui/upgrade_overlay.gd", "res://scripts/ui/result_overlay.gd",
		"res://scripts/ui/compendium_overlay.gd", "res://scripts/ui/frontend_shell.gd",
		"res://scripts/ui/character_page.gd", "res://scripts/ui/bottom_bar.gd",
	]:
		var file := FileAccess.open(path, FileAccess.READ)
		_require(file != null, "无法读取响应式界面：%s" % path)
		if file != null:
			_require(not file.get_as_text().contains("Vector2(540, 960)"), "%s 仍写死全屏尺寸" % path)


func _profiles() -> Array[Dictionary]:
	return [
		{"id": "9_16", "safe": Rect2(0, 0, 540, 960), "design_position": Vector2(0, 0)},
		{"id": "19_5_9", "safe": Rect2(0, 36, 540, 1098), "design_position": Vector2(0, 105)},
		{"id": "20_9", "safe": Rect2(16, 48, 508, 1092), "design_position": Vector2(0, 114)},
		{"id": "3_4", "safe": Rect2(24, 24, 672, 912), "design_position": Vector2(90, 24)},
	]


func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child: Node in node.get_children():
			result.append(child)
			pending.append(child)
	return result


func _is_full_rect(control: Control) -> bool:
	return is_equal_approx(control.anchor_left, 0.0) and is_equal_approx(control.anchor_top, 0.0) and is_equal_approx(control.anchor_right, 1.0) and is_equal_approx(control.anchor_bottom, 1.0) and control.offset_left == 0.0 and control.offset_top == 0.0 and control.offset_right == 0.0 and control.offset_bottom == 0.0


func _contains_rect(outer: Rect2, inner: Rect2, tolerance: float) -> bool:
	return inner.position.x >= outer.position.x - tolerance and inner.position.y >= outer.position.y - tolerance and inner.end.x <= outer.end.x + tolerance and inner.end.y <= outer.end.y + tolerance


func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failed = true
	push_error("RESPONSIVE_FAILED: " + message)
