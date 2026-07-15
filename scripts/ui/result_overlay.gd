extends CanvasLayer

signal replay_requested
signal home_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")

var heading: Label
var summary: Label
var reward_label: Label
var screen_overlay: ColorRect
var design_frame: Control


func _ready() -> void:
	layer = 40
	screen_overlay = ColorRect.new()
	screen_overlay.color = Color(0.012, 0.02, 0.07, 1.0)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_overlay)
	ScreenLayout.fill(screen_overlay)
	design_frame = DesignFrame.new()
	screen_overlay.add_child(design_frame)
	heading = UiFactory.label("", 38, Color("f28aa0"))
	heading.position = Vector2(30, 135)
	heading.size = Vector2(480, 54)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	design_frame.add_child(heading)
	summary = UiFactory.label("", 22, Color("e5ecff"))
	summary.position = Vector2(30, 210)
	summary.size = Vector2(480, 280)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	design_frame.add_child(summary)
	reward_label = UiFactory.label("", 18, Color("f6d782"))
	reward_label.position = Vector2(30, 460)
	reward_label.size = Vector2(480, 58)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	design_frame.add_child(reward_label)
	_add_button(design_frame, "再战一次", Vector2(92, 550), Color("f2ca72"), replay_requested.emit)
	_add_button(design_frame, "返回星港", Vector2(92, 648), Color("7890aa"), home_requested.emit)
	visible = false


func show_result(title: String, body: String, reward_text: String, won: bool) -> void:
	heading.text = title
	heading.add_theme_color_override("font_color", Color("f6d782") if won else Color("f28aa0"))
	summary.text = body
	reward_label.text = reward_text
	visible = true


func _add_button(parent: Control, text: String, at: Vector2, border: Color, callback: Callable) -> void:
	var button := Button.new()
	button.position = at
	button.size = Vector2(356, 72)
	button.text = text
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_stylebox_override("normal", UiFactory.button_style(Color("173c63"), border))
	button.pressed.connect(callback)
	parent.add_child(button)
