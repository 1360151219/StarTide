extends Panel

signal page_selected(page_id: String)
signal navigation_reserve_changed(reserve: float)

const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
const PAGE_START := "start"
const PAGE_CHARACTER := "character"
const PAGE_COMPENDIUM := "compendium"
const PAGE_DEFINITIONS := [
	{
		"id": PAGE_START,
		"caption": "远征",
		"description": "选择关卡并开始远征",
		"glyph": "expedition",
	},
	{
		"id": PAGE_CHARACTER,
		"caption": "角色",
		"description": "选择英雄并配置成长",
		"glyph": "character",
	},
	{
		"id": PAGE_COMPENDIUM,
		"caption": "图鉴",
		"description": "查看旅途中发现的记录",
		"glyph": "compendium",
	},
]

var current_page := PAGE_START
var buttons: Dictionary = {}
var tab_plates: Dictionary = {}
var glyphs: Dictionary = {}
var captions: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(540, 120)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = false
	SunlitCardStyle.apply_panel(self, Color(UiFactory.HUD_SURFACE, 0.98), Color("8d7248"), 8.0, false, true, "ribbon")
	_build_buttons()
	_link_focus()
	select_page(current_page, false)
	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_queue_viewport_layout)
		_queue_viewport_layout()


func select_page(page_id: String, emit_change := true) -> void:
	if not buttons.has(page_id):
		return
	var changed := page_id != current_page
	current_page = page_id
	for id in buttons:
		var button: Button = buttons[id]
		var selected: bool = id == current_page
		button.set_meta("selected", selected)
		button.accessibility_description = (
			"当前页面，%s" % button.get_meta("page_description")
			if selected
			else "切换到%s页面，%s" % [button.text, button.get_meta("page_description")]
		)
		SunlitCardStyle.apply_panel(
			tab_plates[id],
			UiFactory.SURFACE if selected else Color(UiFactory.PRIMARY_DARK, 0.96),
			UiFactory.ACCENT if selected else Color(UiFactory.ACCENT_LIGHT, 0.52),
			6.0,
			selected,
			true,
			"ribbon"
		)
		glyphs[id].set_selected(selected)
		captions[id].add_theme_color_override("font_color", UiFactory.INK if selected else UiFactory.HUD_TEXT)
	if emit_change and changed:
		page_selected.emit(page_id)


func base_texture_path() -> String:
	return ""


func selection_texture_path() -> String:
	return ""


func active_content_texture_path() -> String:
	return ""


func layout_in_safe_rect(safe_rect: Rect2) -> void:
	var design_position := ScreenLayout.design_position(safe_rect)
	var available_bottom := safe_rect.end.y - design_position.y
	position = Vector2(0, minf(840.0, available_bottom - size.y))
	navigation_reserve_changed.emit(available_bottom - position.y)


func _queue_viewport_layout() -> void:
	call_deferred("_layout_for_viewport")


func _layout_for_viewport() -> void:
	var viewport := get_viewport()
	if viewport != null:
		layout_in_safe_rect(ScreenLayout.current_safe_rect(viewport))


func _build_buttons() -> void:
	var tab_width := 102.0
	var gap := 12.0
	var start_x := 20.0
	for index in range(PAGE_DEFINITIONS.size()):
		var definition: Dictionary = PAGE_DEFINITIONS[index]
		var page_id := str(definition["id"])
		var plate := Panel.new()
		plate.position = Vector2(start_x + index * (tab_width + gap), 8)
		plate.size = Vector2(tab_width, 104)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(plate)
		tab_plates[page_id] = plate
		var glyph := SunlitGlyph.new()
		glyph.glyph_id = str(definition["glyph"])
		glyph.position = Vector2(35, 13)
		glyph.size = Vector2(32, 32)
		plate.add_child(glyph)
		glyphs[page_id] = glyph
		var button := Button.new()
		button.name = page_id.capitalize() + "Tab"
		button.position = plate.position
		button.size = plate.size
		button.text = str(definition["caption"])
		button.tooltip_text = str(definition["description"])
		button.accessibility_name = button.text
		button.set_meta("page_description", str(definition["description"]))
		button.focus_mode = Control.FOCUS_ALL
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_size_override("font_size", 1)
		button.add_theme_constant_override("outline_size", 0)
		button.add_theme_constant_override("icon_max_width", 0)
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, Color.TRANSPARENT)
		button.pressed.connect(select_page.bind(page_id))
		add_child(button)
		var caption := UiFactory.surface_label(str(definition["caption"]), 15, UiFactory.MUTED_INK)
		caption.position = Vector2(0, 56)
		caption.size = Vector2(tab_width, 34)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption)
		captions[page_id] = caption
		buttons[page_id] = button


func _link_focus() -> void:
	for index in range(PAGE_DEFINITIONS.size()):
		var button: Button = buttons[PAGE_DEFINITIONS[index]["id"]]
		var previous_index := (index - 1 + PAGE_DEFINITIONS.size()) % PAGE_DEFINITIONS.size()
		var next_index := (index + 1) % PAGE_DEFINITIONS.size()
		var previous: Button = buttons[PAGE_DEFINITIONS[previous_index]["id"]]
		var next: Button = buttons[PAGE_DEFINITIONS[next_index]["id"]]
		button.focus_neighbor_left = button.get_path_to(previous)
		button.focus_previous = button.get_path_to(previous)
		button.focus_neighbor_right = button.get_path_to(next)
		button.focus_next = button.get_path_to(next)
