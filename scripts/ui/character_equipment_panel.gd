extends Panel

signal equipment_changed(message: String)

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const ItemCard = preload("res://scripts/ui/equipment_item_card.gd")
const DetailSheet = preload("res://scripts/ui/equipment_detail_sheet.gd")
const InventoryPresenter = preload("res://scripts/ui/equipment_inventory_presenter.gd")
const HeroStage = preload("res://scripts/ui/equipment_hero_stage.gd")
const INVENTORY_TRAY := preload("res://assets/art/ui/character/inventory_tray_frame.png")
const FILTERS := {
	"all": "全部", "weapon": "武器", "armor": "护甲", "charm": "饰品",
}
const FILTER_ICONS := {
	"all": preload("res://assets/art/ui/character/filter_icon_all.png"),
	"weapon": preload("res://assets/art/ui/character/filter_icon_weapon.png"),
	"armor": preload("res://assets/art/ui/character/filter_icon_armor.png"),
	"charm": preload("res://assets/art/ui/character/filter_icon_charm.png"),
}

var records: RefCounted
var hero_id := ""
var current_snapshot: Dictionary = {}
var current_filter := "all"
var selected_instance_id := ""
var presenter := InventoryPresenter.new()
var slot_buttons: Dictionary = {}
var inventory_buttons: Array[Button] = []
var filter_buttons: Dictionary = {}
var inventory_grid: GridContainer
var count_label: Label
var status_label: Label
var empty_label: Label
var inventory_sheet: Panel
var hero_stage: Control
var hero_rig: Node
var detail_sheet: Panel


func _ready() -> void:
	size = Vector2(504, 682)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	hero_stage = HeroStage.new()
	hero_stage.slot_selected.connect(_select_slot)
	add_child(hero_stage)
	slot_buttons = hero_stage.slot_buttons
	hero_rig = hero_stage.hero_rig
	_build_inventory_sheet()


func configure(run_records: RefCounted) -> void:
	records = run_records


func show_for(selected_hero_id: String, snapshot: Dictionary) -> void:
	hero_id = selected_hero_id
	current_snapshot = snapshot
	_refresh_stage(snapshot)
	_refresh_equipment(snapshot)


func set_active(active: bool) -> void:
	hero_stage.set_active(active)


func _build_inventory_sheet() -> void:
	inventory_sheet = Panel.new()
	inventory_sheet.name = "InventoryTray"
	inventory_sheet.position = Vector2(-12, 418)
	inventory_sheet.size = Vector2(524, 302)
	inventory_sheet.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(inventory_sheet)
	var tray := TextureRect.new()
	tray.name = "TrayFrame"
	tray.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tray.texture = INVENTORY_TRAY
	tray.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray.stretch_mode = TextureRect.STRETCH_SCALE
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_sheet.add_child(tray)
	var filters := HBoxContainer.new()
	filters.position = Vector2(98, 24)
	filters.size = Vector2(308, 48)
	filters.add_theme_constant_override("separation", 12)
	inventory_sheet.add_child(filters)
	for filter_id in FILTERS:
		var button := Button.new()
		button.text = ""
		button.icon = FILTER_ICONS[filter_id]
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 30)
		button.custom_minimum_size = Vector2(68, 48)
		button.tooltip_text = FILTERS[filter_id]
		button.accessibility_name = "%s筛选" % FILTERS[filter_id]
		button.pressed.connect(_set_filter.bind(filter_id))
		filters.add_child(button)
		filter_buttons[filter_id] = button
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 78)
	scroll.size = Vector2(480, 166)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.get_v_scroll_bar().custom_minimum_size.x = 8
	inventory_sheet.add_child(scroll)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 5
	inventory_grid.custom_minimum_size.x = 472
	inventory_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	inventory_grid.add_theme_constant_override("h_separation", 6)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(inventory_grid)
	empty_label = CharacterStyle.add_label(inventory_sheet, "暂无装备", 17, CharacterStyle.MUTED, Vector2(36, 78), Vector2(432, 96), HORIZONTAL_ALIGNMENT_CENTER)
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label = CharacterStyle.add_label(inventory_sheet, "", 14, CharacterStyle.MUTED, Vector2(22, 174), Vector2(156, 24))
	status_label = CharacterStyle.add_label(inventory_sheet, "", 14, CharacterStyle.MUTED, Vector2(190, 174), Vector2(236, 24), HORIZONTAL_ALIGNMENT_RIGHT)
	detail_sheet = DetailSheet.new()
	detail_sheet.action_requested.connect(_perform_selected_action)
	detail_sheet.upgrade_requested.connect(_upgrade_selected_item)
	detail_sheet.lock_requested.connect(_set_selected_item_locked)
	detail_sheet.closed.connect(_refresh_card_selection)
	inventory_sheet.add_child(detail_sheet)


func _refresh_stage(snapshot: Dictionary) -> void:
	hero_stage.show_for(hero_id, snapshot)


func _refresh_equipment(snapshot: Dictionary) -> void:
	presenter.consume(snapshot)
	for slot_id in EquipmentCatalog.SLOTS:
		hero_stage.show_slot(slot_id, presenter.equipped_item(slot_id))
	_rebuild_inventory()


func _rebuild_inventory() -> void:
	for child in inventory_grid.get_children():
		inventory_grid.remove_child(child)
		child.queue_free()
	inventory_buttons.clear()
	var shown := presenter.shown_rows(current_filter)
	for item in shown:
		var card := ItemCard.new()
		card.size = Vector2(88, 88)
		card.pressed.connect(_select_inventory_item.bind(card))
		inventory_grid.add_child(card)
		var owner_name := presenter.owner_name(item)
		card.present(item, str(item.get("instance_id", "")) == selected_instance_id, owner_name, presenter.owner_id(item))
		inventory_buttons.append(card)
	empty_label.visible = shown.is_empty()
	count_label.text = "背包 %d" % presenter.rows.size()
	_refresh_filter_buttons()


func _select_inventory_item(card: Button) -> void:
	selected_instance_id = str(card.get_meta("instance_id", ""))
	_show_selected_detail()
	_refresh_card_selection()


func _select_slot(slot_id: String) -> void:
	var instance_id := str(slot_buttons[slot_id].get_meta("instance_id", ""))
	if instance_id.is_empty():
		_set_filter(slot_id)
		status_label.text = "请选择一件%s" % EquipmentCatalog.slot_name(slot_id)
		return
	selected_instance_id = instance_id
	_show_selected_detail()
	_refresh_card_selection()


func _show_selected_detail() -> void:
	var item := presenter.item(selected_instance_id)
	if item.is_empty():
		return
	var owner_id := presenter.owner_id(item)
	var owner_name := presenter.owner_name(item)
	var action_text := "装备"
	var can_action := owner_id.is_empty()
	if owner_id == hero_id:
		action_text = "卸下装备"
		can_action = true
	elif not owner_id.is_empty():
		action_text = "%s使用中" % owner_name
	var current := presenter.equipped_item(str(item.get("slot", "")))
	var compare_text := "当前槽位：空" if current.is_empty() else "当前：%s · %s" % [current.get("name", "装备"), CharacterStyle.stats_text(current.get("stats", {}))]
	detail_sheet.show_item(item, owner_name, action_text, can_action, compare_text, presenter.upgrade_material(selected_instance_id))


func _perform_selected_action(_instance_id: String) -> void:
	var item := presenter.item(selected_instance_id)
	if item.is_empty() or not is_instance_valid(records):
		return
	var owner_id := presenter.owner_id(item)
	var result: Dictionary
	if owner_id == hero_id:
		result = records.unequip_item(hero_id, str(item.get("slot", "")))
	elif owner_id.is_empty():
		result = records.equip_item(hero_id, selected_instance_id)
	else:
		return
	status_label.text = str(result.get("reason", "装备状态已更新"))
	detail_sheet.visible = false
	equipment_changed.emit(status_label.text)


func _upgrade_selected_item(instance_id: String, material_instance_id: String) -> void:
	if not is_instance_valid(records) or instance_id != selected_instance_id:
		return
	var result: Dictionary = records.upgrade_equipment(instance_id, material_instance_id)
	_finish_detail_command(result)


func _set_selected_item_locked(instance_id: String, locked: bool) -> void:
	if not is_instance_valid(records) or instance_id != selected_instance_id:
		return
	var result: Dictionary = records.set_equipment_locked(instance_id, locked)
	_finish_detail_command(result)


func _finish_detail_command(result: Dictionary) -> void:
	status_label.text = str(result.get("reason", "装备状态已更新"))
	detail_sheet.visible = false
	equipment_changed.emit(status_label.text)


func _set_filter(filter_id: String) -> void:
	current_filter = filter_id if FILTERS.has(filter_id) else "all"
	selected_instance_id = ""
	detail_sheet.visible = false
	_rebuild_inventory()


func _refresh_filter_buttons() -> void:
	for filter_id in filter_buttons:
		CharacterStyle.apply_ribbon_tab(filter_buttons[filter_id], filter_id == current_filter)


func _refresh_card_selection() -> void:
	for card in inventory_buttons:
		card.set_selected(str(card.get_meta("instance_id", "")) == selected_instance_id and detail_sheet.visible)
