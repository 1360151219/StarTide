extends CanvasLayer

signal resume_requested
signal home_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const AudioSettingsPanel = preload("res://scripts/ui/audio_settings_panel.gd")

var audio_settings: Control
var screen_overlay: ColorRect
var design_frame: Control


func configure(audio: Node) -> void:
	layer = 30
	screen_overlay = ColorRect.new()
	screen_overlay.color = Color(0.012, 0.02, 0.07, 0.95)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_overlay)
	ScreenLayout.fill(screen_overlay)
	design_frame = DesignFrame.new()
	screen_overlay.add_child(design_frame)
	var title := UiFactory.label("游戏暂停", 38, Color("f6d782"))
	title.position = Vector2(30, 220)
	title.size = Vector2(480, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	design_frame.add_child(title)
	var hint := UiFactory.label("星潮会在你回来时继续流动", 20, Color("c6d7ea"))
	hint.position = Vector2(30, 292)
	hint.size = Vector2(480, 40)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	design_frame.add_child(hint)
	audio_settings = AudioSettingsPanel.new()
	audio_settings.position = Vector2(136, 350)
	design_frame.add_child(audio_settings)
	audio_settings.configure(audio)
	_add_button(design_frame, "继续游戏", Vector2(92, 458), Color("70e8ff"), resume_requested.emit)
	_add_button(design_frame, "返回英雄选择", Vector2(92, 568), Color("8da5bd"), home_requested.emit)
	visible = false


func _add_button(parent: Control, text: String, at: Vector2, border: Color, callback: Callable) -> void:
	var button := Button.new()
	button.position = at
	button.size = Vector2(356, 72)
	button.text = text
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_stylebox_override("normal", UiFactory.button_style(Color("173c63"), border))
	button.pressed.connect(callback)
	parent.add_child(button)
