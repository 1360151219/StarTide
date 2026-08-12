extends Control

signal hero_selected(hero_id: String)
signal profile_changed

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const CharacterAssets = preload("res://scripts/ui/character_asset_catalog.gd")
const StatusPanel = preload("res://scripts/ui/character_status_panel.gd")
const EquipmentPanel = preload("res://scripts/ui/character_equipment_panel.gd")
const SkillPanel = preload("res://scripts/ui/character_skill_panel.gd")
const TITLE_PLAQUE := preload("res://assets/art/ui/character/character_title_plaque.png")
const SECTION_ICONS := {
	"status": preload("res://assets/art/ui/home/nav_icon_character.png"),
	"equipment": preload("res://assets/art/ui/home/nav_icon_expedition.png"),
	"skills": preload("res://assets/art/ui/home/nav_icon_compendium.png"),
}
const SECTION_IDS := ["status", "equipment", "skills"]
const SECTION_NAMES := {"status": "状态", "equipment": "装备", "skills": "技能"}
const HERO_SWITCHER_Y := 82.0
const SECTION_TABS_Y := 82.0
const PANEL_Y := 150.0

var records: RefCounted
var audio: Node
var selected_hero_id := "star_warden"
var current_section := "equipment"
var pending_initial_hero_id := ""
var content_active := false
var hero_buttons: Dictionary = {}
var section_buttons: Dictionary = {}
var section_panels: Dictionary = {}
var status_panel: Panel
var equipment_panel: Panel
var skill_panel: Panel
var hero_rig: Node
var section_tween: Tween
var title_plaque: TextureRect
var title_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hero_switcher()
	_build_sections()
	_build_panels()
	_update_section()
	if is_instance_valid(records):
		_apply_configuration()
	set_active(content_active)


func configure(run_records: RefCounted, initial_hero_id := "", audio_manager: Node = null) -> void:
	records = run_records
	audio = audio_manager
	pending_initial_hero_id = initial_hero_id
	if is_node_ready():
		_apply_configuration()


func _apply_configuration() -> void:
	status_panel.configure(records)
	equipment_panel.configure(records)
	skill_panel.configure(records)
	var record_hero := _active_hero_id()
	var requested := pending_initial_hero_id if HeroCatalog.ids().has(pending_initial_hero_id) else record_hero
	select_hero(requested if HeroCatalog.ids().has(requested) else HeroCatalog.ids()[0], false)


func select_hero(hero_id: String, persist := true) -> void:
	if not HeroCatalog.ids().has(hero_id):
		return
	if persist and is_instance_valid(records) and records.has_method("set_active_hero"):
		if not bool(records.set_active_hero(hero_id)):
			return
	selected_hero_id = hero_id
	_refresh_hero_buttons()
	refresh()
	if content_active and is_instance_valid(equipment_panel):
		equipment_panel.hero_stage.react()
	hero_selected.emit(hero_id)


func refresh() -> void:
	if not is_instance_valid(records):
		return
	var snapshot := _snapshot()
	status_panel.show_for(selected_hero_id, snapshot)
	equipment_panel.show_for(selected_hero_id, snapshot)
	skill_panel.show_for(selected_hero_id, snapshot)


func show_section(section_id: String) -> void:
	if section_panels.has(section_id):
		current_section = section_id
		_update_section()


func set_active(active: bool) -> void:
	content_active = active
	set_process(active)
	if is_instance_valid(equipment_panel):
		equipment_panel.set_active(active and current_section == "equipment")
	if active and is_instance_valid(equipment_panel) and equipment_panel.hero_stage != null:
		equipment_panel.hero_stage.react()


func _build_hero_switcher() -> void:
	title_plaque = TextureRect.new()
	title_plaque.name = "TitlePlaque"
	title_plaque.position = Vector2(18, 6)
	title_plaque.size = Vector2(250, 77)
	title_plaque.texture = TITLE_PLAQUE
	title_plaque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_plaque.stretch_mode = TextureRect.STRETCH_SCALE
	title_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_plaque)
	title_label = UiFactory.surface_label("角色中心", 26, UiFactory.INK)
	title_label.position = Vector2(72, 18)
	title_label.size = Vector2(174, 46)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiFactory.apply_inner_page_title(title_label, 26)
	title_plaque.add_child(title_label)
	var plate := Panel.new()
	plate.name = "HeroSwitcher"
	plate.position = Vector2(50, HERO_SWITCHER_Y)
	plate.size = Vector2(220, 56)
	plate.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(plate)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 2
	row.offset_top = 1
	row.offset_right = -2
	row.offset_bottom = -1
	row.add_theme_constant_override("separation", 8)
	plate.add_child(row)
	for hero_id in HeroCatalog.ids():
		var button := Button.new()
		button.text = ""
		button.icon = CharacterAssets.hero_avatar_texture(hero_id)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 44)
		button.custom_minimum_size = Vector2(104, 54)
		button.tooltip_text = str(HeroCatalog.hero(hero_id)["name"])
		button.accessibility_name = "切换至%s" % HeroCatalog.hero(hero_id)["name"]
		button.pressed.connect(_select_hero_from_ui.bind(hero_id))
		row.add_child(button)
		hero_buttons[hero_id] = button


func _build_sections() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(296, SECTION_TABS_Y)
	row.size = Vector2(168, 56)
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	for section_id in SECTION_IDS:
		var button := Button.new()
		button.text = ""
		button.icon = SECTION_ICONS[section_id]
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 32)
		button.custom_minimum_size = Vector2(52, 54)
		button.tooltip_text = SECTION_NAMES[section_id]
		button.accessibility_name = "%s页" % SECTION_NAMES[section_id]
		button.pressed.connect(_show_section_from_ui.bind(section_id))
		row.add_child(button)
		section_buttons[section_id] = button


func _build_panels() -> void:
	status_panel = StatusPanel.new()
	equipment_panel = EquipmentPanel.new()
	skill_panel = SkillPanel.new()
	for pair in [["status", status_panel], ["equipment", equipment_panel], ["skills", skill_panel]]:
		var panel: Panel = pair[1]
		panel.position = Vector2(18, PANEL_Y)
		add_child(panel)
		section_panels[pair[0]] = panel
	hero_rig = equipment_panel.hero_rig
	equipment_panel.equipment_changed.connect(_on_profile_changed)
	skill_panel.training_changed.connect(_on_profile_changed)


func _refresh_hero_buttons() -> void:
	for hero_id in hero_buttons:
		CharacterStyle.apply_ribbon_tab(hero_buttons[hero_id], hero_id == selected_hero_id)


func _update_section() -> void:
	if section_tween != null and section_tween.is_valid():
		section_tween.kill()
	for section_id in section_panels:
		var selected: bool = section_id == current_section
		section_panels[section_id].visible = selected
		CharacterStyle.apply_ribbon_tab(section_buttons[section_id], selected)
	var panel: Control = section_panels[current_section]
	panel.position.y = PANEL_Y + 6.0
	panel.modulate.a = 0.0
	section_tween = create_tween().set_parallel(true)
	section_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	section_tween.tween_property(panel, "position:y", PANEL_Y, 0.2)
	section_tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	if is_instance_valid(equipment_panel):
		equipment_panel.set_active(content_active and current_section == "equipment")


func _snapshot() -> Dictionary:
	return records.get_permanent_snapshot(selected_hero_id) if records.has_method("get_permanent_snapshot") else records.progression_snapshot(selected_hero_id)


func _active_hero_id() -> String:
	if is_instance_valid(records) and records.has_method("get_active_hero_id"):
		return str(records.get_active_hero_id())
	return str(records.last_hero_id) if is_instance_valid(records) else ""


func _select_hero_from_ui(hero_id: String) -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_select", -2.0)
	select_hero(hero_id)


func _show_section_from_ui(section_id: String) -> void:
	if section_id == current_section:
		return
	if is_instance_valid(audio):
		audio.play_sfx("ui_navigate", -2.0)
	show_section(section_id)


func _on_profile_changed(_message := "") -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_equip" if current_section == "equipment" else "ui_upgrade_skill", -1.0)
	refresh()
	if current_section == "equipment":
		equipment_panel.hero_stage.react()
	profile_changed.emit()
