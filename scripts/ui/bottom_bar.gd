extends Panel

signal page_selected(page_id: String)
signal navigation_reserve_changed(reserve: float)

const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const PAGE_START := "start"
const PAGE_CHARACTER := "character"
const PAGE_COMPENDIUM := "compendium"
const BASE_TEXTURE := preload("res://assets/art/ui/navigation/bottom_bar_base.png")
const SELECTION_TEXTURE := preload("res://assets/art/ui/navigation/bottom_bar_selection.png")
const CONTENT_TEXTURES := {
	PAGE_START: preload("res://assets/art/ui/navigation/bottom_bar_content_start.png"),
	PAGE_CHARACTER: preload("res://assets/art/ui/navigation/bottom_bar_content_character.png"),
	PAGE_COMPENDIUM: preload("res://assets/art/ui/navigation/bottom_bar_content_compendium.png"),
}
const SELECTION_CENTERS := {
	PAGE_START: 118.0,
	PAGE_CHARACTER: 270.0,
	PAGE_COMPENDIUM: 408.0,
}
const PAGE_DEFINITIONS := [
	{
		"id": PAGE_START,
		"caption": "远征",
		"description": "选择关卡并踏入星门",
		"rect": Rect2(34, 0, 160, 120),
	},
	{
		"id": PAGE_CHARACTER,
		"caption": "角色",
		"description": "选择英雄并配置成长",
		"rect": Rect2(194, 0, 154, 120),
	},
	{
		"id": PAGE_COMPENDIUM,
		"caption": "图鉴",
		"description": "查看已经发现的星潮记录",
		"rect": Rect2(348, 0, 158, 120),
	},
]

var current_page := PAGE_START
var buttons: Dictionary = {}
var skin: TextureRect
var selection: TextureRect
var active_content: TextureRect


func _ready() -> void:
	custom_minimum_size = Vector2(540, 120)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = false
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_build_skin()
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
	selection.position.x = SELECTION_CENTERS[page_id] - selection.size.x * 0.5
	active_content.texture = CONTENT_TEXTURES[page_id]
	for id in buttons:
		var button: Button = buttons[id]
		var selected: bool = id == current_page
		button.set_meta("selected", selected)
		button.accessibility_description = (
			"当前页面，%s" % button.get_meta("page_description")
			if selected
			else "切换到%s页面，%s" % [button.text, button.get_meta("page_description")]
		)
	if emit_change and changed:
		page_selected.emit(page_id)


func base_texture_path() -> String:
	return skin.texture.resource_path if is_instance_valid(skin) and skin.texture != null else ""


func selection_texture_path() -> String:
	return selection.texture.resource_path if is_instance_valid(selection) and selection.texture != null else ""


func active_content_texture_path() -> String:
	return active_content.texture.resource_path if is_instance_valid(active_content) and active_content.texture != null else ""


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


func _build_skin() -> void:
	skin = TextureRect.new()
	skin.name = "StateSkin"
	skin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skin.stretch_mode = TextureRect.STRETCH_SCALE
	skin.texture = BASE_TEXTURE
	skin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(skin)
	selection = TextureRect.new()
	selection.name = "Selection"
	selection.position = Vector2.ZERO
	selection.size = Vector2(SELECTION_TEXTURE.get_width(), SELECTION_TEXTURE.get_height())
	selection.texture = SELECTION_TEXTURE
	selection.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selection.stretch_mode = TextureRect.STRETCH_SCALE
	selection.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	selection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(selection)
	active_content = TextureRect.new()
	active_content.name = "ActiveContent"
	active_content.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	active_content.stretch_mode = TextureRect.STRETCH_SCALE
	active_content.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	active_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(active_content)


func _build_buttons() -> void:
	for definition in PAGE_DEFINITIONS:
		var page_id := str(definition["id"])
		var button := Button.new()
		var rect: Rect2 = definition["rect"]
		button.name = page_id.capitalize() + "Tab"
		button.position = rect.position
		button.size = rect.size
		button.text = str(definition["caption"])
		button.tooltip_text = str(definition["description"])
		button.accessibility_name = button.text
		button.set_meta("page_description", str(definition["description"]))
		button.focus_mode = Control.FOCUS_ALL
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		for color_name in [
			"font_color",
			"font_hover_color",
			"font_pressed_color",
			"font_focus_color",
			"font_disabled_color",
		]:
			button.add_theme_color_override(color_name, Color.TRANSPARENT)
		button.pressed.connect(select_page.bind(page_id))
		add_child(button)
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
