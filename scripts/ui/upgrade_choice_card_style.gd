extends RefCounted

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")

const CARD_SURFACE := Color(1.0, 0.98, 0.9, 0.98)
const CARD_GOLD := Color(1.0, 0.94, 0.72, 0.99)


static func apply_content(views: Dictionary, quality_seams: Array[Panel], shape_id: String, rarity_level: int, highlighted: bool) -> void:
	var accent := _shape_accent(shape_id)
	var soft_surface := _shape_surface(shape_id, highlighted)
	views["icon_back"].add_theme_stylebox_override("panel", _shaped_panel_style(soft_surface, accent, shape_id, 2))
	views["type_panel"].add_theme_stylebox_override("panel", _shaped_panel_style(Color(soft_surface, 0.94), accent, shape_id, 1))
	views["metric_band"].add_theme_stylebox_override("panel", _shaped_panel_style(Color(soft_surface, 0.72), Color(accent, 0.46), shape_id, 1))
	views["title_rule"].color = Color(accent, 0.42)
	views["type"].add_theme_color_override("font_color", accent.darkened(0.2))
	for symbol in views["metric_symbols"]:
		symbol.set_selected(highlighted)
	var special_background := UiFactory.ACCENT_LIGHT if rarity_level == 3 else Color(UiFactory.SURFACE_ALT, 0.98)
	var special_accent := UiFactory.ACCENT_DARK if rarity_level == 3 else UiFactory.RARE
	SunlitCardStyle.apply_panel(views["special_panel"], special_background, special_accent, 6.0, rarity_level == 3, true, "enamel", rarity_level)
	views["special"].add_theme_color_override("font_color", UiFactory.ACCENT_DARK if rarity_level == 3 else UiFactory.PRIMARY_DARK)
	for index in range(quality_seams.size()):
		quality_seams[index].visible = rarity_level >= index + 2
		var seam_style := quality_seams[index].get_theme_stylebox("panel") as StyleBoxFlat
		seam_style.border_color = Color(_quality_accent(shape_id, rarity_level), 0.5 - index * 0.12)


static func apply_button(button: Button, shape_id: String, rarity_level: int, highlighted: bool) -> void:
	var background := CARD_GOLD if highlighted else CARD_SURFACE
	var border := _quality_accent(shape_id, rarity_level)
	var normal := _card_style(background, border, shape_id, highlighted)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = background.lightened(0.025)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = background.darkened(0.04)
	pressed.shadow_offset = Vector2.ZERO
	var disabled_style := _card_style(Color(UiFactory.SURFACE_ALT, 0.88), Color(UiFactory.DISABLED, 0.62), shape_id, false)
	var focus := _card_style(Color.TRANSPARENT, UiFactory.ACCENT, shape_id, true)
	focus.set_expand_margin_all(2.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_stylebox_override("focus", focus)
	SunlitCardStyle.decorate(button, border, _shape_radius(shape_id), false, highlighted, UiFactory.ACCENT, "reward_card", rarity_level)


static func _card_style(background: Color, border: Color, shape_id: String, selected: bool) -> StyleBoxFlat:
	var style := SunlitCardStyle.panel_style(background, border, _shape_radius(shape_id), selected)
	_apply_corners(style, shape_id)
	style.set_border_width_all(3 if selected else 2)
	return style


static func _shaped_panel_style(background: Color, border: Color, kind: String, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	if kind == "relic":
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 12
	elif kind == "supply":
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 5
	else:
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 3
	return style


static func _apply_corners(style: StyleBoxFlat, shape_id: String) -> void:
	if shape_id == "relic":
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 14
	elif shape_id == "supply":
		style.corner_radius_top_left = 22
		style.corner_radius_top_right = 22
		style.corner_radius_bottom_left = 22
		style.corner_radius_bottom_right = 6
	else:
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 4


static func _shape_radius(shape_id: String) -> float:
	return 20.0 if shape_id == "supply" else (14.0 if shape_id == "relic" else 10.0)


static func _shape_accent(shape_id: String) -> Color:
	if shape_id == "relic":
		return UiFactory.RARE
	if shape_id == "supply":
		return UiFactory.HEALING
	return UiFactory.PRIMARY


static func _shape_surface(shape_id: String, highlighted: bool) -> Color:
	if highlighted:
		return UiFactory.ACCENT_LIGHT
	if shape_id == "relic":
		return UiFactory.SURFACE_ALT.lerp(UiFactory.RARE, 0.12)
	if shape_id == "supply":
		return Color(UiFactory.SURFACE_ALT, 0.98)
	return Color(UiFactory.SURFACE_ALT, 0.9)


static func _quality_accent(shape_id: String, rarity_level: int) -> Color:
	if rarity_level == 3:
		return UiFactory.ACCENT_DARK
	if rarity_level == 2:
		return UiFactory.RARE
	return _shape_accent(shape_id)
