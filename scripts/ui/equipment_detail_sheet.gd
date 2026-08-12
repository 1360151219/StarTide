extends Panel

signal action_requested(instance_id: String)
signal upgrade_requested(instance_id: String, material_instance_id: String)
signal lock_requested(instance_id: String, locked: bool)
signal closed

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")

var item: Dictionary = {}
var icon_view: TextureRect
var name_label: Label
var meta_label: Label
var description_label: Label
var stats_label: Label
var compare_label: Label
var action_button: Button
var upgrade_button: Button
var lock_button: Button
var material_instance_id := ""


func _ready() -> void:
	position = Vector2(4, 4)
	size = Vector2(496, 244)
	z_index = 20
	CharacterStyle.apply_continuous_panel(self, UiFactory.SURFACE, Color(UiFactory.PRIMARY, 0.72), 8.0)
	var close_button := Button.new()
	close_button.position = Vector2(424, 6)
	close_button.size = Vector2(60, 48)
	close_button.text = "收起"
	close_button.add_theme_font_size_override("font_size", 14)
	CharacterStyle.apply_segment(close_button, false)
	close_button.pressed.connect(_close)
	add_child(close_button)
	icon_view = TextureRect.new()
	icon_view.position = Vector2(18, 20)
	icon_view.size = Vector2(82, 82)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(icon_view)
	name_label = _label(Vector2(112, 14), Vector2(300, 32), 24, CharacterStyle.INK)
	meta_label = _label(Vector2(112, 46), Vector2(300, 24), 14, CharacterStyle.MUTED)
	description_label = _label(Vector2(112, 70), Vector2(362, 44), 15, CharacterStyle.INK)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label = _label(Vector2(18, 122), Vector2(458, 24), 15, CharacterStyle.INK)
	compare_label = _label(Vector2(18, 150), Vector2(458, 24), 14, CharacterStyle.MUTED)
	lock_button = Button.new()
	lock_button.position = Vector2(18, 184)
	lock_button.size = Vector2(92, 48)
	lock_button.add_theme_font_size_override("font_size", 15)
	lock_button.pressed.connect(_toggle_lock)
	add_child(lock_button)
	upgrade_button = Button.new()
	upgrade_button.position = Vector2(118, 184)
	upgrade_button.size = Vector2(170, 48)
	upgrade_button.add_theme_font_size_override("font_size", 14)
	upgrade_button.pressed.connect(_upgrade)
	add_child(upgrade_button)
	action_button = Button.new()
	action_button.position = Vector2(296, 184)
	action_button.size = Vector2(180, 48)
	action_button.add_theme_font_size_override("font_size", 15)
	action_button.pressed.connect(_act)
	add_child(action_button)
	visible = false


func show_item(target: Dictionary, owner_name: String, action_text: String, can_action: bool, compare_text: String, upgrade_material := {}) -> void:
	item = target
	material_instance_id = str(upgrade_material.get("instance_id", ""))
	icon_view.texture = item.get("icon")
	var rarity_id := str(item.get("rarity", "common"))
	add_theme_stylebox_override("panel", CharacterStyle.quality_card(rarity_id, 8.0))
	SunlitCardStyle.decorate(self, CharacterStyle.rarity_border(rarity_id), 8.0, false, true, UiFactory.ACCENT, "canvas", CharacterStyle.rarity_level(rarity_id))
	CharacterStyle.apply_quality_structure(self, rarity_id, 8.0)
	name_label.text = str(item.get("name", "未知装备"))
	meta_label.text = "%s · %s · LV.%d / %d" % [
		EquipmentCatalog.rarity_name(rarity_id), EquipmentCatalog.slot_name(str(item.get("slot", ""))),
		int(item.get("level", 1)), int(item.get("max_level", 1)),
	]
	meta_label.add_theme_color_override("font_color", CharacterStyle.rarity_color(rarity_id))
	description_label.text = str(item.get("description", ""))
	stats_label.text = CharacterStyle.stats_text(item.get("stats", {}))
	compare_label.text = compare_text if not compare_text.is_empty() else ("当前由%s使用" % owner_name if not owner_name.is_empty() else "可装备到当前角色")
	lock_button.text = "解锁" if bool(item.get("locked", false)) else "锁定"
	CharacterStyle.apply_segment(lock_button, false)
	var at_max := int(item.get("level", 1)) >= int(item.get("max_level", 1))
	upgrade_button.text = "已满级" if at_max else ("缺少同名装备" if material_instance_id.is_empty() else "升级 LV.%d\n耗%s LV.%d" % [
		int(item.get("level", 1)) + 1, EquipmentCatalog.rarity_name(str(upgrade_material.get("rarity", "common"))), int(upgrade_material.get("level", 1)),
	])
	upgrade_button.disabled = at_max or material_instance_id.is_empty()
	upgrade_button.tooltip_text = "" if material_instance_id.is_empty() else "消耗%s %s LV.%d" % [
		EquipmentCatalog.rarity_name(str(upgrade_material.get("rarity", "common"))),
		upgrade_material.get("name", "同名装备"), int(upgrade_material.get("level", 1)),
	]
	SunlitCardStyle.apply_button(upgrade_button, false, CharacterStyle.rarity_border(rarity_id))
	action_button.text = action_text
	action_button.disabled = not can_action
	SunlitCardStyle.apply_button(action_button, true, UiFactory.ACCENT)
	visible = true


func _act() -> void:
	if not item.is_empty():
		action_requested.emit(str(item.get("instance_id", "")))


func _upgrade() -> void:
	if not item.is_empty() and not material_instance_id.is_empty():
		upgrade_requested.emit(str(item.get("instance_id", "")), material_instance_id)


func _toggle_lock() -> void:
	if not item.is_empty():
		lock_requested.emit(str(item.get("instance_id", "")), not bool(item.get("locked", false)))


func _close() -> void:
	visible = false
	closed.emit()


func _label(at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := UiFactory.label("", font_size, color)
	label.position = at
	label.size = label_size
	label.clip_text = true
	add_child(label)
	return label
