extends SceneTree

const AudioManager = preload("res://scripts/audio_manager.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const FrontendShell = preload("res://scripts/ui/frontend_shell.gd")
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
		screen.route_map.selected_level_id == "level_01"
		and screen.route_map.title_label.text == "风铃草原",
		"远征首页没有渲染第一关数据"
	)
	_require(
		screen.bottom_bar.modulate.a == 1.0
		and screen.bottom_bar.base_texture_path() == "res://assets/art/ui/home/nav_flag_normal.png"
		and screen.bottom_bar.selection_texture_path() == "res://assets/art/ui/home/nav_flag_selected.png"
		and screen.bottom_bar.active_content_texture_path() == "res://assets/art/ui/home/nav_icon_expedition.png"
		and screen.bottom_bar.tab_plates.size() == 3,
		"开始页没有使用方案 D 的独立织带旗组件"
	)
	var tab_plate_instances := {}
	for page_id in screen.bottom_bar.tab_plates:
		tab_plate_instances[page_id] = screen.bottom_bar.tab_plates[page_id].get_instance_id()
	var home_shell_instances := HomeShellContract.snapshot(screen)
	_require(
		screen.bottom_bar.tab_plates["start"].size == Vector2(102, 104)
		and screen.bottom_bar.tab_plates["start"].texture.resource_path == screen.bottom_bar.selection_texture_path()
		and screen.bottom_bar.glyphs["start"].texture.resource_path == screen.bottom_bar.active_content_texture_path()
		and screen.bottom_bar.tab_plates["character"].position.x < screen.bottom_bar.tab_plates["start"].position.x
		and bool(screen.bottom_bar.buttons["start"].get_meta("selected", false)),
		"远征选中态没有使用居中的象牙织带旗"
	)
	_require(screen.bottom_bar.current_page == "start" and screen.bottom_bar.buttons.size() == 3, "底部导航没有默认选中远征页")
	_require(
		screen.bottom_bar.buttons["start"].text == "远征"
		and screen.bottom_bar.buttons["character"].text == "角色"
		and screen.bottom_bar.buttons["compendium"].text == "图鉴",
		"远征底栏的三个主入口不完整"
	)
	_require(screen.route_map.animation_player.is_playing() and screen.route_map.compass_banner.texture.resource_path == "res://assets/art/ui/home/home_compass_banner.png", "远征路线动画或左上罗盘挂旗缺失")
	_require(screen.route_map.preview_hero.has_method("play_state"), "远征路线没有接入动态英雄")
	_require(screen.route_map.phase > 0.0, "远征路线画面没有随时间更新")
	_require(screen.route_map.route_pins.size() == 5, "远征路线没有配置五个生态节点")
	_require(screen.route_map.page_label.text == "1 / 5", "远征路线页码错误")
	_require(screen.route_map.expedition_brief.current_power_caption_label.text == "养成评分" and screen.route_map.detail_label.text == "1000", "大厅没有对齐展示养成评分")
	_require(screen.route_map.expedition_brief.recommended_caption_label.text == "建议评分" and screen.route_map.expedition_brief.recommended_label.text == "1000" and screen.route_map.expedition_brief.frame_texture_path() == "res://assets/art/ui/home/expedition_brief_frame.png", "远征简报没有对齐展示建议评分")
	_require(screen.route_map.expedition_brief.reward_title_label.text == "首通奖励" and screen.route_map.expedition_brief.title_label.position.x == 36.0 and screen.route_map.expedition_brief.page_label.position.x + screen.route_map.expedition_brief.page_label.size.x == 293.0 and screen.route_map.expedition_brief.current_power_label.position.x + screen.route_map.expedition_brief.current_power_label.size.x == 153.0 and screen.route_map.expedition_brief.reward_count_label.position.x + screen.route_map.expedition_brief.reward_count_label.size.x == 293.0, "远征简报文字没有落入结构安全区")
	_require(screen.route_map.expedition_brief.reward_icon.visible
		and screen.route_map.expedition_brief.reward_label.text == "萤翼航标" and screen.route_map.expedition_brief.reward_count_label.text == "×1" and screen.route_map.expedition_brief.recommended_icon.size == Vector2(24, 24) and screen.route_map.expedition_brief.recommended_icon.texture.resource_path == "res://assets/art/ui/home/brief_icon_recommended.png" and screen.route_map.expedition_brief.power_icon.texture.resource_path == "res://assets/art/ui/home/brief_icon_power.png" and screen.route_map.expedition_brief.first_clear_icon.texture.resource_path == "res://assets/art/ui/home/brief_icon_first_clear.png" and screen.route_map.expedition_brief.reward_icon.texture.resource_path == "res://assets/art/ui/home/brief_icon_reward.png", "首通奖励缺少图标或数量")
	screen.records.level_record("level_01")["wins"] = 1; screen.refresh_progress()
	_require(screen.route_map.expedition_brief.reward_title_label.text == "通关掉落" and screen.route_map.expedition_brief.reward_label.text == "随机装备" and screen.route_map.expedition_brief.reward_count_label.text == "×1–4" and screen.route_map.expedition_brief.reward_label.position.x + screen.route_map.expedition_brief.reward_label.size.x + 4.0 == screen.route_map.expedition_brief.reward_count_label.position.x, "通关掉落文案没有分列或间距错误")
	screen.records.level_record("level_01")["wins"] = 0; screen.refresh_progress()
	_require(
		bool(screen.route_map.route_pins[0].get("selected"))
		and not bool(screen.route_map.route_pins[0].get("locked"))
		and bool(screen.route_map.route_pins[1].get("locked")) and screen.route_map.route_pins[0].frame_texture_path() == "res://assets/art/ui/home/route_pin_selected.png" and screen.route_map.route_pins[0].icon_texture_path() == "res://assets/art/ui/home/route_icon_meadow.png" and screen.route_map.route_pins[1].icon_texture_path() == "res://assets/art/ui/home/route_icon_locked.png",
		"远征路线的选中态或锁定态错误"
	)
	_require(screen.start_button.position == Vector2(340, 744) and screen.start_button.size == Vector2(192, 192) and screen.start_button.caption.text == "出发" and screen.start_button.frame_texture_path() == "res://assets/art/ui/home/start_button_frame.png" and screen.start_button.sail_texture_path() == "res://assets/art/ui/home/start_button_sail.png", "出发按钮没有使用右下放大的独立罗盘与帆船组件")
	_require(screen.audio_settings.launcher_glyph.texture.resource_path == "res://assets/art/ui/home/settings_medallion.png", "全局声音入口没有使用设置圆章")
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
		bool(screen.bottom_bar.buttons["compendium"].get_meta("selected", false)),
		"图鉴页没有切换同一 BottomBar 的图鉴状态"
	)
	_require(
		screen.bottom_bar.tab_plates["compendium"].get_instance_id() == tab_plate_instances["compendium"]
		and screen.bottom_bar.tab_plates["compendium"].texture.resource_path == screen.bottom_bar.selection_texture_path(),
		"图鉴页没有复用同一个织带旗选中态组件"
	)
	_require(
		screen.bottom_bar.get_parent() == screen.global_chrome
		and screen.global_chrome.z_index > screen.compendium.z_index,
		"图鉴遮挡了全局底部导航的输入层"
	)
	_require(screen.bottom_bar.visible and not screen.compendium.collection_view.close_button.visible, "图鉴主页面仍使用临时弹层导航")
	_require(
		screen.compendium.collection_view.paper_sheet.get_node_or_null("SunlitFrame") != null
		and screen.compendium.tab_buttons["enemies"].get_node_or_null("SunlitFrame") != null,
		"图鉴外框或页签没有复用日光远征装饰组件"
	)
	for button in screen.bottom_bar.buttons.values():
		_require(button.is_visible_in_tree() and button.modulate.a > 0.99, "图鉴页丢失底部主导航入口")
	_require(screen.compendium.list.get_child_count() == 7, "锁定内容没有保留完整怪物图鉴槽位")
	_require(screen.compendium.list.get_child(0).get_node_or_null("SunlitFrame") != null, "图鉴内容卡没有复用日光远征装饰组件")
	_require(screen.compendium.tab_buttons["enemies"].text == "怪物 0/7", "怪物图鉴进度错误")
	_require(not bool(screen.compendium.list.get_child(0).get_meta("discovered", true)), "新存档错误显示怪物详情")
	screen.records.discover_content("enemies", "green_grub")
	screen.compendium.show_category("enemies")
	_require(screen.compendium.tab_buttons["enemies"].text == "怪物 1/7", "发现怪物后图鉴进度没有刷新")
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
	screen.route_map.route_pins[1].pressed.emit()
	_require(screen.selected_level_id == "level_02", "未解锁关卡不能预览")
	_require(screen.start_button.disabled, "未解锁关卡可以进入")
	_require(
		screen.lobby_view.visible
		and HomeShellContract.snapshot(screen) == home_shell_instances
		and screen.route_map.selected_level_id == "level_02"
		and screen.route_map.title_label.text == "金砂绿洲"
		and screen.route_map.page_label.text == "2 / 5"
		and bool(screen.bottom_bar.buttons["start"].get_meta("selected", false)),
		"切换关卡时替换了远征页面，而不是更新同一页面的数据"
	)
	_require(bool(screen.route_map.route_pins[1].get("locked")) and screen.route_map.preview_hero.visible, "锁定关卡没有保留路线节点和英雄")
	var touch := InputEventScreenTouch.new()
	touch.index = 8
	touch.pressed = true
	touch.position = Vector2(120, 180)
	screen.route_map._handle_pointer_input(touch)
	touch.pressed = false
	touch.position = Vector2(250, 180)
	screen.route_map._handle_pointer_input(touch)
	_require(screen.selected_level_id == "level_01", "远征地图区域右滑没有切换上一关")
	_require(bool(screen.route_map.route_pins[0].get("selected")), "返回首关后路线节点没有选中")
	_require(
		HomeShellContract.snapshot(screen) == home_shell_instances
		and screen.route_map.selected_level_id == "level_01"
		and screen.route_map.title_label.text == "风铃草原"
		and bool(screen.bottom_bar.buttons["start"].get_meta("selected", false)),
		"返回第一关时没有复用同一个远征页面"
	)
	_test_stable_route_nodes()
	screen.bottom_bar.buttons["character"].pressed.emit()
	_require(screen.character_page.visible and not screen.lobby_view.visible, "角色菜单没有切换到角色页")
	_require(
		bool(screen.bottom_bar.buttons["character"].get_meta("selected", false)),
		"角色页没有切换同一 BottomBar 的角色状态"
	)
	_require(
		screen.bottom_bar.tab_plates["character"].get_instance_id() == tab_plate_instances["character"]
		and screen.bottom_bar.tab_plates["character"].texture.resource_path == screen.bottom_bar.selection_texture_path(),
		"角色页没有复用同一个织带旗选中态组件"
	)
	_require(screen.character_page.hero_rig.current_state == "menu_react", "首次进入角色页没有播放可感知的互动动作")
	_require(not screen.route_map.animation_player.is_playing(), "离开大厅后路线动画仍在运行")
	screen.character_page.select_hero("ember_ranger")
	_require(screen.selected_hero_id == "ember_ranger" and screen.records.get_active_hero_id() == "ember_ranger", "英雄选择没有成为持久出战英雄")
	_require(screen.route_map.preview_hero.hero_id == "ember_ranger", "大厅路线角色没有同步当前英雄")
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
	_require(screen.character_page.status_panel.power_label.text.contains("养成评分"), "角色状态没有展示养成评分")
	screen.bottom_bar.buttons["start"].pressed.emit()
	_require(screen.lobby_view.visible and not screen.character_page.visible, "底部导航无法返回开始页")
	_require(
		HomeShellContract.snapshot(screen) == home_shell_instances
		and bool(screen.bottom_bar.buttons["start"].get_meta("selected", false)),
		"返回开始页后没有恢复同一个远征页面"
	)
	var equipped_power := int(screen.records.get_permanent_snapshot("ember_ranger")["power"]["total"])
	_require(screen.route_map.detail_label.text == str(equipped_power), "装备后的战力没有同步回大厅")
	screen.start_button.pressed.emit()
	_require(screen.expedition_confirm.visible and start_payload.is_empty(), "开始远征没有先打开出征确认")
	_require(screen.expedition_confirm.hero_label.text == "烬羽" and screen.expedition_confirm.level_label.text.contains("风铃草原") and screen.expedition_confirm.power_label.text.contains("养成评分") and screen.expedition_confirm.power_hint_label.text.contains("建议评分"), "出征确认没有展示角色、关卡或建议评分语义")
	_require(not screen.bottom_bar.visible, "出征确认期间底部导航仍可误触")
	screen.expedition_confirm.confirm_button.pressed.emit()
	_require(start_payload == ["ember_ranger", "level_01"], "开始事件没有保留 hero_id/level_id 接口")
	if not failed:
		print("START_UI_OK frontend=route_map character=status_equipment_skills active_hero=persisted destinations=5 swipe=true compendium=discovery")
	quit(1 if failed else 0)


func _on_start_requested(hero_id: String, level_id: String) -> void:
	start_payload = [hero_id, level_id]


func _test_stable_route_nodes() -> void:
	var pin_instances: Array[int] = []
	for pin in screen.route_map.route_pins:
		pin_instances.append(pin.get_instance_id())
	var child_count: int = screen.route_map.get_child_count()
	screen.route_map.refresh()
	var refreshed_instances: Array[int] = []
	for pin in screen.route_map.route_pins:
		refreshed_instances.append(pin.get_instance_id())
	_require(LevelCatalog.all().size() == 5, "五生态远征地图与战役关卡数量不一致")
	_require(screen.route_map.get_child_count() == child_count and refreshed_instances == pin_instances, "刷新进度时替换了远征路线节点")


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("START_UI_FAILED: " + message)
