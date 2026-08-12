extends Button

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const CharacterAssets = preload("res://scripts/ui/character_asset_catalog.gd")
const SunlitLockBadge = preload("res://scripts/ui/sunlit_lock_badge.gd")

var background_view: TextureRect
var icon_view: TextureRect
var level_label: Label
var owner_backing: Panel
var owner_avatar: TextureRect
var lock_badge: Control
var selection_frame: Panel
var item_data: Dictionary = {}
var selected := false
var current_owner_name := ""
var current_owner_id := ""


func _ready() -> void:
	custom_minimum_size = Vector2(88, 88)
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	CharacterStyle.apply_item_card(self, "common", false)
	background_view = TextureRect.new()
	background_view.name = "QualityBackground"
	background_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_view.stretch_mode = TextureRect.STRETCH_SCALE
	background_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_view)
	icon_view = TextureRect.new()
	icon_view.position = Vector2(16, 15)
	icon_view.size = Vector2(56, 56)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_view)
	level_label = _label(Vector2(46, 65), Vector2(36, 18), 14, HORIZONTAL_ALIGNMENT_RIGHT)
	level_label.add_theme_color_override("font_outline_color", UiFactory.SURFACE)
	level_label.add_theme_constant_override("outline_size", 3)
	owner_backing = Panel.new()
	owner_backing.position = Vector2(60, 4)
	owner_backing.size = Vector2(24, 24)
	owner_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner_backing.add_theme_stylebox_override("panel", _avatar_backing_style())
	add_child(owner_backing)
	owner_avatar = TextureRect.new()
	owner_avatar.position = Vector2(2, 2)
	owner_avatar.size = Vector2(20, 20)
	owner_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	owner_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	owner_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner_backing.add_child(owner_avatar)
	lock_badge = SunlitLockBadge.new()
	lock_badge.position = Vector2(4, 62)
	lock_badge.size = Vector2(22, 22)
	add_child(lock_badge)
	selection_frame = Panel.new()
	selection_frame.name = "SelectionFrame"
	selection_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selection_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_frame.add_theme_stylebox_override("panel", _selection_style())
	add_child(selection_frame)


func present(item: Dictionary, is_selected: bool, owner_name := "", owner_id := "") -> void:
	item_data = item
	selected = is_selected
	current_owner_name = owner_name
	current_owner_id = owner_id
	visible = not item.is_empty()
	if item.is_empty():
		set_meta("instance_id", "")
		return
	var rarity_id := str(item.get("rarity", "common"))
	var equipped := not owner_id.is_empty()
	set_meta("instance_id", str(item.get("instance_id", "")))
	background_view.texture = CharacterAssets.quality_texture(rarity_id)
	icon_view.texture = item.get("icon")
	level_label.text = "LV.%d" % int(item.get("level", 1))
	level_label.add_theme_color_override("font_color", CharacterStyle.INK)
	owner_avatar.texture = CharacterAssets.hero_avatar_texture(owner_id)
	owner_backing.visible = equipped and owner_avatar.texture != null
	lock_badge.visible = bool(item.get("locked", false))
	selection_frame.visible = selected
	var owner_text := "，%s使用中" % owner_name if equipped else ""
	var lock_text := "，已锁定" if bool(item.get("locked", false)) else ""
	tooltip_text = "%s\n%s%s%s" % [
		item.get("description", ""), CharacterStyle.stats_text(item.get("stats", {})), owner_text, lock_text,
	]
	accessibility_name = "%s，%s品质，等级%d%s%s" % [
		item.get("name", "装备"), EquipmentCatalog.rarity_name(rarity_id), int(item.get("level", 1)), owner_text, lock_text,
	]
	CharacterStyle.apply_item_card(self, rarity_id, selected)


func set_selected(value: bool) -> void:
	if item_data.is_empty():
		return
	present(item_data, value, current_owner_name, current_owner_id)


func _avatar_backing_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiFactory.SURFACE
	style.border_color = UiFactory.INK
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = UiFactory.PRIMARY_DARK
	style.set_border_width_all(2)
	style.set_expand_margin_all(2.0)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style


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
