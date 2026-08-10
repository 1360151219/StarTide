extends Button

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const SlotSilhouette = preload("res://scripts/ui/equipment_slot_silhouette.gd")

var slot_id := ""
var item_data: Dictionary = {}
var icon_view: TextureRect
var empty_mark: Control
var slot_label: Label
var item_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(90, 88)
	focus_mode = Control.FOCUS_ALL
	icon_view = TextureRect.new()
	icon_view.position = Vector2(21, 22)
	icon_view.size = Vector2(48, 40)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_view)
	empty_mark = SlotSilhouette.new()
	empty_mark.position = Vector2(19, 20)
	empty_mark.size = Vector2(52, 44)
	add_child(empty_mark)
	slot_label = _label(Vector2(6, 2), Vector2(78, 20), 14)
	item_label = _label(Vector2(5, 64), Vector2(80, 22), 14)


func present(target_slot_id: String, item: Dictionary) -> void:
	slot_id = target_slot_id
	item_data = item
	var occupied := not item.is_empty()
	var rarity_id := str(item.get("rarity", "common"))
	icon_view.texture = item.get("icon") if occupied else null
	icon_view.visible = occupied
	empty_mark.visible = not occupied
	empty_mark.present(slot_id)
	slot_label.text = EquipmentCatalog.slot_name(slot_id)
	slot_label.add_theme_color_override("font_color", CharacterStyle.MUTED)
	item_label.text = str(item.get("name", "待装备")) if occupied else "待装备"
	item_label.add_theme_color_override("font_color", CharacterStyle.INK if occupied else CharacterStyle.MUTED)
	set_meta("instance_id", str(item.get("instance_id", "")))
	tooltip_text = str(item.get("description", "点击下方背包选择装备"))
	accessibility_name = "%s槽，%s" % [EquipmentCatalog.slot_name(slot_id), item_label.text]
	if occupied:
		CharacterStyle.apply_item_card(self, rarity_id, false)
	else:
		CharacterStyle.apply_empty_slot_card(self)


func _label(at: Vector2, label_size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
