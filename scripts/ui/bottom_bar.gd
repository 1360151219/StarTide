extends Panel

signal page_selected(page_id: String)
signal navigation_reserve_changed(reserve: float)

const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const NORMAL_FLAG := preload("res://assets/art/ui/home/nav_flag_normal.png")
const SELECTED_FLAG := preload("res://assets/art/ui/home/nav_flag_selected.png")
const CHARACTER_ICON := preload("res://assets/art/ui/home/nav_icon_character.png")
const EXPEDITION_ICON := preload("res://assets/art/ui/home/nav_icon_expedition.png")
const COMPENDIUM_ICON := preload("res://assets/art/ui/home/nav_icon_compendium.png")
const PAGE_START := "start"
const PAGE_CHARACTER := "character"
const PAGE_COMPENDIUM := "compendium"
const TAB_SIZE := Vector2(102, 104)
const TAB_START_X := 18.0
const TAB_GAP := 8.0
const TAB_Y := 8.0
const SELECTED_TAB_Y := 2.0
const PAGE_DEFINITIONS := [
	{
		"id": PAGE_CHARACTER,
		"caption": "角色",
		"description": "选择英雄并配置成长",
		"icon": CHARACTER_ICON,
	},
	{
		"id": PAGE_START,
		"caption": "远征",
		"description": "选择关卡并开始远征",
		"icon": EXPEDITION_ICON,
	},
	{
		"id": PAGE_COMPENDIUM,
		"caption": "图鉴",
		"description": "查看旅途中发现的记录",
		"icon": COMPENDIUM_ICON,
	},
]

var current_page := PAGE_START
var buttons: Dictionary = {}
var tab_plates: Dictionary = {}
var glyphs: Dictionary = {}
var captions: Dictionary = {}
var hovered_tabs: Dictionary = {}
var motion_tweens: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(540, 120)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = false
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
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
		var plate: TextureRect = tab_plates[id]
		var selected: bool = id == current_page
		button.set_meta("selected", selected)
		button.accessibility_description = (
			"当前页面，%s" % button.get_meta("page_description")
			if selected
			else "切换到%s页面，%s" % [button.text, button.get_meta("page_description")]
		)
		plate.texture = SELECTED_FLAG if selected else NORMAL_FLAG
		plate.position.y = SELECTED_TAB_Y if selected else TAB_Y
		glyphs[id].modulate = _icon_modulate(id, selected)
		_refresh_tab_modulate(id)
	if emit_change and changed:
		page_selected.emit(page_id)


func base_texture_path() -> String:
	return NORMAL_FLAG.resource_path


func selection_texture_path() -> String:
	return SELECTED_FLAG.resource_path


func active_content_texture_path() -> String:
	if not glyphs.has(current_page):
		return ""
	var icon: TextureRect = glyphs[current_page]
	return icon.texture.resource_path


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
	for index in range(PAGE_DEFINITIONS.size()):
		var definition: Dictionary = PAGE_DEFINITIONS[index]
		var page_id := str(definition["id"])
		var tab_position := Vector2(TAB_START_X + index * (TAB_SIZE.x + TAB_GAP), TAB_Y)
		var plate := TextureRect.new()
		plate.name = page_id.capitalize() + "Flag"
		plate.position = tab_position
		plate.size = TAB_SIZE
		plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plate.stretch_mode = TextureRect.STRETCH_SCALE
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(plate)
		tab_plates[page_id] = plate
		var glyph := TextureRect.new()
		glyph.name = page_id.capitalize() + "Icon"
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.texture = definition["icon"]
		glyph.position = Vector2(27, 29)
		glyph.size = Vector2(48, 48)
		glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(glyph)
		glyphs[page_id] = glyph
		var button := Button.new()
		button.name = page_id.capitalize() + "Tab"
		button.position = tab_position
		button.size = TAB_SIZE
		button.text = str(definition["caption"])
		button.tooltip_text = str(definition["description"])
		button.accessibility_name = button.text
		button.set_meta("page_description", str(definition["description"]))
		button.focus_mode = Control.FOCUS_ALL
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 1)
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, Color.TRANSPARENT)
		button.pressed.connect(select_page.bind(page_id))
		button.button_down.connect(_set_tab_pressed.bind(page_id, true))
		button.button_up.connect(_set_tab_pressed.bind(page_id, false))
		button.mouse_entered.connect(_set_tab_hovered.bind(page_id, true))
		button.mouse_exited.connect(_set_tab_hovered.bind(page_id, false))
		button.focus_entered.connect(_set_tab_hovered.bind(page_id, true))
		button.focus_exited.connect(_set_tab_hovered.bind(page_id, false))
		add_child(button)
		var caption := UiFactory.surface_label(button.text, 14, UiFactory.INK)
		caption.visible = false
		button.add_child(caption)
		captions[page_id] = caption
		buttons[page_id] = button


func _set_tab_pressed(page_id: String, pressed: bool) -> void:
	if not tab_plates.has(page_id):
		return
	if motion_tweens.has(page_id):
		var previous: Tween = motion_tweens[page_id]
		if previous.is_valid():
			previous.kill()
	var selected := page_id == current_page
	var rest_y := SELECTED_TAB_Y if selected else TAB_Y
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(tab_plates[page_id], "position:y", rest_y + (2.0 if pressed else 0.0), 0.08 if pressed else 0.12)
	motion_tweens[page_id] = tween


func _set_tab_hovered(page_id: String, hovered: bool) -> void:
	hovered_tabs[page_id] = hovered
	_refresh_tab_modulate(page_id)


func _refresh_tab_modulate(page_id: String) -> void:
	if not tab_plates.has(page_id):
		return
	var highlighted := page_id == current_page or bool(hovered_tabs.get(page_id, false))
	tab_plates[page_id].self_modulate = Color.WHITE if highlighted else Color(0.88, 0.94, 0.94, 1.0)


func _icon_modulate(page_id: String, selected: bool) -> Color:
	if not selected or page_id == PAGE_START:
		return Color.WHITE
	return Color(0.34, 0.62, 0.64, 1.0)


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
