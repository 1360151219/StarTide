extends SceneTree

const AudioManager = preload("res://scripts/audio_manager.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const FrontendShell = preload("res://scripts/ui/frontend_shell.gd")
const RunRecords = preload("res://scripts/run_records.gd")

var failed := false
var frame_count := 0
var screen: CanvasLayer
var records: RefCounted
var storage_path := ""


func _initialize() -> void:
	storage_path = "user://character_ui_%d.cfg" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(storage_path))
	var host := Node.new()
	root.add_child(host)
	var audio := AudioManager.new()
	host.add_child(audio)
	records = RunRecords.new(storage_path)
	screen = FrontendShell.new()
	host.add_child(screen)
	screen.configure(records, audio)
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count < 4:
		return
	screen.show_page("character")
	var page = screen.character_page
	var equipment = page.equipment_panel
	_require(page.current_section == "equipment", "角色中心没有默认展示装备舞台")
	_require(
		page.get_node("HeroSwitcher").size == Vector2(220, 56)
		and page.title_plaque.texture.resource_path == "res://assets/art/ui/character/character_title_plaque.png"
		and equipment.hero_stage.power_label.text.is_valid_int(),
		"角色标题签、英雄切换或角色下方战力结构不正确"
	)
	_require(
		screen.screen_background.visible
		and screen.screen_background.texture.resource_path == "res://assets/art/ui/character/character_camp_backdrop.png",
		"角色页仍泄漏首页地图，或没有使用独立营地背景"
	)
	_require(
		equipment.hero_stage.power_label.get_theme_font_size("font_size") == 36
		and equipment.hero_stage.power_label.get_theme_color("font_color").is_equal_approx(CharacterStyle.POWER),
		"角色下方战力没有使用醒目的专属字体样式"
	)
	_require(
		equipment.hero_stage.power_plate.size == Vector2(304, 76)
		and equipment.hero_stage.power_plate.get_node("PowerPlateFrame").texture.resource_path == "res://assets/art/ui/character/power_plate_frame.png"
		and equipment.hero_stage.level_label.get_theme_font_size("font_size") == 22
		and equipment.hero_stage.level_label.get_theme_font("font").resource_path == "res://assets/fonts/SmileySans-Oblique.otf",
		"等级与战力没有进入新的远征战力牌"
	)
	_require(
		page.hero_buttons["star_warden"].get_node_or_null("SunlitFrame") != null
		and page.section_buttons["equipment"].get_node_or_null("SunlitFrame") != null
		and page.hero_buttons["star_warden"].icon is AtlasTexture
		and page.hero_buttons["star_warden"].icon.atlas.resource_path == "res://assets/art/characters/star_tide_warden.png"
		and page.section_buttons["status"].icon.resource_path == "res://assets/art/ui/home/nav_icon_character.png"
		and equipment.hero_stage.get_node("StageFrame").texture.resource_path == "res://assets/art/ui/character/hero_stage_frame.png"
		and equipment.hero_stage.get_node("StageCanvas").texture.resource_path == "res://assets/art/ui/character/hero_stage_canvas.png",
		"角色中心没有复用英雄头像、首页图标与日光远征舞台构件"
	)
	_require(equipment.hero_stage.hero_rig.display_height >= 240.0, "装备舞台英雄仍是缩略头像")
	_require(
		equipment.slot_buttons.size() == 3
		and equipment.hero_stage.locked_slot_cards.size() == 3
		and equipment.slot_buttons["weapon"].size == Vector2(64, 64),
		"装备舞台没有形成左三右三的六槽结构"
	)
	_require(not equipment.slot_buttons["weapon"].empty_mark is Label, "空装备槽仍使用文字占位符")
	_require(
		equipment.inventory_grid.columns == 5
		and equipment.inventory_grid.custom_minimum_size.x == 472.0
		and equipment.inventory_buttons.size() == 3,
		"新手装备没有进入五列正方形背包"
	)
	_require(
		equipment.filter_buttons.size() == 4
		and equipment.filter_buttons["weapon"].icon.resource_path == "res://assets/art/ui/character/filter_icon_weapon.png"
		and equipment.inventory_sheet.get_node("TrayFrame").texture.resource_path == "res://assets/art/ui/character/inventory_tray_frame.png",
		"装备背包缺少正式筛选图标或帆布托盘"
	)
	_require(
		equipment.size == Vector2(504, 682)
		and equipment.inventory_sheet.position == Vector2(-12, 418)
		and equipment.inventory_sheet.size == Vector2(524, 302)
		and equipment.count_label.position == Vector2(414, 36)
		and equipment.count_label.size == Vector2(86, 24)
		and equipment.status_label.position.x + equipment.status_label.size.x <= 426.0
		and equipment.detail_sheet.size == Vector2(496, 244),
		"装备托盘布局异常，或背包数量没有固定在筛选行安全区"
	)
	var rare: Dictionary = records.grant_equipment("windstring_bow")
	records.grant_equipment("crystal_vest")
	records.grant_equipment("timeglass_charm")
	var top: Dictionary = records.grant_equipment("apprentice_starwand", "top")
	page.refresh()
	_require(equipment.inventory_buttons.size() == 7, "三种品质装备没有完整进入背包网格")
	_require(
		equipment.inventory_buttons[0].size == Vector2(88, 88)
		and equipment.inventory_grid.get_combined_minimum_size().y >= 184.0,
		"装备背包没有保持一行五格与纵向滚动"
	)
	var common_card: Button = _card_by_id(equipment, "starter-weapon")
	var rare_card: Button = _card_by_id(equipment, str(rare["instance_id"]))
	var top_card: Button = _card_by_id(equipment, str(top["instance_id"]))
	_require(common_card != null and top_card != null, "普通或顶级装备没有进入背包")
	_require(rare_card != null, "稀有装备没有进入背包")
	_require(
		common_card.background_view.texture.resource_path == "res://assets/art/ui/character/quality_cell_common.png"
		and rare_card.background_view.texture.resource_path == "res://assets/art/ui/character/quality_cell_rare.png"
		and top_card.background_view.texture.resource_path == "res://assets/art/ui/character/quality_cell_top.png",
		"装备品质卡没有使用三档独立正式方格"
	)
	_require(CharacterStyle.COMMON_BACKGROUND == Color("c9cdca"), "普通装备没有使用主动灰帆布语义")
	_require(CharacterStyle.RARE_BACKGROUND == Color("dff5e7") and CharacterStyle.RARE == Color("42b873"), "稀有装备没有使用鲜绿品质语义")
	_require(CharacterStyle.TOP_BACKGROUND == Color("fff0b2"), "顶级装备没有使用日照金语义")
	_require(CharacterStyle.COMMON != CharacterStyle.LOCKED and CharacterStyle.POWER_LOSS != Color("e45b5b"), "普通品质或战力下降仍复用了禁用/危险语义色")
	_require(common_card.icon_view.size.x == 56.0, "装备图标主体占比不符合五列方格规范")
	rare_card.pressed.emit()
	_require(
		rare_card.background_view.texture.resource_path == "res://assets/art/ui/character/quality_cell_rare.png"
		and rare_card.selection_frame.visible,
		"选中态覆盖了装备品质结构"
	)
	_require(equipment.detail_sheet.visible and equipment.detail_sheet.action_button.text == "装备", "装备详情没有明确操作")
	_require(equipment.detail_sheet.get_theme_stylebox("panel").bg_color.is_equal_approx(CharacterStyle.RARE_BACKGROUND), "装备详情没有延续品质背景")
	_require(equipment.detail_sheet.upgrade_button.disabled and equipment.detail_sheet.lock_button.text == "锁定", "装备详情没有提供等级升级与材料保护入口")
	_require(str(records.equipment_loadout_snapshot("star_warden")["weapon"]).is_empty(), "选择装备就错误修改了装配")
	equipment.detail_sheet.action_button.pressed.emit()
	_require(str(records.equipment_loadout_snapshot("star_warden")["weapon"]) == str(rare["instance_id"]), "确认装备没有写入装配")
	_require(
		equipment.hero_stage.power_delta_label.visible
		and equipment.hero_stage.power_delta_label.text.begins_with("评分 +")
		and equipment.hero_stage.power_delta_glyph.glyph_id == "up"
		and equipment.hero_stage.power_delta_feedback.visible
		and equipment.hero_stage.power_tween != null,
		"战力提升后没有播放数值增长提示动画"
	)
	_require(equipment.slot_buttons["weapon"].background_view.texture.resource_path == "res://assets/art/ui/character/quality_cell_rare.png", "已装备槽位没有复用品质方格")
	page.select_hero("ember_ranger")
	var occupied_card: Button = _card_by_id(equipment, str(rare["instance_id"]))
	_require(
		occupied_card != null
		and occupied_card.owner_backing.visible
		and occupied_card.owner_avatar.texture is AtlasTexture
		and occupied_card.owner_avatar.texture.atlas.resource_path == "res://assets/art/characters/star_tide_warden.png",
		"跨英雄占用装备没有显示右上归属头像"
	)
	occupied_card.pressed.emit()
	_require(equipment.detail_sheet.action_button.disabled, "其他英雄使用中的装备仍可直接穿戴")
	page.show_section("status")
	_require(
		page.status_panel.metric_values.size() == 4
		and page.status_panel.metric_values.has("attack")
		and page.status_panel.metric_values.has("health")
		and page.status_panel.metric_values.has("speed")
		and page.status_panel.metric_values.has("frequency")
		and page.status_panel.size.y == 506.0,
		"状态页没有保留四项可结算核心属性"
	)
	_require(
		page.status_panel.metric_values["attack"].text.is_valid_float()
		and not page.status_panel.metric_values["attack"].text.contains("%")
		and page.status_panel.metric_values["health"].text.is_valid_float()
		and page.status_panel.metric_values["speed"].text.is_valid_float()
		and page.status_panel.metric_values["frequency"].text.ends_with("×")
		and page.status_panel.level_label.text.contains("技能点"),
		"状态页仍以百分比代替攻击力，或遗漏实际生命、移速与施法频率"
	)
	_require(page.status_panel.metric_values["attack"].tooltip_text.contains("通用伤害指数") and page.status_panel.metric_values["attack"].tooltip_text.contains("局内等级"), "攻击力没有说明永久指数语义及局内倍率边界")
	_require(page.status_panel.name_label.get_theme_font("font").resource_path == "res://assets/fonts/SmileySans-Oblique.otf", "角色页重要标题没有使用 Smiley Sans")
	page.show_section("skills")
	_require(page.skill_panel.skill_cards.size() == 3 and page.skill_panel.skill_buttons.size() == 3, "技能培养卡不完整")
	_require(not page.skill_panel.skill_locks[1] is Label, "未发现技能仍使用空心菱形占位符")
	var locked_index := -1
	for index in range(page.skill_panel.skill_locks.size()):
		if page.skill_panel.skill_locks[index].visible:
			locked_index = index
			break
	_require(locked_index >= 0, "未发现技能没有显示锁定图形")
	if locked_index >= 0:
		_require(
			page.skill_panel.skill_locks[locked_index].size.x >= 60.0
			and page.skill_panel.skill_locks[locked_index].position.x < page.skill_panel.skill_names[locked_index].position.x
			and page.skill_panel.skill_names[locked_index].visible
			and page.skill_panel.skill_names[locked_index].text == "未发现"
			and not page.skill_panel.skill_effects[locked_index].visible
			and not page.skill_panel.skill_buttons[locked_index].visible,
			"锁定技能没有使用左侧锁徽章与精简文案"
		)
	_require(page.skill_panel.status_label.text == "远征发现后可培养", "技能解锁说明没有收敛为单条全局提示")
	screen.show_page("start")
	_require(screen.screen_background.texture.resource_path == "res://assets/art/sunlit/backgrounds/expedition_route_map.png", "离开角色页后没有恢复首页地图")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(storage_path))
	if not failed:
		print("CHARACTER_UI_OK title_asset=true power_plate=true hero_stage=250 slots=6 inventory_grid=5 tray_height=302 quality_assets=3 ownership_avatar=true")
	quit(1 if failed else 0)


func _card_by_id(equipment: Panel, instance_id: String) -> Button:
	for card in equipment.inventory_buttons:
		if str(card.get_meta("instance_id", "")) == instance_id:
			return card
	return null


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("CHARACTER_UI_FAILED: " + message)
