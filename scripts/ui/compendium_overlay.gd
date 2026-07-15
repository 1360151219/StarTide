extends ColorRect

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const SafeArea = preload("res://scripts/ui/safe_area.gd")
const CompendiumCatalog = preload("res://scripts/compendium_catalog.gd")

var list: VBoxContainer
var tab_buttons: Dictionary = {}
var safe_area: Control
var content: Control
var scroll: ScrollContainer


func _ready() -> void:
	ScreenLayout.fill(self)
	color = Color(0.008, 0.018, 0.055, 0.985)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	safe_area = SafeArea.new()
	add_child(safe_area)
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.anchor_left = 0.5
	content.anchor_right = 0.5
	content.anchor_bottom = 1.0
	content.offset_left = -270.0
	content.offset_right = 270.0
	safe_area.add_child(content)
	_build_header()
	_build_tabs()
	scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 20.0
	scroll.offset_top = 184.0
	scroll.offset_right = -20.0
	scroll.offset_bottom = -32.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	list = VBoxContainer.new()
	list.custom_minimum_size = Vector2(478, 0)
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)


func open(category := "heroes") -> void:
	visible = true
	show_category(category)


func close() -> void:
	visible = false


func show_category(category: String) -> void:
	for category_id in tab_buttons:
		var selected: bool = category_id == category
		var button: Button = tab_buttons[category_id]
		button.add_theme_stylebox_override("normal", UiFactory.button_style(Color("173c63") if selected else Color("101d36"), Color("f2ca72") if selected else Color("526d8c")))
	for child in list.get_children():
		child.queue_free()
	for entry in CompendiumCatalog.entries(category):
		list.add_child(_make_card(entry))


func _build_header() -> void:
	var title := UiFactory.label("星潮图鉴", 38, Color("f6d782"))
	title.position = Vector2(28, 34)
	title.size = Vector2(360, 54)
	content.add_child(title)
	var close_button := Button.new()
	close_button.position = Vector2(440, 28)
	close_button.size = Vector2(72, 60)
	close_button.text = "×"
	close_button.add_theme_font_size_override("font_size", 30)
	close_button.add_theme_stylebox_override("normal", UiFactory.button_style(Color("172944"), Color("6683a3")))
	close_button.pressed.connect(close)
	content.add_child(close_button)


func _build_tabs() -> void:
	var categories := [{"id": "heroes", "name": "英雄"}, {"id": "enemies", "name": "怪物"}, {"id": "pickups", "name": "道具"}, {"id": "skills", "name": "技能"}]
	for index in range(categories.size()):
		var category: Dictionary = categories[index]
		var tab := Button.new()
		tab.position = Vector2(20 + index * 126, 112)
		tab.size = Vector2(116, 54)
		tab.text = category["name"]
		tab.add_theme_font_size_override("font_size", 19)
		tab.pressed.connect(show_category.bind(category["id"]))
		content.add_child(tab)
		tab_buttons[category["id"]] = tab


func _make_card(entry: Dictionary) -> Panel:
	var card := Panel.new()
	var height: float = entry.get("card_height", 178.0)
	card.custom_minimum_size = Vector2(478, height)
	card.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.035, 0.06, 0.125, 0.98), 18.0, entry["accent"]))
	var icon := TextureRect.new()
	icon.position = Vector2(16, 18)
	icon.size = Vector2(132, 140)
	icon.texture = entry["texture"]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(icon)
	var name_label := UiFactory.label(entry["name"], 24, Color("fff0b0"))
	name_label.position = Vector2(164, 17)
	name_label.size = Vector2(292, 34)
	card.add_child(name_label)
	var subtitle := UiFactory.label(entry["subtitle"], 15, entry["accent"])
	subtitle.position = Vector2(164, 52)
	subtitle.size = Vector2(292, 28)
	card.add_child(subtitle)
	var description := UiFactory.label(entry["description"], 14 if height > 200.0 else 15, Color("d5e0ee"))
	description.position = Vector2(164, 84)
	description.size = Vector2(292, height - 96.0)
	description.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	description.clip_text = true
	card.add_child(description)
	return card
