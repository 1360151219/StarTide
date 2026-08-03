extends Button

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")

var icon_view: TextureRect
var rarity_label: Label
var name_label: Label
var level_label: Label
var owner_label: Label
var item_data: Dictionary = {}
var selected := false
var current_owner_name := ""


func _ready() -> void:
	custom_minimum_size = Vector2(108, 88)
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	icon_view = TextureRect.new()
	icon_view.position = Vector2(26, 10)
	icon_view.size = Vector2(56, 46)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_view)
	rarity_label = _label(Vector2(6, 4), Vector2(56, 18), 11, HORIZONTAL_ALIGNMENT_LEFT)
	level_label = _label(Vector2(60, 4), Vector2(42, 18), 11, HORIZONTAL_ALIGNMENT_RIGHT)
	name_label = _label(Vector2(6, 56), Vector2(96, 20), 13, HORIZONTAL_ALIGNMENT_CENTER)
	owner_label = _label(Vector2(12, 73), Vector2(84, 14), 10, HORIZONTAL_ALIGNMENT_CENTER)


func present(item: Dictionary, is_selected: bool, owner_name := "") -> void:
	item_data = item
	selected = is_selected
	current_owner_name = owner_name
	visible = not item.is_empty()
	if item.is_empty():
		set_meta("instance_id", "")
		return
	var rarity_id := str(item.get("rarity", "common"))
	var equipped := not owner_name.is_empty()
	set_meta("instance_id", str(item.get("instance_id", "")))
	icon_view.texture = item.get("icon")
	rarity_label.text = EquipmentCatalog.rarity_name(rarity_id)
	rarity_label.add_theme_color_override("font_color", CharacterStyle.rarity_color(rarity_id))
	level_label.text = "Lv.%d" % int(item.get("level", 1))
	level_label.add_theme_color_override("font_color", CharacterStyle.INK)
	name_label.text = str(item.get("name", "未知装备"))
	name_label.add_theme_color_override("font_color", CharacterStyle.INK)
	owner_label.text = "%s使用中" % owner_name if equipped else ("已锁定" if bool(item.get("locked", false)) else "")
	owner_label.add_theme_color_override("font_color", CharacterStyle.MUTED)
	tooltip_text = "%s\n%s\n%s" % [
		item.get("description", ""), CharacterStyle.stats_text(item.get("stats", {})),
		owner_label.text,
	]
	accessibility_name = "%s，%s品质，等级%d%s" % [
		item.get("name", "装备"), EquipmentCatalog.rarity_name(rarity_id), int(item.get("level", 1)),
		"，已锁定" if bool(item.get("locked", false)) else "",
	]
	CharacterStyle.apply_item_card(self, rarity_id, selected)


func set_selected(value: bool) -> void:
	if item_data.is_empty():
		return
	present(item_data, value, current_owner_name)


func _label(at: Vector2, label_size: Vector2, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = at
	label.size = label_size
	label.horizontal_alignment = alignment
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
