extends Control

signal close_requested
signal category_requested(category: String)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
const CATEGORY_GLYPHS := {
	"heroes": "character", "enemies": "enemy", "pickups": "magnet",
	"skills": "level", "relics": "equipment",
}

var list: GridContainer
var tab_buttons: Dictionary = {}
var scroll: ScrollContainer
var progress_label: Label
var paper_sheet: Panel
var top_wash: Panel
var close_button: Button
var navigation_mode := false
var navigation_reserve := 142.0


func build(categories: Array) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_paper_sheet()
	_build_header()
	_build_tabs(categories)
	_build_collection_grid()
	resized.connect(_layout)
	_layout()


func set_navigation_mode(enabled: bool) -> void:
	navigation_mode = enabled
	if is_instance_valid(close_button):
		close_button.visible = not enabled
	_layout()


func set_navigation_reserve(reserve: float) -> void:
	navigation_reserve = maxf(120.0, reserve)
	_layout()


func clear_cards() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()


func add_card(card: Panel) -> void:
	list.add_child(card)


func set_progress(discovered: int, total: int) -> void:
	progress_label.text = "已收集 %d / %d" % [discovered, total]


func set_tab_label(category: String, title: String, discovered: int, total: int) -> void:
	if tab_buttons.has(category):
		tab_buttons[category].text = "%s %d/%d" % [title, discovered, total]
		tab_buttons[category].tooltip_text = "%s：已收集 %d / %d" % [title, discovered, total]
		tab_buttons[category].accessibility_name = tab_buttons[category].tooltip_text


func set_selected_tab(category: String) -> void:
	for category_id in tab_buttons:
		_apply_tab_style(tab_buttons[category_id], category_id == category)


func _build_paper_sheet() -> void:
	paper_sheet = Panel.new()
	paper_sheet.position = Vector2(10, 16)
	SunlitCardStyle.apply_panel(paper_sheet, UiFactory.SURFACE, UiFactory.PRIMARY, 14.0)
	add_child(paper_sheet)
	top_wash = Panel.new()
	top_wash.position = Vector2(20, 94)
	top_wash.size = Vector2(500, 86)
	var wash_style := StyleBoxFlat.new()
	wash_style.bg_color = Color(UiFactory.SURFACE_ALT, 0.82)
	wash_style.border_color = Color(UiFactory.PRIMARY, 0.48)
	wash_style.border_width_top = 1
	wash_style.border_width_bottom = 2
	top_wash.add_theme_stylebox_override("panel", wash_style)
	add_child(top_wash)


func _build_header() -> void:
	var kicker := _plain_label("远征收藏册", 15, UiFactory.PRIMARY_DARK)
	kicker.position = Vector2(30, 30)
	kicker.size = Vector2(250, 24)
	add_child(kicker)
	var title := _plain_label("远征图鉴", 34, UiFactory.INK)
	title.position = Vector2(28, 52)
	title.size = Vector2(300, 46)
	UiFactory.apply_inner_page_title(title)
	add_child(title)
	progress_label = _plain_label("", 14, UiFactory.MUTED_INK)
	progress_label.position = Vector2(252, 62)
	progress_label.size = Vector2(176, 28)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(progress_label)
	close_button = Button.new()
	close_button.position = Vector2(430, 38)
	close_button.size = Vector2(80, 52)
	close_button.text = "收起"
	close_button.add_theme_font_size_override("font_size", 14)
	SunlitCardStyle.apply_button(close_button, false, UiFactory.PRIMARY)
	close_button.pressed.connect(close_requested.emit)
	add_child(close_button)


func _build_tabs(categories: Array) -> void:
	var gap := 4.0
	var tab_width := (500.0 - gap * (categories.size() - 1)) / categories.size()
	for index in range(categories.size()):
		var category: Dictionary = categories[index]
		var tab := Button.new()
		tab.position = Vector2(20 + index * (tab_width + gap), 106)
		tab.size = Vector2(tab_width, 60)
		tab.text = category["name"]
		tab.add_theme_font_size_override("font_size", 14)
		tab.pressed.connect(category_requested.emit.bind(category["id"]))
		add_child(tab)
		tab_buttons[category["id"]] = tab
		var glyph := SunlitGlyph.new()
		glyph.name = "CategoryGlyph"
		glyph.position = Vector2(6, 4)
		glyph.size = Vector2(18, 18)
		glyph.glyph_id = CATEGORY_GLYPHS.get(category["id"], "compendium")
		tab.add_child(glyph)


func _build_collection_grid() -> void:
	scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 20.0
	scroll.offset_top = 180.0
	scroll.offset_right = -20.0
	scroll.offset_bottom = -36.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	list = GridContainer.new()
	list.columns = 3
	list.custom_minimum_size = Vector2(500, 0)
	list.add_theme_constant_override("h_separation", 6)
	list.add_theme_constant_override("v_separation", 6)
	scroll.add_child(list)


func _layout() -> void:
	if not is_instance_valid(paper_sheet) or not is_instance_valid(scroll):
		return
	var reserved_height := navigation_reserve if navigation_mode else 0.0
	var content_bottom := maxf(260.0, size.y - reserved_height)
	paper_sheet.size = Vector2(520, maxf(236.0, content_bottom - 24.0))
	scroll.offset_bottom = -(reserved_height + 36.0)


func _apply_tab_style(button: Button, selected: bool) -> void:
	var background := UiFactory.PRIMARY_DARK if selected else Color(UiFactory.SURFACE, 0.78)
	var border := UiFactory.PRIMARY_LIGHT if selected else Color(UiFactory.PRIMARY, 0.62)
	var normal := SunlitCardStyle.panel_style(background, border, 5.0, selected, false)
	normal.shadow_color = Color.TRANSPARENT
	normal.shadow_size = 0
	normal.border_width_bottom = 3 if selected else 1
	normal.corner_radius_top_left = 2
	normal.corner_radius_top_right = 9
	normal.corner_radius_bottom_left = 9
	normal.corner_radius_bottom_right = 2
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.04)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.06)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = UiFactory.ACCENT
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	var text_color := UiFactory.HUD_TEXT if selected else UiFactory.INK
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_constant_override("outline_size", 0)
	SunlitCardStyle.decorate(button, Color(border, 0.42), 5.0, true, selected, UiFactory.PRIMARY_LIGHT, "ribbon")
	var glyph := button.get_node_or_null("CategoryGlyph") as Control
	if glyph != null:
		glyph.call("set_selected", selected)


func _plain_label(text: String, font_size: int, color: Color) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	return label
