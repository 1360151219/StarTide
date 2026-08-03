extends SceneTree

const AudioManager = preload("res://scripts/audio_manager.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const FrontendShell = preload("res://scripts/ui/frontend_shell.gd")
const LevelSelector = preload("res://scripts/ui/level_selector.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const HomeShellContract = preload("res://tools/support/home_shell_contract.gd")

var failed := false
var frame_count := 0
var start_payload: Array[String] = []
var screen: CanvasLayer


func _initialize() -> void:
	var host := Node.new()
	root.add_child(host)
	var audio := AudioManager.new()
	host.add_child(audio)
	screen = FrontendShell.new()
	host.add_child(screen)
	screen.configure(RunRecords.new(""), audio)
	screen.start_requested.connect(_on_start_requested)
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count < 3:
		return
	_require(screen.lobby_view.visible and not screen.character_page.visible, "默认页面不是关卡大厅")
	_require(
		screen.level_preview.current_level_id == "level_01"
		and screen.level_preview.title_label.text == "风铃草原",
		"远征首页没有渲染第一关数据"
	)
	_require(
		screen.bottom_bar.modulate.a == 1.0
		and screen.bottom_bar.base_texture_path().ends_with("bottom_bar_base.png")
		and screen.bottom_bar.selection_texture_path().ends_with("bottom_bar_selection.png")
		and screen.bottom_bar.active_content_texture_path().ends_with("bottom_bar_content_start.png"),
		"开始页没有由全局 BottomBar 承载远征状态皮肤"
	)
	var selection_instance_id: int = screen.bottom_bar.selection.get_instance_id()
	var selection_size: Vector2 = screen.bottom_bar.selection.size
	var home_shell_instances := HomeShellContract.snapshot(screen)
	_require(
		selection_size == Vector2(128, 112)
		and is_equal_approx(screen.bottom_bar.selection.position.x + selection_size.x * 0.5, 118.0),
		"远征选中态没有使用统一选中组件"
	)
	_require(screen.bottom_bar.current_page == "start" and screen.bottom_bar.buttons.size() == 3, "底部导航没有默认选中远征页")
	_require(
		screen.bottom_bar.buttons["start"].text == "远征"
		and screen.bottom_bar.buttons["character"].text == "角色"
		and screen.bottom_bar.buttons["compendium"].text == "图鉴",
		"绘本底栏的三个主入口不完整"
	)
	_require(screen.level_preview.animation_player.is_playing(), "动态关卡预览没有播放")
	_require(screen.level_preview.preview_hero.has_method("play_state"), "关卡预览没有接入动态英雄")
	_require(screen.level_preview.phase > 0.0, "关卡预览画面没有随时间更新")
	_require(screen.level_selector.page_buttons.size() == 3, "轮播没有固定复用三个页面节点")
	_require(screen.level_selector.page_label.text == "第 1 / 3 关", "轮播页码错误")
	_require(screen.level_selector.detail_label.text.contains("当前战力 1000"), "大厅没有展示当前战力")
	_require(screen.level_selector.expedition_brief.recommended_label.text == "推荐战力 1000", "远征简报没有展示推荐战力")
	_require(screen.level_selector.expedition_brief.reward_title_label.text == "首通奖励", "远征简报没有展示首通奖励")
	_require(
		screen.level_selector.expedition_brief.reward_icon.visible
		and screen.level_selector.expedition_brief.reward_label.text.ends_with("×1"),
		"首通奖励缺少图标或数量"
	)
	_require(screen.level_selector.left_button.disabled and not screen.level_selector.right_button.disabled, "轮播首尾按钮状态错误")
	var caption_center: Vector2 = screen.start_button.caption.position + screen.start_button.caption.size * 0.5
	_require(caption_center.is_equal_approx(screen.start_button.size * 0.5), "踏入星门文案没有居中")
	screen.audio_settings.launcher_button.pressed.emit()
	_require(screen.audio_settings.settings_card.visible, "全局声音入口无法打开声音设置")
	screen.audio_settings.close_popup()
	screen.open_compendium("enemies")
	_require(screen.current_page == "compendium" and screen.bottom_bar.current_page == "compendium", "图鉴没有成为第三主导航")
	_require(
		screen.audio_settings.visible
		and screen.audio_settings.get_parent() == screen.global_chrome,
		"声音组件没有作为全局前台组件复用"
	)
	_require(
		screen.bottom_bar.active_content_texture_path().ends_with("bottom_bar_content_compendium.png"),
		"图鉴页没有切换同一 BottomBar 的图鉴状态"
	)
	_require(
		screen.bottom_bar.selection.get_instance_id() == selection_instance_id
		and screen.bottom_bar.selection.size == selection_size
		and is_equal_approx(screen.bottom_bar.selection.position.x + selection_size.x * 0.5, 408.0),
		"图鉴页没有复用同一个选中态组件"
	)
	_require(
		screen.bottom_bar.get_parent() == screen.global_chrome
		and screen.global_chrome.z_index > screen.compendium.z_index,
		"图鉴遮挡了全局底部导航的输入层"
	)
	_require(screen.bottom_bar.visible and not screen.compendium.collection_view.close_button.visible, "图鉴主页面仍使用临时弹层导航")
	for button in screen.bottom_bar.buttons.values():
		_require(button.is_visible_in_tree() and button.modulate.a > 0.99, "图鉴页丢失底部主导航入口")
	_require(screen.compendium.list.get_child_count() == 4, "锁定内容没有保留图鉴槽位")
	_require(screen.compendium.tab_buttons["enemies"].text == "怪物 0/4", "怪物图鉴进度错误")
	_require(not bool(screen.compendium.list.get_child(0).get_meta("discovered", true)), "新存档错误显示怪物详情")
	screen.records.discover_content("enemies", "green_grub")
	screen.compendium.show_category("enemies")
	_require(screen.compendium.tab_buttons["enemies"].text == "怪物 1/4", "发现怪物后图鉴进度没有刷新")
	_require(bool(screen.compendium.list.get_child(0).get_meta("discovered", false)), "发现怪物后图鉴详情仍被锁定")
	screen.compendium.show_category("relics")
	_require(screen.compendium.list.get_child_count() == 6, "遗物没有保留全部图鉴槽位")
	_require(screen.compendium.tab_buttons["relics"].text == "遗物 0/6", "遗物图鉴进度错误")
	_require(not bool(screen.compendium.list.get_child(0).get_meta("discovered", true)), "未获得遗物错误显示详情")
	screen.records.discover_content("skills", "star_lance")
	screen.compendium.show_category("skills")
	var discovered_skill_card: Panel = screen.compendium.list.get_child(0)
	var skill_description: Label = discovered_skill_card.get_child(3)
	_require(skill_description.text.contains("分支 · ？？？"), "未选过的技能分支提前显示详情")
	screen.bottom_bar.buttons["character"].pressed.emit()
	_require(
		screen.current_page == "character"
		and screen.character_page.visible
		and not screen.compendium.visible,
		"图鉴页无法通过全局底栏切换到角色页"
	)
	screen.bottom_bar.buttons["compendium"].pressed.emit()
	screen.bottom_bar.buttons["start"].pressed.emit()
	_require(
		screen.current_page == "start"
		and screen.lobby_view.visible
		and not screen.compendium.visible,
		"图鉴页无法通过全局底栏切回远征页"
	)
	screen.level_selector.right_button.pressed.emit()
	_require(screen.selected_level_id == "level_02", "未解锁关卡不能预览")
	_require(screen.start_button.disabled, "未解锁关卡可以进入")
	_require(
		screen.lobby_view.visible
		and HomeShellContract.snapshot(screen) == home_shell_instances
		and screen.level_preview.current_level_id == "level_02"
		and screen.level_preview.title_label.text == "金砂绿洲"
		and screen.level_selector.page_label.text == "第 2 / 3 关"
		and screen.bottom_bar.active_content_texture_path().ends_with("bottom_bar_content_start.png"),
		"切换关卡时替换了远征页面，而不是更新同一页面的数据"
	)
	_require(screen.level_preview.lock_panel.visible and screen.level_preview.preview_hero.visible, "锁定关卡没有保留可见预览")
	var touch := InputEventScreenTouch.new()
	touch.index = 8
	touch.pressed = true
	touch.position = Vector2(120, 180)
	screen.level_preview._gui_input(touch)
	touch.pressed = false
	touch.position = Vector2(250, 180)
	screen.level_preview._gui_input(touch)
	_require(screen.selected_level_id == "level_01", "关卡预览区域右滑没有切换上一关")
	_require(screen.level_selector.left_button.disabled, "返回首关后左箭头仍可用")
	_require(
		HomeShellContract.snapshot(screen) == home_shell_instances
		and screen.level_preview.current_level_id == "level_01"
		and screen.level_preview.title_label.text == "风铃草原"
		and screen.bottom_bar.active_content_texture_path().ends_with("bottom_bar_content_start.png"),
		"返回第一关时没有复用同一个远征页面"
	)
	_test_constant_carousel_nodes()
	screen.bottom_bar.buttons["character"].pressed.emit()
	_require(screen.character_page.visible and not screen.lobby_view.visible, "角色菜单没有切换到角色页")
	_require(
		screen.bottom_bar.active_content_texture_path().ends_with("bottom_bar_content_character.png"),
		"角色页没有切换同一 BottomBar 的角色状态"
	)
	_require(
		screen.bottom_bar.selection.get_instance_id() == selection_instance_id
		and screen.bottom_bar.selection.size == selection_size
		and is_equal_approx(screen.bottom_bar.selection.position.x + selection_size.x * 0.5, 270.0),
		"角色页没有复用同一个选中态组件"
	)
	_require(screen.character_page.hero_rig.current_state == "menu_react", "首次进入角色页没有播放可感知的互动动作")
	_require(not screen.level_preview.animation_player.is_playing(), "离开大厅后预览仍在运行")
	screen.character_page.select_hero("ember_ranger")
	_require(screen.selected_hero_id == "ember_ranger" and screen.records.get_active_hero_id() == "ember_ranger", "英雄选择没有成为持久出战英雄")
	_require(screen.level_preview.preview_hero.hero_id == "ember_ranger", "大厅动态预览没有同步当前英雄")
	screen.character_page.show_section("skills")
	_require(screen.character_page.skill_panel.visible and screen.character_page.skill_panel.skill_buttons.size() == 3, "角色页技能栏目不完整")
	screen.records.grant_equipment("apprentice_starwand")
	screen.character_page.refresh()
	screen.character_page.show_section("equipment")
	_require(screen.character_page.equipment_panel.visible and screen.character_page.equipment_panel.inventory_buttons[0].visible, "角色页装备背包没有刷新")
	screen.character_page.equipment_panel.inventory_buttons[0].pressed.emit()
	_require(screen.character_page.equipment_panel.detail_sheet.visible, "点击装备没有进入详情确认状态")
	_require(str(screen.records.equipment_loadout_snapshot("ember_ranger")["weapon"]).is_empty(), "仅选择装备就错误修改了存档")
	screen.character_page.equipment_panel.detail_sheet.action_button.pressed.emit()
	_require(not str(screen.records.equipment_loadout_snapshot("ember_ranger")["weapon"]).is_empty(), "角色页无法装备物品")
	screen.character_page.show_section("status")
	_require(screen.character_page.status_panel.power_label.text.contains("战力"), "角色状态没有展示战力")
	screen.bottom_bar.buttons["start"].pressed.emit()
	_require(screen.lobby_view.visible and not screen.character_page.visible, "底部导航无法返回开始页")
	_require(
		HomeShellContract.snapshot(screen) == home_shell_instances
		and screen.bottom_bar.active_content_texture_path().ends_with("bottom_bar_content_start.png"),
		"返回开始页后没有恢复同一个远征页面"
	)
	var equipped_power := int(screen.records.get_permanent_snapshot("ember_ranger")["power"]["total"])
	_require(screen.level_selector.detail_label.text.contains("当前战力 %d" % equipped_power), "装备后的战力没有同步回大厅")
	screen.start_button.pressed.emit()
	_require(screen.expedition_confirm.visible and start_payload.is_empty(), "踏入星门没有先打开出征确认")
	_require(screen.expedition_confirm.hero_label.text == "烬羽" and screen.expedition_confirm.level_label.text.contains("风铃草原"), "出征确认没有展示当前英雄或关卡")
	_require(not screen.bottom_bar.visible, "出征确认期间底部导航仍可误触")
	screen.expedition_confirm.confirm_button.pressed.emit()
	_require(start_payload == ["ember_ranger", "level_01"], "开始事件没有保留 hero_id/level_id 接口")
	if not failed:
		print("START_UI_OK frontend=bottom_bar character=status_equipment_skills active_hero=persisted preview=rig carousel=3 swipe=true compendium=discovery")
	quit(1 if failed else 0)


func _on_start_requested(hero_id: String, level_id: String) -> void:
	start_payload = [hero_id, level_id]


func _test_constant_carousel_nodes() -> void:
	var carousel := LevelSelector.new()
	root.add_child(carousel)
	var templates := LevelCatalog.all()
	var simulated_levels: Array[LevelConfig] = []
	for index in range(12):
		var level := templates[index % templates.size()].duplicate(true) as LevelConfig
		level.level_id = "carousel_%02d" % (index + 1)
		level.display_name = "模拟关卡 %d" % (index + 1)
		simulated_levels.append(level)
	carousel.configure(simulated_levels, screen.records, simulated_levels[0].level_id)
	var child_count := carousel.get_child_count()
	_require(carousel.page_buttons.size() == 3, "12关轮播创建了超过三个页面节点")
	carousel.configure(LevelCatalog.all(), screen.records, "level_01")
	_require(carousel.get_child_count() == child_count and carousel.page_buttons.size() == 3, "轮播节点数量随关卡数量变化")
	carousel.queue_free()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("START_UI_FAILED: " + message)
