extends RefCounted

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

const STAGE_TOP := Color("123f5a")
const STAGE_BOTTOM := Color("082536")
const SHEET := UiFactory.PAPER
const SHEET_ALT := UiFactory.PAPER_ALT
const INK := UiFactory.INK
const MUTED := UiFactory.MUTED_INK
const COMMON := Color("68737d")
const RARE := Color("2f804d")
const TOP := Color("6f4aa8")
const COMMON_BACKGROUND := Color("e3e6e8")
const RARE_BACKGROUND := Color("37d48b")
const TOP_BACKGROUND := Color("e9e0f5")
const COMMON_BORDER := Color("929aa2")
const RARE_BORDER := Color("039932")
const TOP_BORDER := Color("8b69bd")
const LOCKED := Color("82969a")

const STAT_NAMES := {
	"damage_percent": "技能伤害", "max_health_percent": "最大生命",
	"max_health_flat": "最大生命", "cooldown_reduction": "技能冷却",
	"move_speed_percent": "移动速度", "range_percent": "技能范围",
	"projectile_speed_percent": "弹道速度", "pickup_radius_percent": "拾取范围",
}


static func surface(background: Color, radius := 18.0, border := Color.TRANSPARENT, shadow := true) -> StyleBoxFlat:
	var style := UiFactory.panel_style(background, radius, border)
	style.set_border_width_all(2 if border.a > 0.0 else 0)
	if not shadow:
		style.shadow_size = 0
		style.shadow_color = Color.TRANSPARENT
	return style


static func paper_card(alternate := false, radius := 18.0, border := UiFactory.PAPER_STROKE, shadow := true) -> StyleBoxFlat:
	return UiFactory.paper_panel_style(border, alternate, radius, shadow)


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


static func quality_card(rarity_id: String, radius := 14.0, selected := false) -> StyleBoxFlat:
	var style := surface(rarity_background(rarity_id), radius, rarity_border(rarity_id))
	style.set_border_width_all(3 if selected else 2)
	style.shadow_color = Color(UiFactory.GOLD, 0.46) if selected else Color(0.03, 0.15, 0.19, 0.18)
	style.shadow_size = 6 if selected else 2
	style.shadow_offset = Vector2(0, 2 if selected else 1)
	return style


static func apply_segment(button: Button, selected: bool) -> void:
	UiFactory.apply_secondary_button(button, selected)


static func apply_item_card(button: Button, rarity_id: String, selected: bool) -> void:
	var normal := quality_card(rarity_id, 14.0, selected)
	var hover := quality_card(rarity_id, 14.0, selected)
	hover.bg_color = normal.bg_color.lightened(0.025)
	var pressed := quality_card(rarity_id, 14.0, selected)
	pressed.bg_color = normal.bg_color.darkened(0.04)
	var focus := surface(Color.TRANSPARENT, 14.0, UiFactory.GOLD, false)
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", INK)


static func apply_empty_slot_card(button: Button) -> void:
	var normal := paper_card(true, 14.0, UiFactory.GOLD)
	var hover := paper_card(true, 14.0, UiFactory.GOLD_LIGHT)
	var pressed := paper_card(true, 14.0, UiFactory.GOLD)
	pressed.bg_color = normal.bg_color.darkened(0.04)
	var focus := surface(Color.TRANSPARENT, 14.0, UiFactory.GOLD, false)
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", INK)


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
