extends RefCounted

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitFrame = preload("res://scripts/ui/sunlit_frame.gd")


static func panel_style(
	background := UiFactory.SURFACE,
	accent := UiFactory.PRIMARY,
	radius := UiFactory.RADIUS_M,
	selected := false,
	shadow := true
) -> StyleBoxFlat:
	var style := UiFactory.panel_style(background, radius, accent)
	style.set_border_width_all(2)
	style.shadow_color = Color(UiFactory.INK, 0.24 if selected else 0.14)
	style.shadow_size = 5 if selected else (3 if shadow else 0)
	style.shadow_offset = Vector2(0, 2) if shadow else Vector2.ZERO
	style.content_margin_left = UiFactory.SPACE_M
	style.content_margin_right = UiFactory.SPACE_M
	style.content_margin_top = UiFactory.SPACE_M
	style.content_margin_bottom = UiFactory.SPACE_M
	return style


static func decorate(
	target: Control,
	accent := UiFactory.PRIMARY,
	radius := UiFactory.RADIUS_M,
	compact := false,
	selected := false,
	ornament := UiFactory.ACCENT,
	variant := "canvas",
	rarity_level := 1
) -> Control:
	var frame := target.get_node_or_null("SunlitFrame") as Control
	if frame == null:
		frame = SunlitFrame.new()
		frame.name = "SunlitFrame"
		target.add_child(frame, false, Node.INTERNAL_MODE_FRONT)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.call("configure", accent, radius, compact, selected, ornament, variant, rarity_level)
	return frame


static func apply_panel(
	panel: Control,
	background := UiFactory.SURFACE,
	accent := UiFactory.PRIMARY,
	radius := UiFactory.RADIUS_M,
	selected := false,
	compact := false,
	variant := "canvas",
	rarity_level := 1
) -> void:
	panel.add_theme_stylebox_override("panel", panel_style(background, accent, radius, selected))
	decorate(panel, accent, radius, compact, selected, UiFactory.ACCENT, variant, rarity_level)


static func apply_button(
	button: Button,
	selected := false,
	accent := UiFactory.PRIMARY,
	selected_background := UiFactory.PRIMARY_DARK,
	normal_background := UiFactory.SURFACE,
	variant := "canvas"
) -> void:
	var normal := panel_style(selected_background if selected else normal_background, accent, 10.0, selected)
	normal.content_margin_left = 18.0
	normal.content_margin_right = 18.0
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 10.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.04)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.06)
	pressed.shadow_offset = Vector2.ZERO
	pressed.shadow_size = 1
	var disabled := panel_style(Color(UiFactory.SURFACE_ALT, 0.94), Color(UiFactory.DISABLED, 0.62), 10.0, false, false)
	var focus := panel_style(Color.TRANSPARENT, UiFactory.ACCENT, 10.0, true, false)
	focus.set_expand_margin_all(2.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)
	var text_color := UiFactory.HUD_TEXT if selected else UiFactory.INK
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", UiFactory.MUTED_INK)
	button.add_theme_constant_override("outline_size", 0)
	decorate(button, accent, 10.0, true, selected, UiFactory.ACCENT, variant)
