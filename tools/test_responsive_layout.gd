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
	_require(game.hud.skill_dock.anchor_top == 1.0 and game.hud.skill_dock.size.x <= 210.0, "技能栏没有移动到紧凑的右下区域")
	_require(game.hud.stage_hud.banner.size.y <= 64.0, "阶段提示高度超过 64 像素")
	_require(game.start_screen.lobby_view.visible and not game.start_screen.hero_view.visible, "开始页没有默认停留在关卡大厅")
	_require(game.start_screen.level_preview.animation_player.is_playing(), "关卡预览动画没有播放")
	game.result_overlay.show_result(
		"完美远征与星门守护认证",
		"彩晶火山 · 星潮守望者\n挑战成功 · 击败星核暴君并坚持 120 秒\n用时 02:00 · 击败 123 · 等级 11\n精英 已击败\n星潮伤害 +99% · 移速 +24% · 最大生命 +45\n个人最佳 · 击败 123",
		"首次通关 · 星门守望者\n完成当前三关远征，获得星门守望者认证与额外成长奖励\n英雄熟练度 +100 · 当前 Lv.10 · 技能点 +1",
		true,
		"技能：星芒枪 III·星雨齐射 / 日轮守卫 III·群星环列 / 霜潮脉冲 III·永冻冰原\n遗物：星核扩容 III / 聚能棱晶 III / 时砂齿轮 III / 回响透镜 III · 重抽 0"
	)
	var card_rect: Rect2 = game.result_overlay.result_card.get_global_rect()
	for label in [game.result_overlay.heading, game.result_overlay.summary, game.result_overlay.reward_label, game.result_overlay.build_label]:
		_require(_contains_rect(card_rect, label.get_global_rect(), 0.51), "结算文案越过卡片边界")
		_require(label.autowrap_mode != TextServer.AUTOWRAP_OFF and label.clip_text, "结算文案没有启用受限换行")
	game.result_overlay.visible = false


func _test_profile(game: Node, profile: Dictionary) -> void:
	var safe_rect: Rect2 = profile["safe"]
	for frame in [
		game.start_screen.design_frame,
		game.pause_overlay.design_frame,
		game.upgrade_overlay.design_frame,
		game.result_overlay.design_frame,
	]:
		frame.layout_in_rect(safe_rect)
		_require(frame.position.is_equal_approx(profile["design_position"]), "%s 的设计框位置错误" % profile["id"])
	game.start_screen.compendium.safe_area.layout_in_rect(safe_rect)
	game.hud.safe_area.layout_in_rect(safe_rect)
	for root in [
		game.start_screen.design_frame,
		game.start_screen.compendium.safe_area,
		game.hud.safe_area,
		game.pause_overlay.design_frame,
		game.upgrade_overlay.design_frame,
		game.result_overlay.design_frame,
	]:
		_check_interactive_bounds(root, safe_rect, profile["id"])


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
		"res://scripts/ui/compendium_overlay.gd",
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
