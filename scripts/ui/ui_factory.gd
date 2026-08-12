extends RefCounted

const CEREMONIAL_SERIF := preload("res://assets/fonts/NotoSerifSC-UI.otf")
const EXPEDITION_HEADING := preload("res://assets/fonts/SmileySans-Oblique.otf")

const BACKGROUND := Color("ddefe7")
const SURFACE := Color("fff6e2")
const SURFACE_ALT := Color("eaf4e8")
const INK := Color("243c43")
const MUTED_INK := Color("5c7073")
const PRIMARY := Color("4fa7b5")
const PRIMARY_DARK := Color("286b78")
const PRIMARY_LIGHT := Color("8dcbd1")
const SUPPORTING := Color("76b77a")
const ACCENT := Color("f2b84b")
const ACCENT_LIGHT := Color("fff0b2")
const ACCENT_DARK := Color("8b5a16")
const DANGER := Color("e45b5b")
const DANGER_DARK := Color("9f343b")
const HEALING := Color("58b985")
const BLOCK := Color("6e91b3")
const RARE := Color("42b873")
const DISABLED := Color("8a9995")
const HUD_SURFACE := Color(0.075, 0.22, 0.25, 0.95)
const HUD_SURFACE_ALT := Color(0.10, 0.31, 0.34, 0.94)
const HUD_TEXT := Color("fff6e2")
const HUD_TEXT_MUTED := Color("c8ded7")
const CANVAS_EDGE := Color("b98943")

const SPACE_XS := 4.0
const SPACE_S := 8.0
const SPACE_M := 16.0
const SPACE_L := 24.0
const RADIUS_S := 6.0
const RADIUS_M := 10.0
const RADIUS_L := 14.0


static func ceremonial_font(weight := 400) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = CEREMONIAL_SERIF
	font.variation_opentype = {"wght": weight}
	return font


static func expedition_heading_font() -> Font:
	return EXPEDITION_HEADING


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


static func texture_rect(texture: Texture2D, mode := TextureRect.STRETCH_SCALE) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = mode
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


static func apply_key_heading(node: Label, font_size := 22, color := INK) -> void:
	node.add_theme_font_override("font", expedition_heading_font())
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_constant_override("outline_size", 0)
	node.add_theme_constant_override("shadow_outline_size", 0)


static func apply_inner_page_title(node: Label, font_size := 34) -> void:
	apply_key_heading(node, font_size, INK)


static func apply_level_title(node: Label, font_size := 25) -> void:
	apply_key_heading(node, font_size, INK)


static func panel_style(background: Color, radius: float, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = mini(int(radius), 6)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = mini(int(radius), 6)
	style.border_color = border
	var border_width := 2 if border.a > 0.0 else 0
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.shadow_color = Color(INK, 0.16)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style


static func paper_panel_style(accent := CANVAS_EDGE, alternate := false, radius := RADIUS_M, shadow := true) -> StyleBoxFlat:
	var style := panel_style(SURFACE_ALT if alternate else SURFACE, radius, accent)
	style.set_border_width_all(2 if accent.a > 0.0 else 0)
	style.shadow_color = Color(INK, 0.16) if shadow else Color.TRANSPARENT
	style.shadow_size = 2 if shadow else 0
	style.shadow_offset = Vector2(0, 1) if shadow else Vector2.ZERO
	style.content_margin_left = SPACE_M
	style.content_margin_right = SPACE_M
	style.content_margin_top = SPACE_M
	style.content_margin_bottom = SPACE_M
	return style


static func hud_panel_style(accent := Color(PRIMARY_LIGHT, 0.72), radius := RADIUS_M) -> StyleBoxFlat:
	return panel_style(HUD_SURFACE, radius, accent)


static func button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := panel_style(background, 10.0, border)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


static func apply_button_styles(button: Button, background: Color, border: Color, disabled_background := Color(0.65, 0.72, 0.69, 0.9), disabled_border := Color(0.5, 0.58, 0.55, 0.7)) -> void:
	button.add_theme_stylebox_override("normal", button_style(background, border))
	button.add_theme_stylebox_override("hover", button_style(background.lightened(0.05), border.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", button_style(background.darkened(0.09), border.lightened(0.12)))
	button.add_theme_stylebox_override("disabled", button_style(disabled_background, disabled_border))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color(ACCENT, 0.95)
	focus.set_border_width_all(3)
	focus.corner_radius_top_left = 6
	focus.corner_radius_top_right = 10
	focus.corner_radius_bottom_left = 10
	focus.corner_radius_bottom_right = 6
	focus.set_expand_margin_all(2.0)
	button.add_theme_stylebox_override("focus", focus)


static func apply_primary_button(button: Button) -> void:
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color(MUTED_INK, 0.82))
	button.add_theme_constant_override("outline_size", 0)
	apply_button_styles(
		button,
		ACCENT,
		ACCENT_LIGHT,
		Color(0.73, 0.72, 0.61, 0.92),
		Color(0.54, 0.57, 0.51, 0.72)
	)


static func apply_secondary_button(button: Button, selected := false) -> void:
	button.add_theme_color_override("font_color", HUD_TEXT if selected else INK)
	button.add_theme_color_override("font_hover_color", HUD_TEXT if selected else INK)
	button.add_theme_color_override("font_pressed_color", HUD_TEXT if selected else INK)
	button.add_theme_color_override("font_disabled_color", Color(MUTED_INK, 0.9))
	apply_button_styles(
		button,
		PRIMARY_DARK if selected else SURFACE,
		PRIMARY if not selected else ACCENT,
		Color(0.74, 0.79, 0.75, 0.92),
		Color(0.48, 0.57, 0.54, 0.7)
	)


static func apply_hud_button(button: Button, primary := false, accent := ACCENT) -> void:
	button.add_theme_color_override("font_color", HUD_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", HUD_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.8, 0.78, 0.88))
	apply_button_styles(
		button,
		PRIMARY_DARK if primary else HUD_SURFACE_ALT,
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
