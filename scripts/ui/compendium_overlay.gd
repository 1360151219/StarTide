extends ColorRect

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const SafeArea = preload("res://scripts/ui/safe_area.gd")
const CompendiumCatalog = preload("res://scripts/compendium_catalog.gd")
const CATEGORIES := [
	{"id": "heroes", "name": "英雄"},
	{"id": "enemies", "name": "怪物"},
	{"id": "pickups", "name": "道具"},
	{"id": "skills", "name": "技能"},
	{"id": "relics", "name": "遗物"},
]

var list: VBoxContainer
var tab_buttons: Dictionary = {}
var safe_area: Control
var content: Control
var scroll: ScrollContainer
var records: RefCounted


func _ready() -> void:
	ScreenLayout.fill(self)
	color = Color(0.008, 0.045, 0.075, 0.96)
	z_index = 80
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


func configure(run_records: RefCounted) -> void:
	records = run_records
	_refresh_tab_labels()


func open(category := "heroes") -> void:
	visible = true
	show_category(category)


func close() -> void:
	visible = false


func show_category(category: String) -> void:
	_refresh_tab_labels()
	for category_id in tab_buttons:
		var selected: bool = category_id == category
		var button: Button = tab_buttons[category_id]
		UiFactory.apply_glass_button(button, selected, UiFactory.GOLD if selected else UiFactory.STROKE)
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	for entry in CompendiumCatalog.entries(category):
		var discovered: bool = category == "heroes" or records == null or records.is_content_discovered(category, entry["id"])
		list.add_child(_make_card(entry, discovered))


func _build_header() -> void:
	var title := UiFactory.label("星潮图鉴", 38, UiFactory.PALE)
	title.position = Vector2(28, 34)
	title.size = Vector2(360, 54)
	content.add_child(title)
	var close_button := Button.new()
	close_button.position = Vector2(440, 28)
	close_button.size = Vector2(72, 60)
	close_button.text = "×"
	close_button.add_theme_font_size_override("font_size", 30)
	UiFactory.apply_glass_button(close_button, false, UiFactory.GOLD)
	close_button.pressed.connect(close)
	content.add_child(close_button)


func _build_tabs() -> void:
	var gap := 7.0
	var tab_width := (504.0 - gap * (CATEGORIES.size() - 1)) / CATEGORIES.size()
	for index in range(CATEGORIES.size()):
		var category: Dictionary = CATEGORIES[index]
		var tab := Button.new()
		tab.position = Vector2(20 + index * (tab_width + gap), 112)
		tab.size = Vector2(tab_width, 54)
		tab.text = category["name"]
		tab.add_theme_font_size_override("font_size", 16)
		tab.pressed.connect(show_category.bind(category["id"]))
		content.add_child(tab)
		tab_buttons[category["id"]] = tab


func _refresh_tab_labels() -> void:
	for category in CATEGORIES:
		var category_id: String = category["id"]
		if not tab_buttons.has(category_id):
			continue
		var entries := CompendiumCatalog.entries(category_id)
		var total := entries.size()
		var discovered := 0
		for entry in entries:
			discovered += int(category_id == "heroes" or records == null or records.is_content_discovered(category_id, entry["id"]))
		tab_buttons[category_id].text = "%s %d/%d" % [category["name"], discovered, total]


func _make_card(entry: Dictionary, discovered: bool) -> Panel:
	var card := Panel.new()
	var height: float = entry.get("card_height", 178.0)
	card.custom_minimum_size = Vector2(478, height)
	card.set_meta("content_id", entry["id"])
	card.set_meta("discovered", discovered)
	var accent: Color = entry["accent"] if discovered else Color("60737a")
	card.add_theme_stylebox_override("panel", UiFactory.panel_style(UiFactory.GLASS, 18.0, accent))
	var icon := TextureRect.new()
	icon.position = Vector2(16, 18)
	icon.size = Vector2(132, 140)
	icon.texture = entry["texture"]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if discovered else Color(0.08, 0.13, 0.15, 0.78)
	card.add_child(icon)
	var name_label := UiFactory.label(entry["name"] if discovered else "？？？", 24, UiFactory.PALE)
	name_label.position = Vector2(164, 17)
	name_label.size = Vector2(292, 34)
	card.add_child(name_label)
	var subtitle := UiFactory.label(entry["subtitle"] if discovered else "尚未发现", 15, accent)
	subtitle.position = Vector2(164, 52)
	subtitle.size = Vector2(292, 28)
	card.add_child(subtitle)
	var description_text := _entry_description(entry, discovered)
	var description := UiFactory.label(description_text, 14 if height > 200.0 else 15, UiFactory.PALE_MUTED)
	description.position = Vector2(164, 84)
	description.size = Vector2(292, height - 96.0)
	description.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	description.clip_text = true
	card.add_child(description)
	return card


func _entry_description(entry: Dictionary, discovered: bool) -> String:
	if not discovered:
		return "在远征中首次发现后，\n即可解锁完整图鉴资料。"
	var text := str(entry["description"])
	for branch in entry.get("branches", []):
		if records == null or records.is_content_discovered("skill_branches", branch["id"]):
			text += "\n分支 · %s：%s" % [branch["name"], branch["description"]]
		else:
			text += "\n分支 · ？？？：在局内选择后解锁"
	return text
