extends CanvasLayer

signal resume_requested
signal home_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const AudioSettingsPanel = preload("res://scripts/ui/audio_settings_panel.gd")
const PauseBuildStrip = preload("res://scripts/ui/pause_build_strip.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")

var audio_settings: Control
var build_icons
var screen_overlay: ColorRect
var design_frame: Control
var pause_card: Panel


func configure(audio: Node) -> void:
	layer = 30
	screen_overlay = ColorRect.new()
	screen_overlay.color = Color(0.015, 0.075, 0.09, 0.76)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_overlay)
	ScreenLayout.fill(screen_overlay)
	design_frame = DesignFrame.new()
	screen_overlay.add_child(design_frame)
	_build_pause_card()
	_build_audio_settings(audio)
	visible = false


func show_build(build_state: RefCounted) -> void:
	build_icons.present(build_state)


func _build_pause_card() -> void:
	pause_card = Panel.new()
	pause_card.position = Vector2(24, 145)
	pause_card.size = Vector2(492, 670)
	SunlitCardStyle.apply_panel(pause_card, Color(UiFactory.SURFACE, 0.98), UiFactory.PRIMARY, 12.0, true, false, "canvas")
	design_frame.add_child(pause_card)
	var expedition_mark := SunlitGlyph.new()
	expedition_mark.glyph_id = "expedition"
	expedition_mark.set_selected(true)
	expedition_mark.position = Vector2(230, 20)
	expedition_mark.size = Vector2(32, 32)
	pause_card.add_child(expedition_mark)
	var title := _plain_label("冒险暂停", 34, UiFactory.INK)
	title.position = Vector2(30, 52)
	title.size = Vector2(432, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_card.add_child(title)
	var hint := _plain_label("远征已经暂停，准备好就继续出发", 16, UiFactory.MUTED_INK)
	hint.position = Vector2(30, 100)
	hint.size = Vector2(432, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_card.add_child(hint)
	_build_summary_card()
	_add_button(pause_card, "继续冒险", Vector2(30, 356), Vector2(432, 70), true, resume_requested.emit)
	var audio_hint := _plain_label("需要调整听感？", 14, UiFactory.MUTED_INK)
	audio_hint.position = Vector2(30, 448)
	audio_hint.size = Vector2(170, 48)
	audio_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_card.add_child(audio_hint)
	_add_button(pause_card, "返回关卡大厅", Vector2(30, 548), Vector2(432, 62), false, home_requested.emit)
	var footnote := _plain_label("返回大厅将结束本次远征", 13, Color("8a6b58"))
	footnote.position = Vector2(30, 616)
	footnote.size = Vector2(432, 28)
	footnote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_card.add_child(footnote)


func _build_summary_card() -> void:
	var summary_card := Panel.new()
	summary_card.position = Vector2(30, 154)
	summary_card.size = Vector2(432, 184)
	SunlitCardStyle.apply_panel(summary_card, UiFactory.SURFACE_ALT, Color(UiFactory.PRIMARY, 0.58), 10.0, false, true, "ribbon")
	pause_card.add_child(summary_card)
	var section_mark := _plain_label("本局构筑", 21, UiFactory.INK)
	section_mark.position = Vector2(20, 16)
	section_mark.size = Vector2(196, 32)
	summary_card.add_child(section_mark)
	build_icons = PauseBuildStrip.new()
	build_icons.position = Vector2(26, 88)
	build_icons.size = Vector2(380, 62)
	summary_card.add_child(build_icons)


func _build_audio_settings(audio: Node) -> void:
	audio_settings = AudioSettingsPanel.new()
	audio_settings.position = Vector2(362, 593)
	design_frame.add_child(audio_settings)
	audio_settings.configure(audio, true)


func _add_button(parent: Control, text: String, at: Vector2, button_size: Vector2, primary: bool, callback: Callable) -> void:
	var button := Button.new()
	button.position = at
	button.size = button_size
	button.text = text
	button.add_theme_font_size_override("font_size", 22 if primary else 19)
	button.add_theme_color_override("font_color", UiFactory.INK)
	button.add_theme_color_override("font_hover_color", UiFactory.INK)
	button.add_theme_color_override("font_pressed_color", UiFactory.INK)
	if primary:
		UiFactory.apply_primary_button(button)
	else:
		UiFactory.apply_secondary_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)


func _plain_label(text: String, font_size: int, color: Color) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	return label
