extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const EXPERIENCE_ICON := preload("res://assets/art/pickups/experience_shard.png")
const VICTORY_CREST := preload("res://assets/generated/ui/victory_crest.png")
const VISIBLE_TILES := 6
const PRIMARY_TILE_WIDTH := 96.0
const TILE_WIDTH := 64.0

var scroll: ScrollContainer
var content: HBoxContainer
var left_hint: Control
var right_hint: Control
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
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 0)
	scroll.add_child(content)
	left_hint = _build_scroll_hint(true)
	right_hint = _build_scroll_hint(false)
	scroll.get_h_scroll_bar().value_changed.connect(_update_scroll_hints.unbind(1))
	resized.connect(_refresh_content_width)


func present(presentation: Dictionary) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var entries := _entries(presentation)
	if entries.is_empty():
		entries.append({"texture": EXPERIENCE_ICON, "badge": "—", "tooltip": "本次没有获得奖励", "kind": "xp", "source": "收获"})
	entry_count = entries.size()
	for index in range(entries.size()):
		content.add_child(_build_tile(entries[index], index == 0, index < entries.size() - 1))
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
			"tooltip": "英雄经验 +%d · 当前 LV.%d" % [xp_gained, int(progression.get("level", 1))],
			"kind": "xp",
			"source": "成长",
		})
	_append_equipment(entries, presentation.get("equipment_reward", {}).get("item_rows", []), "关卡")
	_append_equipment(entries, presentation.get("random_equipment_reward", {}).get("items", []), "掉落")
	if bool(presentation.get("first_clear", false)):
		entries.append({
			"texture": VICTORY_CREST,
			"badge": "×1",
			"tooltip": str(presentation.get("first_clear_hint", "首次通关奖励")),
			"kind": "first_clear",
			"source": "首通",
		})
	var discovery_count := int(presentation.get("discovery_count", 0))
	if discovery_count > 0:
		entries.append({
			"glyph": "compendium",
			"badge": "+%d" % discovery_count,
			"tooltip": "新图鉴 %d 项" % discovery_count,
			"kind": "discovery",
			"source": "发现",
		})
	return entries


func _append_equipment(entries: Array[Dictionary], raw_items, source: String) -> void:
	for raw_item in raw_items:
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item
		var definition_id := str(item.get("definition_id", ""))
		if not EquipmentCatalog.has(definition_id):
			continue
		var rarity_id := str(item.get("rarity", EquipmentCatalog.default_rarity(definition_id)))
		var equipment := EquipmentCatalog.equipment(definition_id)
		var level := int(item.get("level", 1))
		entries.append({
			"texture": equipment["icon"],
			"badge": "×1",
			"tooltip": "%s · %s · LV.%d" % [equipment["name"], EquipmentCatalog.rarity_name(rarity_id), level],
			"kind": "equipment",
			"rarity": rarity_id,
			"source": source,
		})


func _build_tile(entry: Dictionary, primary: bool, show_separator: bool) -> Panel:
	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(PRIMARY_TILE_WIDTH if primary else TILE_WIDTH, 96)
	tile.mouse_filter = Control.MOUSE_FILTER_PASS
	tile.tooltip_text = str(entry.get("tooltip", ""))
	if primary:
		var style := SunlitCardStyle.panel_style(Color(UiFactory.ACCENT_LIGHT, 0.86), Color(UiFactory.ACCENT_DARK, 0.7), 6.0, false, false)
		style.shadow_size = 0
		style.shadow_offset = Vector2.ZERO
		tile.add_theme_stylebox_override("panel", style)
		SunlitCardStyle.decorate(tile, UiFactory.ACCENT_DARK, 6.0, true, false, UiFactory.ACCENT, "enamel", 1)
	else:
		tile.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var width := PRIMARY_TILE_WIDTH if primary else TILE_WIDTH
	var source := UiFactory.surface_label(str(entry.get("source", "收获")), 14, UiFactory.MUTED_INK)
	source.position = Vector2(4, 0)
	source.size = Vector2(width - 8, 22)
	source.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	source.clip_text = true
	source.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(source)
	_add_entry_icon(tile, entry, width, primary)
	var badge := UiFactory.surface_label(str(entry.get("badge", "")), 14 if not primary else 16, UiFactory.INK)
	badge.position = Vector2(3, 72)
	badge.size = Vector2(width - 6, 22)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.clip_text = true
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(badge)
	if show_separator:
		var separator := ColorRect.new()
		separator.anchor_left = 1.0
		separator.anchor_right = 1.0
		separator.offset_left = -1.0
		separator.offset_right = 0.0
		separator.offset_top = 12.0
		separator.offset_bottom = 84.0
		separator.color = Color(UiFactory.PRIMARY, 0.28)
		separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(separator)
	return tile


func _add_entry_icon(tile: Panel, entry: Dictionary, width: float, primary: bool) -> void:
	var icon_size := 50.0 if primary else 44.0
	var icon_position := Vector2((width - icon_size) * 0.5, 21)
	if str(entry.get("kind", "")) == "equipment":
		var rarity_id := str(entry.get("rarity", "common"))
		var icon_frame := Panel.new()
		icon_frame.position = icon_position
		icon_frame.size = Vector2(icon_size, icon_size)
		icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.add_theme_stylebox_override("panel", CharacterStyle.quality_card(rarity_id, 6.0))
		SunlitCardStyle.decorate(icon_frame, CharacterStyle.rarity_border(rarity_id), 6.0, false, false, UiFactory.ACCENT, "canvas", CharacterStyle.rarity_level(rarity_id))
		CharacterStyle.apply_quality_structure(icon_frame, rarity_id, 6.0)
		tile.add_child(icon_frame)
		var equipment_icon := TextureRect.new()
		equipment_icon.position = Vector2(4, 4)
		equipment_icon.size = Vector2(icon_size - 8, icon_size - 8)
		equipment_icon.texture = entry.get("texture")
		equipment_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		equipment_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		equipment_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.add_child(equipment_icon)
		return
	if entry.has("glyph"):
		var glyph := SunlitGlyph.new()
		glyph.glyph_id = str(entry["glyph"])
		glyph.position = icon_position
		glyph.size = Vector2(icon_size, icon_size)
		tile.add_child(glyph)
		return
	var icon := TextureRect.new()
	icon.position = icon_position
	icon.size = Vector2(icon_size, icon_size)
	icon.texture = entry.get("texture")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(icon)


func _refresh_content_width() -> void:
	var tiles_width := 0.0
	for tile in content.get_children():
		tiles_width += tile.custom_minimum_size.x
	content_width = maxf(size.x, tiles_width)
	content.custom_minimum_size = Vector2(content_width, size.y)
	_update_scroll_hints()


func _build_scroll_hint(on_left: bool) -> Control:
	var hint := SunlitGlyph.new()
	hint.glyph_id = "back"
	hint.anchor_left = 0.0 if on_left else 1.0
	hint.anchor_right = 0.0 if on_left else 1.0
	hint.anchor_top = 0.5
	hint.anchor_bottom = 0.5
	hint.offset_left = 0.0 if on_left else -28.0
	hint.offset_right = 28.0 if on_left else 0.0
	hint.offset_top = -20.0
	hint.offset_bottom = 20.0
	hint.pivot_offset = Vector2(14, 20)
	if not on_left:
		hint.rotation = PI
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
