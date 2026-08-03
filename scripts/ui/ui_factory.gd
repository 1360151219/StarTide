extends RefCounted

const HOME_SERIF := preload("res://assets/fonts/NotoSerifSC-UI.otf")

const INK := Color("183640")
const MUTED_INK := Color("456978")
const CREAM := Color("fff5d7")
const SURFACE := Color(1.0, 0.973, 0.91, 0.98)
const SURFACE_ALT := Color(1.0, 0.984, 0.94, 0.98)
const PRIMARY := Color("087e8b")
const PRIMARY_DARK := Color("075f6d")
const ACTION := Color("f5760a")
const ACTION_DARK := Color("b74a08")
const SKY := Color("6bc7e8")
const GOLD := Color("e8b84d")
const GOLD_LIGHT := Color("ffe7aa")
const CORAL := Color("f05c5c")
const LEAF := Color("61b74d")
const STROKE := Color("0a7886")
const NIGHT := Color(0.024, 0.09, 0.13, 0.96)
const GLASS := Color(0.0, 0.165, 0.227, 0.94)
const GLASS_ALT := Color(0.02, 0.24, 0.29, 0.92)
const PALE := Color("ffe59c")
const PALE_MUTED := Color("b7d8d1")
const CYAN := Color("50d8d0")
const PAPER := Color("fff8e5")
const PAPER_ALT := Color("fffdf4")
const PAPER_STROKE := Color("d6a74d")

const SPACE_XS := 4.0
const SPACE_S := 8.0
const SPACE_M := 16.0
const SPACE_L := 24.0
const RADIUS_S := 12.0
const RADIUS_M := 18.0
const RADIUS_L := 26.0


static func home_serif(weight := 400) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = HOME_SERIF
	font.variation_opentype = {"wght": weight}
	return font


static func label(text: String, font_size: int, color: Color, outlined := true) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_constant_override("outline_size", 2 if outlined else 0)
	if outlined:
		var outline := Color(1.0, 0.98, 0.9, 0.8) if color.get_luminance() < 0.48 else Color(0.04, 0.12, 0.18, 0.72)
		node.add_theme_color_override("font_outline_color", outline)
	return node


static func surface_label(text: String, font_size: int, color := INK) -> Label:
	return label(text, font_size, color, false)


static func apply_home_title(node: Label, font_size := 43) -> void:
	node.add_theme_font_override("font", home_serif(900))
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", GOLD_LIGHT)
	node.add_theme_color_override("font_outline_color", Color("e4bd63"))
	node.add_theme_constant_override("outline_size", 2)
	node.add_theme_color_override("font_shadow_color", Color(0.03, 0.11, 0.14, 0.94))
	node.add_theme_constant_override("shadow_offset_x", 0)
	node.add_theme_constant_override("shadow_offset_y", 2)
	node.add_theme_constant_override("shadow_outline_size", 5)


static func apply_home_subtitle(node: Label, font_size := 16) -> void:
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", CREAM)
	node.add_theme_color_override("font_outline_color", Color(0.03, 0.15, 0.2, 0.88))
	node.add_theme_constant_override("outline_size", 2)


static func apply_inner_page_title(node: Label, font_size := 34) -> void:
	apply_home_title(node, font_size)
	node.add_theme_constant_override("outline_size", 3)
	node.add_theme_constant_override("shadow_outline_size", 1)


static func apply_level_title(node: Label, font_size := 25) -> void:
	node.add_theme_font_override("font", home_serif(500))
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", INK)
	node.add_theme_constant_override("outline_size", 0)


static func panel_style(background: Color, radius: float, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.border_color = border
	var border_width := 2 if border.a > 0.0 else 0
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.shadow_color = Color(0.03, 0.15, 0.19, 0.2)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


static func paper_panel_style(accent := PAPER_STROKE, alternate := false, radius := RADIUS_M, shadow := true) -> StyleBoxFlat:
	var style := panel_style(PAPER_ALT if alternate else PAPER, radius, accent)
	style.set_border_width_all(2 if accent.a > 0.0 else 0)
	style.shadow_color = Color(0.03, 0.15, 0.19, 0.2) if shadow else Color.TRANSPARENT
	style.shadow_size = 2 if shadow else 0
	style.shadow_offset = Vector2(0, 1) if shadow else Vector2.ZERO
	style.content_margin_left = SPACE_M
	style.content_margin_right = SPACE_M
	style.content_margin_top = SPACE_M
	style.content_margin_bottom = SPACE_M
	return style


static func glass_panel_style(accent := Color(CYAN, 0.44), radius := RADIUS_M) -> StyleBoxFlat:
	return panel_style(GLASS, radius, accent)


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


static func apply_primary_button(button: Button) -> void:
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", CREAM)
	button.add_theme_color_override("font_disabled_color", Color(MUTED_INK, 0.82))
	button.add_theme_color_override("font_outline_color", Color(ACTION_DARK, 0.94))
	button.add_theme_constant_override("outline_size", 2)
	apply_button_styles(
		button,
		ACTION,
		GOLD_LIGHT,
		Color(0.73, 0.72, 0.61, 0.92),
		Color(0.54, 0.57, 0.51, 0.72)
	)


static func apply_secondary_button(button: Button, selected := false) -> void:
	button.add_theme_color_override("font_color", CREAM if selected else INK)
	button.add_theme_color_override("font_hover_color", CREAM if selected else INK)
	button.add_theme_color_override("font_pressed_color", CREAM if selected else INK)
	button.add_theme_color_override("font_disabled_color", Color(MUTED_INK, 0.9))
	apply_button_styles(
		button,
		PRIMARY_DARK if selected else SURFACE_ALT,
		GOLD,
		Color(0.74, 0.79, 0.75, 0.92),
		Color(0.48, 0.57, 0.54, 0.7)
	)


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
