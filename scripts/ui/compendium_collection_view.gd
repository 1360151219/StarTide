extends Control

signal close_requested
signal category_requested(category: String)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const PAGE_FRAME = preload("res://assets/art/ui/compendium/page_frame.png")
const CATEGORY_RAIL = preload("res://assets/art/ui/compendium/category_rail.png")
const CATEGORY_SELECTED = preload("res://assets/art/ui/compendium/category_selected.png")
const CATEGORY_ICONS := {
	"heroes": preload("res://assets/art/ui/compendium/category_heroes.png"),
	"enemies": preload("res://assets/art/ui/compendium/category_enemies.png"),
	"pickups": preload("res://assets/art/ui/compendium/category_pickups.png"),
	"skills": preload("res://assets/art/ui/compendium/category_skills.png"),
	"relics": preload("res://assets/art/ui/compendium/category_relics.png"),
}

var list: GridContainer
var tab_buttons: Dictionary = {}
var scroll: ScrollContainer
var progress_label: Label
var paper_sheet: TextureRect
var close_button: Button
var selected_plate: TextureRect
var navigation_mode := false
var navigation_reserve := 142.0
var selection_tween: Tween


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
	if not tab_buttons.has(category):
		return
	var button: Button = tab_buttons[category]
	button.set_meta("title", title)
	button.get_node("TabContent/Title").text = title
	button.tooltip_text = "%s：已收集 %d / %d" % [title, discovered, total]
	button.accessibility_name = button.tooltip_text
	button.set_meta("discovered", discovered)
	button.set_meta("total", total)


func set_selected_tab(category: String) -> void:
	var selected_index := 0
	var index := 0
	for category_id in tab_buttons:
		var selected: bool = category_id == category
		_apply_tab_colors(tab_buttons[category_id], selected)
		if selected:
			selected_index = index
		index += 1
	_move_selected_plate(selected_index)


func _build_paper_sheet() -> void:
	paper_sheet = TextureRect.new()
	paper_sheet.name = "CompendiumPageFrame"
	paper_sheet.position = Vector2(8, 6)
	paper_sheet.texture = PAGE_FRAME
	paper_sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper_sheet.stretch_mode = TextureRect.STRETCH_SCALE
	paper_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper_sheet)


func _build_header() -> void:
	var kicker := _plain_label("远征收藏册", 15, UiFactory.PRIMARY_DARK)
	kicker.position = Vector2(52, 34)
	kicker.size = Vector2(220, 24)
	add_child(kicker)
	var title := _plain_label("远征图鉴", 34, UiFactory.INK)
	title.position = Vector2(50, 58)
	title.size = Vector2(300, 48)
	UiFactory.apply_inner_page_title(title)
	add_child(title)
	progress_label = _plain_label("", 15, UiFactory.MUTED_INK)
	progress_label.position = Vector2(292, 68)
	progress_label.size = Vector2(188, 28)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(progress_label)
	close_button = Button.new()
	close_button.position = Vector2(442, 32)
	close_button.size = Vector2(64, 52)
	close_button.text = "收起"
	close_button.add_theme_font_size_override("font_size", 14)
	SunlitCardStyle.apply_button(close_button, false, UiFactory.PRIMARY)
	close_button.pressed.connect(close_requested.emit)
	add_child(close_button)


func _build_tabs(categories: Array) -> void:
	var rail := TextureRect.new()
	rail.name = "CategoryRail"
	rail.position = Vector2(14, 130)
	rail.size = Vector2(512, 74)
	rail.texture = CATEGORY_RAIL
	rail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rail.stretch_mode = TextureRect.STRETCH_SCALE
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rail)
	selected_plate = TextureRect.new()
	selected_plate.name = "CategorySelected"
	selected_plate.position = Vector2(14, 126)
	selected_plate.size = Vector2(102.4, 84)
	var selected_texture := AtlasTexture.new()
	selected_texture.atlas = CATEGORY_SELECTED
	selected_texture.region = Rect2(28, 0, 152, 168)
	selected_plate.texture = selected_texture
	selected_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selected_plate.stretch_mode = TextureRect.STRETCH_SCALE
	selected_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(selected_plate)
	for index in range(categories.size()):
		var category: Dictionary = categories[index]
		var tab := Button.new()
		tab.position = Vector2(14 + index * 102.4, 130)
		tab.size = Vector2(102.4, 72)
		tab.set_meta("title", category["name"])
		tab.flat = true
		tab.pressed.connect(category_requested.emit.bind(category["id"]))
		add_child(tab)
		_add_tab_content(tab, category["name"], CATEGORY_ICONS[category["id"]])
		tab_buttons[category["id"]] = tab


func _add_tab_content(button: Button, title: String, texture: Texture2D) -> void:
	var content := HBoxContainer.new()
	content.name = "TabContent"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(28, 28)
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var label := _plain_label(title, 15, Color("fff2c4"))
	label.name = "Title"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(label)


func _build_collection_grid() -> void:
	scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 39.0
	scroll.offset_top = 224.0
	scroll.offset_right = -39.0
	scroll.offset_bottom = -28.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	list = GridContainer.new()
	list.columns = 3
	list.custom_minimum_size = Vector2(462, 0)
	list.add_theme_constant_override("h_separation", 0)
	list.add_theme_constant_override("v_separation", 0)
	scroll.add_child(list)


func _layout() -> void:
	if not is_instance_valid(paper_sheet) or not is_instance_valid(scroll):
		return
	var reserved_height := navigation_reserve if navigation_mode else 0.0
	var content_bottom := maxf(260.0, size.y - reserved_height)
	paper_sheet.size = Vector2(524, maxf(246.0, content_bottom - 10.0))
	scroll.offset_bottom = -(reserved_height + 28.0)


func _move_selected_plate(index: int) -> void:
	var target_x := 14.0 + index * 102.4
	if selection_tween != null and selection_tween.is_valid():
		selection_tween.kill()
	if not is_inside_tree() or not visible:
		selected_plate.position.x = target_x
		return
	selection_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	selection_tween.tween_property(selected_plate, "position:x", target_x, 0.12)


func _apply_tab_colors(button: Button, selected: bool) -> void:
	var color := UiFactory.HUD_TEXT if selected else Color("fff2c4")
	button.get_node("TabContent/Icon").modulate = color
	button.get_node("TabContent/Title").add_theme_color_override("font_color", color)


func _plain_label(text: String, font_size: int, color: Color) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	return label
