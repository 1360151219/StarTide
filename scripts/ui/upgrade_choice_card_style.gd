extends RefCounted

const UiFactory = preload("res://scripts/ui/ui_factory.gd")


static func apply_content(views: Dictionary, rarity_level: int, highlighted: bool) -> void:
	var ink := UiFactory.ACCENT_DARK if highlighted else UiFactory.INK
	views["type"].add_theme_color_override("font_color", UiFactory.HUD_TEXT)
	views["name"].add_theme_color_override("font_color", ink)
	views["description"].add_theme_color_override("font_color", UiFactory.MUTED_INK)
	views["title_rule"].color = Color(UiFactory.ACCENT if highlighted else UiFactory.CANVAS_EDGE, 0.48)
	views["icon_ring"].modulate = Color(1.0, 0.93, 0.68) if highlighted else Color.WHITE
	views["special_panel"].visible = rarity_level > 1
	views["special"].add_theme_color_override("font_color", UiFactory.ACCENT_DARK if highlighted else UiFactory.PRIMARY_DARK)
	for symbol in views["metric_symbols"]:
		symbol.modulate = Color(1.0, 0.93, 0.68) if highlighted else Color.WHITE


static func apply_button(button: Button, rarity_level: int, highlighted: bool) -> void:
	var normal := _button_style(Color(UiFactory.ACCENT_LIGHT, 0.16) if highlighted else Color.TRANSPARENT)
	var hover := _button_style(Color(UiFactory.PRIMARY_LIGHT, 0.10))
	var pressed := _button_style(Color(UiFactory.PRIMARY_DARK, 0.10))
	var disabled := _button_style(Color(UiFactory.SURFACE_ALT, 0.12))
	var focus := _focus_style(UiFactory.ACCENT if highlighted else UiFactory.PRIMARY, rarity_level)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)


static func type_modulate(shape_id: String) -> Color:
	if shape_id == "relic":
		return Color(0.83, 1.0, 0.82)
	if shape_id == "supply":
		return Color(0.76, 1.0, 0.88)
	return Color.WHITE


static func _button_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 4
	return style


static func _focus_style(accent: Color, rarity_level: int) -> StyleBoxFlat:
	var style := _button_style(Color.TRANSPARENT)
	style.border_color = accent
	style.set_border_width_all(2 if rarity_level < 3 else 3)
	style.set_expand_margin_all(1.0)
	return style
