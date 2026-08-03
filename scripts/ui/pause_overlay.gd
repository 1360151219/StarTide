extends CanvasLayer

signal resume_requested
signal home_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const AudioSettingsPanel = preload("res://scripts/ui/audio_settings_panel.gd")
const PauseBuildStrip = preload("res://scripts/ui/pause_build_strip.gd")
const VICTORY_CREST := preload("res://assets/generated/ui/victory_crest.png")

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
	pause_card.position = Vector2(24, 74)
	pause_card.size = Vector2(492, 812)
	pause_card.add_theme_stylebox_override(
		"panel",
		UiFactory.panel_style(Color(1.0, 0.975, 0.89, 0.97), 30.0, Color("f4b638"))
	)
	design_frame.add_child(pause_card)
	var star_mark := _plain_label("✦", 22, UiFactory.GOLD)
	star_mark.position = Vector2(222, 24)
	star_mark.size = Vector2(48, 32)
	star_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_card.add_child(star_mark)
	var title := _plain_label("冒险暂停", 34, UiFactory.INK)
	title.position = Vector2(30, 52)
	title.size = Vector2(432, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_card.add_child(title)
	var hint := _plain_label("星潮已经停住，准备好就继续出发", 16, UiFactory.MUTED_INK)
	hint.position = Vector2(30, 100)
	hint.size = Vector2(432, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_card.add_child(hint)
	_add_button(pause_card, "▶  继续冒险", Vector2(30, 144), Vector2(432, 74), true, resume_requested.emit)
	_build_summary_card()
	var audio_hint := _plain_label("需要调整听感？", 14, UiFactory.MUTED_INK)
	audio_hint.position = Vector2(30, 592)
	audio_hint.size = Vector2(170, 48)
	audio_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_card.add_child(audio_hint)
	_add_button(pause_card, "返回关卡大厅", Vector2(30, 694), Vector2(432, 62), false, home_requested.emit)
	var footnote := _plain_label("返回大厅将结束本次远征", 13, Color("8a6b58"))
	footnote.position = Vector2(30, 760)
	footnote.size = Vector2(432, 28)
	footnote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_card.add_child(footnote)


func _build_summary_card() -> void:
	var summary_card := Panel.new()
	summary_card.position = Vector2(30, 244)
	summary_card.size = Vector2(432, 324)
	summary_card.add_theme_stylebox_override(
		"panel",
		UiFactory.panel_style(Color(0.89, 0.97, 0.91, 0.98), 22.0, Color(0.08, 0.55, 0.59, 0.48))
	)
	pause_card.add_child(summary_card)
	var section_mark := _plain_label("本局构筑", 21, UiFactory.INK)
	section_mark.position = Vector2(20, 16)
	section_mark.size = Vector2(196, 32)
	summary_card.add_child(section_mark)
	var crest := TextureRect.new()
	crest.position = Vector2(126, 54)
	crest.size = Vector2(180, 180)
	crest.texture = VICTORY_CREST
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.modulate = Color(1.0, 1.0, 1.0, 0.13)
	crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_card.add_child(crest)
	build_icons = PauseBuildStrip.new()
	build_icons.position = Vector2(26, 126)
	build_icons.size = Vector2(380, 62)
	summary_card.add_child(build_icons)


func _build_audio_settings(audio: Node) -> void:
	audio_settings = AudioSettingsPanel.new()
	audio_settings.position = Vector2(362, 666)
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
	UiFactory.apply_button_styles(
		button,
		Color("f5ad35") if primary else Color("f7f1df"),
		Color("fff0b0") if primary else Color("3b8588")
	)
	button.pressed.connect(callback)
	parent.add_child(button)


func _plain_label(text: String, font_size: int, color: Color) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	return label
