extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const StarTideGlyph = preload("res://scripts/ui/star_tide_glyph.gd")
const EXPERIENCE_ICON := preload("res://assets/art/pickups/experience_shard.png")
const VICTORY_CREST := preload("res://assets/generated/ui/victory_crest.png")
const VISIBLE_TILES := 6
const TILE_WIDTH := 65.0
const TILE_GAP := 6

var scroll: ScrollContainer
var content: HBoxContainer
var left_hint: Label
var right_hint: Label
var entry_count := 0
var content_width := 0.0


func _ready() -> void:
	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 6
	scroll.follow_focus = true
	add_child(scroll)
	content = HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", TILE_GAP)
	scroll.add_child(content)
	left_hint = _build_scroll_hint("‹", true)
	right_hint = _build_scroll_hint("›", false)
	scroll.get_h_scroll_bar().value_changed.connect(_update_scroll_hints.unbind(1))
	resized.connect(_refresh_content_width)


func present(presentation: Dictionary) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var entries := _entries(presentation)
	if entries.is_empty():
		entries.append({"texture": EXPERIENCE_ICON, "badge": "—", "tooltip": "本次没有获得奖励", "kind": "xp"})
	entry_count = entries.size()
	for entry in entries:
		content.add_child(_build_tile(entry))
	scroll.scroll_horizontal = 0
	_refresh_content_width()
	_update_scroll_hints()


func tile_count() -> int:
	return entry_count


func tile_tooltips() -> PackedStringArray:
	var result := PackedStringArray()
	for tile in content.get_children():
		result.append(tile.tooltip_text)
	return result


func has_horizontal_overflow() -> bool:
	return entry_count > VISIBLE_TILES


func _entries(presentation: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var progression: Dictionary = presentation.get("progression_reward", {})
	var xp_gained := int(progression.get("hero_xp_gained", 0))
	if xp_gained > 0:
		entries.append({
			"texture": EXPERIENCE_ICON,
			"badge": "+%d" % xp_gained,
			"tooltip": "英雄经验 +%d · 当前 Lv.%d" % [xp_gained, int(progression.get("level", 1))],
			"kind": "xp",
		})
	_append_equipment(entries, presentation.get("equipment_reward", {}).get("item_rows", []))
	_append_equipment(entries, presentation.get("random_equipment_reward", {}).get("items", []))
	if bool(presentation.get("first_clear", false)):
		entries.append({"texture": VICTORY_CREST, "badge": "首通", "tooltip": str(presentation.get("first_clear_hint", "首次通关奖励")), "kind": "first_clear"})
	var discovery_count := int(presentation.get("discovery_count", 0))
	if discovery_count > 0:
		entries.append({"glyph": "compendium", "badge": "+%d" % discovery_count, "tooltip": "新图鉴 %d 项" % discovery_count, "kind": "discovery"})
	return entries


func _append_equipment(entries: Array[Dictionary], raw_items) -> void:
	for raw_item in raw_items:
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item
		var definition_id := str(item.get("definition_id", ""))
		if not EquipmentCatalog.has(definition_id):
			continue
		var rarity_id := str(item.get("rarity", EquipmentCatalog.default_rarity(definition_id)))
		var equipment := EquipmentCatalog.equipment(definition_id)
		entries.append({
			"texture": equipment["icon"],
			"badge": "Lv.%d" % int(item.get("level", 1)),
			"tooltip": "%s · %s" % [equipment["name"], EquipmentCatalog.rarity_name(rarity_id)],
			"kind": "equipment",
			"rarity": rarity_id,
		})


func _build_tile(entry: Dictionary) -> Panel:
	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(TILE_WIDTH, 104)
	tile.mouse_filter = Control.MOUSE_FILTER_PASS
	tile.tooltip_text = str(entry.get("tooltip", ""))
	var kind := str(entry.get("kind", ""))
	if kind == "equipment":
		tile.add_theme_stylebox_override("panel", CharacterStyle.quality_card(str(entry.get("rarity", "common")), 14.0))
	else:
		var background := Color("fff0bd") if kind in ["xp", "first_clear"] else Color("dcefeb")
		tile.add_theme_stylebox_override("panel", UiFactory.panel_style(background, 14.0, UiFactory.GOLD))
	if entry.has("glyph"):
		var glyph := StarTideGlyph.new()
		glyph.glyph_id = str(entry["glyph"])
		glyph.position = Vector2(14, 14)
		glyph.size = Vector2(38, 38)
		tile.add_child(glyph)
	else:
		var icon := TextureRect.new()
		icon.position = Vector2(7, 7)
		icon.size = Vector2(52, 58)
		icon.texture = entry.get("texture")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(icon)
	var badge := UiFactory.surface_label(str(entry.get("badge", "")), 12, UiFactory.INK)
	badge.position = Vector2(3, 72)
	badge.size = Vector2(60, 24)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.clip_text = true
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(badge)
	return tile


func _refresh_content_width() -> void:
	var tiles_width := entry_count * TILE_WIDTH + maxi(0, entry_count - 1) * TILE_GAP
	content_width = maxf(size.x, tiles_width)
	content.custom_minimum_size = Vector2(content_width, size.y)
	_update_scroll_hints()


func _build_scroll_hint(text: String, on_left: bool) -> Label:
	var hint := UiFactory.surface_label(text, 24, UiFactory.CREAM)
	hint.anchor_left = 0.0 if on_left else 1.0
	hint.anchor_right = 0.0 if on_left else 1.0
	hint.anchor_top = 0.5
	hint.anchor_bottom = 0.5
	hint.offset_left = 0.0 if on_left else -24.0
	hint.offset_right = 24.0 if on_left else 0.0
	hint.offset_top = -22.0
	hint.offset_bottom = 22.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_outline_color", Color(0.02, 0.19, 0.2, 0.92))
	hint.add_theme_constant_override("outline_size", 5)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.visible = false
	add_child(hint)
	return hint


func _update_scroll_hints() -> void:
	if not is_instance_valid(left_hint) or not is_instance_valid(right_hint):
		return
	var overflow := has_horizontal_overflow()
	left_hint.visible = overflow and scroll.scroll_horizontal > 1
	right_hint.visible = overflow and scroll.scroll_horizontal < content_width - size.x - 1.0
