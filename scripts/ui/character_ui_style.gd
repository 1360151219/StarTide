extends RefCounted

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")

const STAGE_TOP := Color("8dcbd1")
const STAGE_BOTTOM := Color("ddefe7")
const SHEET := UiFactory.SURFACE
const SHEET_ALT := UiFactory.SURFACE_ALT
const INK := UiFactory.INK
const MUTED := UiFactory.MUTED_INK
const COMMON := Color("8a9995")
const RARE := UiFactory.RARE
const TOP := UiFactory.ACCENT
const COMMON_BACKGROUND := Color("f2f1e7")
const RARE_BACKGROUND := Color("e7edf6")
const TOP_BACKGROUND := Color("fff0c8")
const COMMON_BORDER := Color("8a9995")
const RARE_BORDER := UiFactory.RARE
const TOP_BORDER := UiFactory.ACCENT_DARK
const POWER := UiFactory.ACCENT_DARK
const POWER_FLASH := UiFactory.ACCENT
const POWER_GAIN := UiFactory.HEALING
const POWER_LOSS := UiFactory.DANGER
const LOCKED := UiFactory.DISABLED

const STAT_NAMES := {
	"damage_percent": "技能伤害", "max_health_percent": "最大生命",
	"max_health_flat": "最大生命", "cooldown_reduction": "技能冷却",
	"move_speed_percent": "移动速度", "range_percent": "技能范围",
	"projectile_speed_percent": "弹道速度", "pickup_radius_percent": "拾取范围",
}


static func surface(background: Color, radius := 18.0, border := Color.TRANSPARENT, shadow := true) -> StyleBoxFlat:
	return SunlitCardStyle.panel_style(background, border, radius, false, shadow)


static func paper_card(alternate := false, radius := 18.0, border := UiFactory.PRIMARY, shadow := true) -> StyleBoxFlat:
	return SunlitCardStyle.panel_style(SHEET_ALT if alternate else SHEET, border, radius, false, shadow)


static func continuous_style(
	background := SHEET_ALT,
	border := Color(UiFactory.PRIMARY, 0.58),
	radius := 8.0
) -> StyleBoxFlat:
	var style := SunlitCardStyle.panel_style(background, border, radius, false, false)
	style.set_border_width_all(1)
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style


static func apply_continuous_panel(
	panel: Control,
	background := SHEET_ALT,
	border := Color(UiFactory.PRIMARY, 0.58),
	radius := 8.0
) -> void:
	panel.add_theme_stylebox_override("panel", continuous_style(background, border, radius))


static func apply_surface_panel(
	panel: Control,
	background: Color,
	radius := 18.0,
	border := UiFactory.PRIMARY,
	selected := false
) -> void:
	panel.add_theme_stylebox_override("panel", SunlitCardStyle.panel_style(background, border, radius, selected))
	SunlitCardStyle.decorate(panel, border, radius, false, selected)


static func apply_panel(
	panel: Control,
	alternate := false,
	radius := 18.0,
	border := UiFactory.PRIMARY,
	selected := false
) -> void:
	panel.add_theme_stylebox_override("panel", SunlitCardStyle.panel_style(SHEET_ALT if alternate else SHEET, border, radius, selected))
	SunlitCardStyle.decorate(panel, border, radius, false, selected)


static func rarity_color(rarity_id: String) -> Color:
	return TOP if rarity_id == "top" else (RARE if rarity_id == "rare" else COMMON)


static func rarity_background(rarity_id: String) -> Color:
	return TOP_BACKGROUND if rarity_id == "top" else (RARE_BACKGROUND if rarity_id == "rare" else COMMON_BACKGROUND)


static func rarity_border(rarity_id: String) -> Color:
	return TOP_BORDER if rarity_id == "top" else (RARE_BORDER if rarity_id == "rare" else COMMON_BORDER)


static func rarity_level(rarity_id: String) -> int:
	return 3 if rarity_id == "top" else (2 if rarity_id == "rare" else 1)


static func quality_card(rarity_id: String, radius := 14.0, selected := false) -> StyleBoxFlat:
	var style := SunlitCardStyle.panel_style(rarity_background(rarity_id), rarity_border(rarity_id), radius, selected)
	style.set_border_width_all(3 if selected or rarity_level(rarity_id) >= 3 else 2)
	style.shadow_color = Color(UiFactory.INK, 0.24) if selected else Color(UiFactory.INK, 0.12)
	style.shadow_size = 4 if selected else 2
	style.shadow_offset = Vector2(0, 2 if selected else 1)
	return style


static func apply_segment(button: Button, selected: bool) -> void:
	SunlitCardStyle.apply_button(button, selected, UiFactory.PRIMARY, UiFactory.PRIMARY_DARK, UiFactory.SURFACE)


static func apply_ribbon_tab(button: Button, selected: bool) -> void:
	var background := UiFactory.PRIMARY_DARK if selected else UiFactory.SURFACE_ALT
	var border := UiFactory.PRIMARY_LIGHT if selected else Color(UiFactory.PRIMARY, 0.74)
	var normal := continuous_style(background, border, 6.0)
	normal.border_width_bottom = 3 if selected else 1
	normal.corner_radius_top_left = 2
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 2
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.04)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.06)
	var focus := continuous_style(Color.TRANSPARENT, UiFactory.ACCENT, 6.0)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	var text_color := UiFactory.HUD_TEXT if selected else UiFactory.INK
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_constant_override("outline_size", 0)
	SunlitCardStyle.decorate(button, Color(border, 0.46), 6.0, true, selected, UiFactory.PRIMARY_LIGHT, "ribbon")


static func apply_training_row(panel: Panel) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UiFactory.SURFACE_ALT, 0.34)
	style.border_color = Color(UiFactory.PRIMARY, 0.38)
	style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", style)


static func apply_power_label(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", POWER)
	label.add_theme_color_override("font_outline_color", UiFactory.SURFACE)
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_shadow_color", Color(UiFactory.ACCENT, 0.24))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 3)


static func apply_item_card(button: Button, rarity_id: String, selected: bool) -> void:
	var normal := quality_card(rarity_id, 6.0, selected)
	var hover := quality_card(rarity_id, 6.0, selected)
	hover.bg_color = normal.bg_color.lightened(0.025)
	var pressed := quality_card(rarity_id, 6.0, selected)
	pressed.bg_color = normal.bg_color.darkened(0.04)
	var focus := surface(Color.TRANSPARENT, 6.0, UiFactory.ACCENT, false)
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color(MUTED, 0.58))
	SunlitCardStyle.decorate(button, rarity_border(rarity_id), 6.0, false, selected, UiFactory.ACCENT, "canvas", rarity_level(rarity_id))
	apply_quality_structure(button, rarity_id, 6.0)


static func apply_quality_structure(target: Control, rarity_id: String, radius := 6.0) -> void:
	var visible_lines := rarity_level(rarity_id) - 1
	for index in range(2):
		var line_name := "QualityLine%d" % (index + 1)
		var line := target.get_node_or_null(line_name) as Panel
		if line == null:
			line = Panel.new()
			line.name = line_name
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			target.add_child(line, false, Node.INTERNAL_MODE_FRONT)
		line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var inset := 4.0 + float(index) * 4.0
		line.offset_left = inset
		line.offset_top = inset
		line.offset_right = -inset
		line.offset_bottom = -inset
		var line_style := StyleBoxFlat.new()
		line_style.bg_color = Color.TRANSPARENT
		line_style.border_color = Color(rarity_border(rarity_id), 0.68 - float(index) * 0.18)
		line_style.set_border_width_all(1)
		var inner_radius := maxi(2, int(radius - inset * 0.5))
		line_style.corner_radius_top_left = 2
		line_style.corner_radius_top_right = inner_radius
		line_style.corner_radius_bottom_left = inner_radius
		line_style.corner_radius_bottom_right = 2
		line.add_theme_stylebox_override("panel", line_style)
		line.visible = index < visible_lines


static func apply_empty_slot_card(button: Button) -> void:
	var normal := continuous_style(Color(UiFactory.SURFACE_ALT, 0.76), Color(UiFactory.PRIMARY, 0.62), 6.0)
	var hover := continuous_style(UiFactory.SURFACE_ALT, UiFactory.PRIMARY_LIGHT, 6.0)
	var pressed := continuous_style(UiFactory.SURFACE_ALT.darkened(0.04), UiFactory.PRIMARY, 6.0)
	pressed.bg_color = normal.bg_color.darkened(0.04)
	var focus := surface(Color.TRANSPARENT, 6.0, UiFactory.ACCENT, false)
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	SunlitCardStyle.decorate(button, Color(UiFactory.PRIMARY, 0.72), 6.0, true, false)


static func stats_text(raw_stats: Variant) -> String:
	if not raw_stats is Dictionary or raw_stats.is_empty():
		return "暂无附加属性"
	var parts := PackedStringArray()
	for stat_id in raw_stats:
		var value := float(raw_stats[stat_id])
		var value_text := "+%.0f" % value if stat_id == "max_health_flat" else "+%.0f%%" % (value * 100.0)
		parts.append("%s %s" % [STAT_NAMES.get(stat_id, str(stat_id)), value_text])
	return "  ·  ".join(parts)


static func add_label(parent: Control, text: String, font_size: int, color: Color, at: Vector2, label_size: Vector2, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := UiFactory.surface_label(text, font_size, color)
	label.position = at
	label.size = label_size
	label.horizontal_alignment = alignment
	label.clip_text = true
	parent.add_child(label)
	return label
