extends Control

signal close_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")

var detail_icon: TextureRect
var detail_title: Label
var detail_subtitle: Label
var detail_description: RichTextLabel
var detail_hint: Label
var detail_panel: Panel
var back_button: Button
var navigation_mode := false
var navigation_reserve := 142.0


func build() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_top = 174.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 12
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.02, 0.1, 0.12, 0.72)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)
	detail_panel = _build_panel()
	add_child(detail_panel)
	_build_header(detail_panel)
	_build_record(detail_panel)
	_build_description(detail_panel)
	_build_footer(detail_panel)
	resized.connect(_layout)
	_layout()
	visible = false


func set_navigation_mode(enabled: bool) -> void:
	navigation_mode = enabled
	offset_bottom = -navigation_reserve if enabled else 0.0
	_layout()


func set_navigation_reserve(reserve: float) -> void:
	navigation_reserve = maxf(120.0, reserve)
	offset_bottom = -navigation_reserve if navigation_mode else 0.0
	_layout()


func present(
	entry: Dictionary,
	discovered: bool,
	accent: Color,
	description: String,
	hint: String
) -> void:
	detail_icon.texture = entry["texture"]
	detail_icon.modulate = Color.WHITE if discovered else Color(0.12, 0.2, 0.19, 0.45)
	detail_title.text = entry["name"] if discovered else "？？？"
	detail_title.add_theme_color_override("font_color", UiFactory.INK)
	detail_subtitle.text = entry["subtitle"] if discovered else "这条记录还藏在远征途中"
	detail_subtitle.add_theme_color_override("font_color", accent)
	detail_description.text = description
	detail_description.scroll_to_line(0)
	detail_hint.text = hint
	visible = true


func hide_detail() -> void:
	visible = false


func _build_panel() -> Panel:
	var panel := Panel.new()
	panel.position = Vector2(22, 14)
	SunlitCardStyle.apply_panel(panel, UiFactory.SURFACE, UiFactory.PRIMARY, 14.0, true, false, "map_tag")
	return panel


func _build_header(panel: Panel) -> void:
	var record_mark := _plain_label("图鉴记录", 14, UiFactory.PRIMARY_DARK)
	record_mark.position = Vector2(24, 20)
	record_mark.size = Vector2(160, 24)
	panel.add_child(record_mark)
	var close_button := Button.new()
	close_button.position = Vector2(388, 16)
	close_button.size = Vector2(84, 48)
	close_button.text = "收起"
	close_button.add_theme_font_size_override("font_size", 14)
	SunlitCardStyle.apply_button(close_button, false, UiFactory.PRIMARY)
	close_button.pressed.connect(close_requested.emit)
	panel.add_child(close_button)


func _build_record(panel: Panel) -> void:
	detail_icon = TextureRect.new()
	detail_icon.position = Vector2(28, 68)
	detail_icon.size = Vector2(128, 136)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(detail_icon)
	detail_title = _plain_label("", 28, UiFactory.INK)
	detail_title.position = Vector2(176, 76)
	detail_title.size = Vector2(282, 42)
	detail_title.clip_text = true
	panel.add_child(detail_title)
	detail_subtitle = _plain_label("", 15, UiFactory.PRIMARY_DARK)
	detail_subtitle.position = Vector2(176, 120)
	detail_subtitle.size = Vector2(282, 70)
	detail_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_subtitle.clip_text = true
	panel.add_child(detail_subtitle)
	var divider := ColorRect.new()
	divider.position = Vector2(24, 218)
	divider.size = Vector2(448, 2)
	divider.color = Color(UiFactory.PRIMARY, 0.42)
	panel.add_child(divider)


func _build_description(panel: Panel) -> void:
	detail_description = RichTextLabel.new()
	detail_description.position = Vector2(28, 238)
	detail_description.size = Vector2(440, 372)
	detail_description.bbcode_enabled = false
	detail_description.fit_content = false
	detail_description.scroll_active = true
	detail_description.add_theme_font_size_override("normal_font_size", 17)
	detail_description.add_theme_color_override("default_color", UiFactory.MUTED_INK)
	detail_description.add_theme_constant_override("line_separation", 8)
	panel.add_child(detail_description)


func _build_footer(panel: Panel) -> void:
	detail_hint = _plain_label("", 15, UiFactory.PRIMARY_DARK)
	detail_hint.position = Vector2(28, 620)
	detail_hint.size = Vector2(440, 36)
	detail_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_hint.clip_text = true
	panel.add_child(detail_hint)
	back_button = Button.new()
	back_button.position = Vector2(28, 660)
	back_button.size = Vector2(440, 52)
	back_button.text = "返回收藏"
	back_button.add_theme_font_size_override("font_size", 18)
	SunlitCardStyle.apply_button(back_button, false, UiFactory.PRIMARY)
	back_button.pressed.connect(close_requested.emit)
	panel.add_child(back_button)


func _layout() -> void:
	if not is_instance_valid(detail_panel) or not is_instance_valid(detail_description):
		return
	var panel_height := maxf(468.0, size.y - 36.0)
	detail_panel.size = Vector2(496, panel_height)
	var footer_top := panel_height - 106.0
	detail_description.size.y = maxf(100.0, footer_top - 248.0)
	detail_hint.position.y = footer_top
	back_button.position.y = panel_height - 66.0


func _plain_label(text: String, font_size: int, color: Color) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	return label
