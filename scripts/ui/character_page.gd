extends Control

signal hero_selected(hero_id: String)
signal profile_changed

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const StatusPanel = preload("res://scripts/ui/character_status_panel.gd")
const EquipmentPanel = preload("res://scripts/ui/character_equipment_panel.gd")
const SkillPanel = preload("res://scripts/ui/character_skill_panel.gd")
const SECTION_IDS := ["status", "equipment", "skills"]
const SECTION_NAMES := {"status": "状态", "equipment": "装备", "skills": "技能"}

var records: RefCounted
var selected_hero_id := "star_warden"
var current_section := "equipment"
var pending_initial_hero_id := ""
var content_active := false
var hero_buttons: Dictionary = {}
var section_buttons: Dictionary = {}
var section_panels: Dictionary = {}
var power_label: Label
var status_panel: Panel
var equipment_panel: Panel
var skill_panel: Panel
var hero_rig: Node
var section_tween: Tween


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


func configure(run_records: RefCounted, initial_hero_id := "") -> void:
	records = run_records
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
	var power: Dictionary = snapshot.get("power", {})
	power_label.text = "当前战力  %d" % int(power.get("total", snapshot.get("combat_power", 0)))
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
	var plate := Panel.new()
	plate.position = Vector2(18, 144)
	plate.size = Vector2(300, 46)
	plate.add_theme_stylebox_override("panel", CharacterStyle.surface(UiFactory.GLASS, 18.0, UiFactory.GOLD))
	add_child(plate)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 5
	row.offset_top = 3
	row.offset_right = -5
	row.offset_bottom = -3
	row.add_theme_constant_override("separation", 4)
	plate.add_child(row)
	for hero_id in HeroCatalog.ids():
		var button := Button.new()
		button.text = HeroCatalog.hero(hero_id)["name"]
		button.custom_minimum_size = Vector2(0, 40)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(select_hero.bind(hero_id))
		row.add_child(button)
		hero_buttons[hero_id] = button
	var power_plate := Panel.new()
	power_plate.position = Vector2(328, 144)
	power_plate.size = Vector2(194, 46)
	power_plate.add_theme_stylebox_override("panel", CharacterStyle.paper_card())
	add_child(power_plate)
	power_label = CharacterStyle.add_label(
		power_plate, "当前战力  0", 16, UiFactory.INK,
		Vector2.ZERO, power_plate.size, HORIZONTAL_ALIGNMENT_CENTER
	)
	power_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_sections() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(18, 198)
	row.size = Vector2(504, 48)
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	for section_id in SECTION_IDS:
		var button := Button.new()
		button.text = SECTION_NAMES[section_id]
		button.custom_minimum_size = Vector2(0, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(show_section.bind(section_id))
		row.add_child(button)
		section_buttons[section_id] = button


func _build_panels() -> void:
	status_panel = StatusPanel.new()
	equipment_panel = EquipmentPanel.new()
	skill_panel = SkillPanel.new()
	for pair in [["status", status_panel], ["equipment", equipment_panel], ["skills", skill_panel]]:
		var panel: Panel = pair[1]
		panel.position = Vector2(18, 254)
		add_child(panel)
		section_panels[pair[0]] = panel
	hero_rig = equipment_panel.hero_rig
	equipment_panel.equipment_changed.connect(_on_profile_changed)
	skill_panel.training_changed.connect(_on_profile_changed)


func _refresh_hero_buttons() -> void:
	for hero_id in hero_buttons:
		CharacterStyle.apply_segment(hero_buttons[hero_id], hero_id == selected_hero_id)


func _update_section() -> void:
	if section_tween != null and section_tween.is_valid():
		section_tween.kill()
	for section_id in section_panels:
		var selected: bool = section_id == current_section
		section_panels[section_id].visible = selected
		CharacterStyle.apply_segment(section_buttons[section_id], selected)
	var panel: Control = section_panels[current_section]
	panel.position.y = 260.0
	panel.modulate.a = 0.0
	section_tween = create_tween().set_parallel(true)
	section_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	section_tween.tween_property(panel, "position:y", 254.0, 0.2)
	section_tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	if is_instance_valid(equipment_panel):
		equipment_panel.set_active(content_active and current_section == "equipment")


func _snapshot() -> Dictionary:
	return records.get_permanent_snapshot(selected_hero_id) if records.has_method("get_permanent_snapshot") else records.progression_snapshot(selected_hero_id)


func _active_hero_id() -> String:
	if is_instance_valid(records) and records.has_method("get_active_hero_id"):
		return str(records.get_active_hero_id())
	return str(records.last_hero_id) if is_instance_valid(records) else ""


func _on_profile_changed(_message := "") -> void:
	refresh()
	if current_section == "equipment":
		equipment_panel.hero_stage.react()
	profile_changed.emit()
