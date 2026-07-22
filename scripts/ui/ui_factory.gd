extends RefCounted

const INK := Color(0.09, 0.18, 0.25, 1.0)
const MUTED_INK := Color(0.27, 0.41, 0.47, 1.0)
const CREAM := Color(1.0, 0.98, 0.89, 1.0)
const SURFACE := Color(1.0, 0.98, 0.91, 0.96)
const SURFACE_ALT := Color(0.87, 0.97, 0.94, 0.96)
const PRIMARY := Color(0.08, 0.55, 0.59, 1.0)
const PRIMARY_DARK := Color(0.04, 0.38, 0.45, 1.0)
const SKY := Color(0.42, 0.78, 0.91, 1.0)
const GOLD := Color(0.96, 0.69, 0.2, 1.0)
const CORAL := Color(0.94, 0.36, 0.36, 1.0)
const LEAF := Color(0.32, 0.68, 0.31, 1.0)
const STROKE := Color(0.16, 0.46, 0.52, 1.0)
const NIGHT := Color(0.012, 0.065, 0.1, 0.96)
const GLASS := Color(0.018, 0.1, 0.15, 0.94)
const GLASS_ALT := Color(0.025, 0.16, 0.2, 0.92)
const PALE := Color(1.0, 0.95, 0.75, 1.0)
const PALE_MUTED := Color(0.72, 0.85, 0.82, 1.0)
const CYAN := Color(0.28, 0.82, 0.79, 1.0)


static func label(text: String, font_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_constant_override("outline_size", 2)
	var outline := Color(1.0, 0.98, 0.9, 0.8) if color.get_luminance() < 0.48 else Color(0.04, 0.12, 0.18, 0.72)
	node.add_theme_color_override("font_outline_color", outline)
	return node


static func panel_style(background: Color, radius: float, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.03, 0.15, 0.19, 0.2)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


static func button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := panel_style(background, 18.0, border)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


static func apply_button_styles(button: Button, background: Color, border: Color, disabled_background := Color(0.65, 0.72, 0.69, 0.9), disabled_border := Color(0.5, 0.58, 0.55, 0.7)) -> void:
	button.add_theme_stylebox_override("normal", button_style(background, border))
	button.add_theme_stylebox_override("hover", button_style(background.lightened(0.08), GOLD))
	button.add_theme_stylebox_override("pressed", button_style(background.darkened(0.09), border.lightened(0.12)))
	button.add_theme_stylebox_override("disabled", button_style(disabled_background, disabled_border))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color(1.0, 0.88, 0.48, 0.95)
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(18)
	focus.set_expand_margin_all(2.0)
	button.add_theme_stylebox_override("focus", focus)


static func apply_glass_button(button: Button, primary := false, accent := GOLD) -> void:
	button.add_theme_color_override("font_color", PALE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", PALE)
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.8, 0.78, 0.88))
	apply_button_styles(
		button,
		PRIMARY_DARK if primary else GLASS_ALT,
		accent,
		Color(0.04, 0.1, 0.13, 0.92),
		Color(0.3, 0.45, 0.45, 0.75)
	)


static func flat_bar_style(color: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	return style
