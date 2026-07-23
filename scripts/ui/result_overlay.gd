extends CanvasLayer

signal replay_requested
signal home_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")

var heading: Label
var summary: Label
var reward_label: Label
var build_label: Label
var screen_overlay: ColorRect
var design_frame: Control
var result_card: Panel
var content_margin: MarginContainer
var content_stack: VBoxContainer


func _ready() -> void:
	layer = 40
	screen_overlay = ColorRect.new()
	screen_overlay.color = Color(0.006, 0.04, 0.07, 0.95)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_overlay)
	ScreenLayout.fill(screen_overlay)
	design_frame = DesignFrame.new()
	screen_overlay.add_child(design_frame)
	result_card = Panel.new()
	result_card.position = Vector2(42, 104)
	result_card.size = Vector2(456, 500)
	result_card.add_theme_stylebox_override("panel", UiFactory.panel_style(UiFactory.GLASS, 24.0, UiFactory.GOLD))
	design_frame.add_child(result_card)
	content_margin = MarginContainer.new()
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_theme_constant_override("margin_left", 26)
	content_margin.add_theme_constant_override("margin_top", 20)
	content_margin.add_theme_constant_override("margin_right", 26)
	content_margin.add_theme_constant_override("margin_bottom", 18)
	result_card.add_child(content_margin)
	content_stack = VBoxContainer.new()
	content_stack.add_theme_constant_override("separation", 10)
	content_margin.add_child(content_stack)
	heading = UiFactory.label("", 38, UiFactory.CORAL)
	heading.custom_minimum_size = Vector2(0, 60)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.clip_text = true
	content_stack.add_child(heading)
	summary = UiFactory.label("", 22, UiFactory.PALE)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.clip_text = true
	content_stack.add_child(summary)
	reward_label = UiFactory.label("", 18, UiFactory.CYAN)
	reward_label.custom_minimum_size = Vector2(0, 92)
	reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.clip_text = true
	content_stack.add_child(reward_label)
	build_label = UiFactory.label("", 15, UiFactory.PALE_MUTED)
	build_label.custom_minimum_size = Vector2(0, 88)
	build_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_label.clip_text = true
	content_stack.add_child(build_label)
	_add_button(design_frame, "再战一次", Vector2(92, 620), true, replay_requested.emit)
	_add_button(design_frame, "返回关卡大厅", Vector2(92, 718), false, home_requested.emit)
	visible = false


func show_result(title: String, body: String, reward_text: String, won: bool, build_text := "") -> void:
	heading.text = title
	heading.add_theme_color_override("font_color", UiFactory.GOLD if won else UiFactory.CORAL)
	summary.text = body
	reward_label.text = reward_text
	build_label.text = build_text
	visible = true


func _add_button(parent: Control, text: String, at: Vector2, primary: bool, callback: Callable) -> void:
	var button := Button.new()
	button.position = at
	button.size = Vector2(356, 72)
	button.text = text
	button.add_theme_font_size_override("font_size", 23)
	UiFactory.apply_glass_button(button, primary, UiFactory.GOLD if primary else UiFactory.STROKE)
	button.pressed.connect(callback)
	parent.add_child(button)
