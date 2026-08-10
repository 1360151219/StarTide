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
		page.get_node("HeroSwitcher").size.x == 504.0
		and equipment.hero_stage.power_label.text.is_valid_int(),
		"角色页右上角仍保留重复战力，或角色下方战力不是独立主数值"
	)
	_require(
		equipment.hero_stage.power_label.get_theme_font_size("font_size") == 30
		and equipment.hero_stage.power_label.get_theme_color("font_color").is_equal_approx(CharacterStyle.POWER),
		"角色下方战力没有使用醒目的专属字体样式"
	)
	_require(
		page.hero_buttons["star_warden"].get_node_or_null("SunlitFrame") != null
		and page.section_buttons["equipment"].get_node_or_null("SunlitFrame") != null
		and equipment.get_node_or_null("SunlitFrame") != null,
		"角色中心没有复用日光远征装饰组件"
	)
	_require(equipment.hero_stage.hero_rig.display_height >= 180.0, "装备舞台英雄仍是缩略头像")
	_require(equipment.slot_buttons.size() == 3, "装备槽没有按目录完整生成")
	_require(not equipment.slot_buttons["weapon"].empty_mark is Label, "空装备槽仍使用文字占位符")
	_require(equipment.inventory_grid.columns == 4 and equipment.inventory_buttons.size() == 3, "新手装备没有进入四列背包")
	_require(equipment.filter_buttons.size() == 4, "装备背包缺少槽位筛选")
	var rare: Dictionary = records.grant_equipment("windstring_bow")
	records.grant_equipment("crystal_vest")
	records.grant_equipment("timeglass_charm")
	var top: Dictionary = records.grant_equipment("apprentice_starwand", "top")
	page.refresh()
	_require(equipment.inventory_buttons.size() == 7, "三种品质装备没有完整进入背包网格")
	_require(equipment.inventory_grid.get_combined_minimum_size().y <= equipment.inventory_grid.get_parent().size.y + 0.1, "四列两行装备卡不能完整显示")
	var common_card: Button = _card_by_id(equipment, "starter-weapon")
	var rare_card: Button = _card_by_id(equipment, str(rare["instance_id"]))
	var top_card: Button = _card_by_id(equipment, str(top["instance_id"]))
	_require(common_card != null and top_card != null, "普通或顶级装备没有进入背包")
	_require(rare_card != null, "稀有装备没有进入背包")
	_require(
		common_card.get_node_or_null("SunlitFrame") != null
		and rare_card.get_node_or_null("SunlitFrame") != null
		and top_card.get_node_or_null("SunlitFrame") != null,
		"装备品质卡没有复用日光远征装饰组件"
	)
	_require(common_card.get_theme_stylebox("normal").bg_color.is_equal_approx(CharacterStyle.COMMON_BACKGROUND), "普通装备没有使用灰色背景")
	_require(rare_card.get_theme_stylebox("normal").bg_color.is_equal_approx(CharacterStyle.RARE_BACKGROUND), "稀有装备没有使用绿色背景")
	_require(top_card.get_theme_stylebox("normal").bg_color.is_equal_approx(CharacterStyle.TOP_BACKGROUND), "顶级装备没有使用紫色背景")
	_require(rare_card.get_theme_stylebox("normal").border_color.is_equal_approx(CharacterStyle.RARE_BORDER), "稀有装备边框没有与品质背景统一")
	_require(rare_card.rarity_label.get_theme_color("font_color").is_equal_approx(CharacterStyle.RARE), "稀有装备没有保留品质识别色")
	rare_card.pressed.emit()
	_require(rare_card.get_theme_stylebox("normal").bg_color.is_equal_approx(CharacterStyle.RARE_BACKGROUND) and rare_card.get_theme_stylebox("normal").border_color.is_equal_approx(CharacterStyle.RARE_BORDER), "选中态覆盖了装备品质颜色")
	_require(equipment.detail_sheet.visible and equipment.detail_sheet.action_button.text == "装备", "装备详情没有明确操作")
	_require(equipment.detail_sheet.get_theme_stylebox("panel").bg_color.is_equal_approx(CharacterStyle.RARE_BACKGROUND), "装备详情没有延续品质背景")
	_require(equipment.detail_sheet.upgrade_button.disabled and equipment.detail_sheet.lock_button.text == "锁定", "装备详情没有提供等级升级与材料保护入口")
	_require(str(records.equipment_loadout_snapshot("star_warden")["weapon"]).is_empty(), "选择装备就错误修改了装配")
	equipment.detail_sheet.action_button.pressed.emit()
	_require(str(records.equipment_loadout_snapshot("star_warden")["weapon"]) == str(rare["instance_id"]), "确认装备没有写入装配")
	_require(
		equipment.hero_stage.power_delta_label.visible
		and equipment.hero_stage.power_delta_label.text.begins_with("战力 +")
		and equipment.hero_stage.power_delta_glyph.glyph_id == "up"
		and equipment.hero_stage.power_delta_feedback.visible
		and equipment.hero_stage.power_tween != null,
		"战力提升后没有播放数值增长提示动画"
	)
	_require(equipment.slot_buttons["weapon"].get_theme_stylebox("normal").bg_color.is_equal_approx(CharacterStyle.RARE_BACKGROUND), "已装备槽位没有复用品质背景")
	page.select_hero("ember_ranger")
	var occupied_card: Button = _card_by_id(equipment, str(rare["instance_id"]))
	_require(occupied_card != null and occupied_card.owner_label.text.contains("星潮守望者"), "跨英雄占用装备被隐藏")
	occupied_card.pressed.emit()
	_require(equipment.detail_sheet.action_button.disabled, "其他英雄使用中的装备仍可直接穿戴")
	page.show_section("status")
	_require(page.status_panel.metric_values.size() == 4 and page.status_panel.breakdown_values.size() == 4, "状态页没有使用分层属性卡")
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
			and page.skill_panel.skill_names[locked_index].text == "未发现技艺"
			and page.skill_panel.skill_effects[locked_index].text == "远征中获得后开放培养"
			and not page.skill_panel.skill_buttons[locked_index].visible,
			"锁定技能没有使用左侧锁徽章与连续说明行"
		)
	_require(page.skill_panel.status_label.text.contains("远征中发现"), "技能解锁说明没有收敛为单条全局提示")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(storage_path))
	if not failed:
		print("CHARACTER_UI_OK hero_stage=188 slots=3 inventory_grid=4 filters=4 detail_confirm=true rarity_backgrounds=3 ownership=true")
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
