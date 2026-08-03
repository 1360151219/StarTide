extends RefCounted

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CARD_SIZE := Vector2(344, 104)


static func add_page(parent: Control, slot_index: int, pressed_callback: Callable, input_callback: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.size = CARD_SIZE
	button.pivot_offset = CARD_SIZE * 0.5
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.self_modulate = Color.TRANSPARENT
	button.pressed.connect(pressed_callback.bind(slot_index))
	button.gui_input.connect(input_callback)
	parent.add_child(button)
	return button


static func add_chrome(parent: Control) -> Dictionary:
	var page_label := UiFactory.label("", 12, Color("e5f2de"))
	page_label.position = Vector2(355, 98)
	page_label.size = Vector2(96, 26)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_label.z_index = 5
	parent.add_child(page_label)
	var dots := HBoxContainer.new()
	dots.position = Vector2(123, 99)
	dots.size = Vector2(258, 28)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 5)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.z_index = 5
	parent.add_child(dots)
	return {"page_label": page_label, "dots": dots}


static func add_arrow(parent: Control, caption: String, at: Vector2) -> Button:
	var button := Button.new()
	button.position = at
	button.size = Vector2(50, 50)
	button.text = caption
	button.add_theme_font_size_override("font_size", 31)
	button.z_index = 7
	button.add_theme_color_override("font_color", UiFactory.CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", UiFactory.CREAM)
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.8, 0.78, 0.62))
	UiFactory.apply_button_styles(
		button,
		Color(0.025, 0.16, 0.2, 0.94),
		UiFactory.GOLD,
		Color(0.04, 0.1, 0.13, 0.7),
		Color(0.35, 0.46, 0.45, 0.48)
	)
	parent.add_child(button)
	return button


static func add_dot(parent: Container, slot_index: int, pressed_callback: Callable) -> Button:
	var dot := Button.new()
	dot.custom_minimum_size = Vector2(24, 28)
	dot.flat = true
	dot.focus_mode = Control.FOCUS_ALL
	dot.add_theme_font_size_override("font_size", 16)
	dot.add_theme_color_override("font_hover_color", UiFactory.GOLD)
	dot.add_theme_color_override("font_pressed_color", UiFactory.GOLD.darkened(0.08))
	dot.pressed.connect(pressed_callback.bind(slot_index))
	parent.add_child(dot)
	return dot
