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
	if rarity_id == "top":
		return TOP
	return RARE if rarity_id == "rare" else COMMON


static func rarity_background(rarity_id: String) -> Color:
	if rarity_id == "top":
		return TOP_BACKGROUND
	return RARE_BACKGROUND if rarity_id == "rare" else COMMON_BACKGROUND


static func rarity_border(rarity_id: String) -> Color:
	if rarity_id == "top":
		return TOP_BORDER
	return RARE_BORDER if rarity_id == "rare" else COMMON_BORDER


static func rarity_level(rarity_id: String) -> int:
	if rarity_id == "top":
		return 3
	return 2 if rarity_id == "rare" else 1


static func quality_card(rarity_id: String, radius := 14.0, selected := false) -> StyleBoxFlat:
	var style := SunlitCardStyle.panel_style(rarity_background(rarity_id), rarity_border(rarity_id), radius, selected)
	style.set_border_width_all(3 if selected else 2)
	style.shadow_color = Color(UiFactory.INK, 0.24) if selected else Color(UiFactory.INK, 0.12)
	style.shadow_size = 4 if selected else 2
	style.shadow_offset = Vector2(0, 2 if selected else 1)
	return style


static func apply_segment(button: Button, selected: bool) -> void:
	SunlitCardStyle.apply_button(button, selected, UiFactory.PRIMARY, UiFactory.PRIMARY_DARK, UiFactory.SURFACE)


static func apply_power_label(label: Label) -> void:
	label.add_theme_font_override("font", UiFactory.home_serif(900))
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", POWER)
	label.add_theme_color_override("font_outline_color", UiFactory.SURFACE)
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_shadow_color", Color(UiFactory.ACCENT, 0.24))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 3)


static func apply_item_card(button: Button, rarity_id: String, selected: bool) -> void:
	var normal := quality_card(rarity_id, 14.0, selected)
	var hover := quality_card(rarity_id, 14.0, selected)
	hover.bg_color = normal.bg_color.lightened(0.025)
	var pressed := quality_card(rarity_id, 14.0, selected)
	pressed.bg_color = normal.bg_color.darkened(0.04)
	var focus := surface(Color.TRANSPARENT, 14.0, UiFactory.ACCENT, false)
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color(MUTED, 0.58))
	SunlitCardStyle.decorate(button, rarity_border(rarity_id), 10.0, true, selected, UiFactory.ACCENT, "canvas", rarity_level(rarity_id))


static func apply_empty_slot_card(button: Button) -> void:
	var normal := paper_card(true, 14.0, Color(UiFactory.PRIMARY, 0.72))
	var hover := paper_card(true, 14.0, UiFactory.PRIMARY_LIGHT)
	var pressed := paper_card(true, 14.0, UiFactory.PRIMARY)
	pressed.bg_color = normal.bg_color.darkened(0.04)
	var focus := surface(Color.TRANSPARENT, 14.0, UiFactory.ACCENT, false)
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	SunlitCardStyle.decorate(button, Color(UiFactory.PRIMARY, 0.72), 10.0, true, false)


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
