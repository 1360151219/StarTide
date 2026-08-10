extends ColorRect

const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const SafeArea = preload("res://scripts/ui/safe_area.gd")
const CompendiumCatalog = preload("res://scripts/compendium_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const CompendiumCard = preload("res://scripts/ui/compendium_card.gd")
const CollectionView = preload("res://scripts/ui/compendium_collection_view.gd")
const DetailView = preload("res://scripts/ui/compendium_detail_view.gd")
const CATEGORIES := [
	{"id": "heroes", "name": "英雄"},
	{"id": "enemies", "name": "怪物"},
	{"id": "pickups", "name": "道具"},
	{"id": "skills", "name": "技能"},
	{"id": "relics", "name": "遗物"},
]

var list: GridContainer
var tab_buttons: Dictionary = {}
var safe_area: Control
var content: Control
var scroll: ScrollContainer
var records: RefCounted
var progress_label: Label
var detail_layer: Control
var detail_icon: TextureRect
var detail_title: Label
var detail_subtitle: Label
var detail_description: RichTextLabel
var detail_hint: Label
var current_category := "heroes"
var pressed_card: Panel
var pressed_position := Vector2.ZERO
var collection_view: Control
var detail_view: Control
var navigation_mode := false


func _ready() -> void:
	ScreenLayout.fill(self)
	color = Color(0.02, 0.08, 0.1, 0.28)
	z_index = 80
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	safe_area = SafeArea.new()
	add_child(safe_area)
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.size = ScreenLayout.DESIGN_SIZE
	safe_area.add_child(content)
	safe_area.resized.connect(_layout_content)
	_layout_content()
	_build_collection_view()
	_build_detail_view()


func configure(run_records: RefCounted) -> void:
	records = run_records
	_refresh_tab_labels()


func open(category := "heroes") -> void:
	visible = true
	show_category(category)


func close() -> void:
	_close_detail()
	visible = false


func set_navigation_mode(enabled: bool) -> void:
	navigation_mode = enabled
	mouse_filter = Control.MOUSE_FILTER_IGNORE if enabled else Control.MOUSE_FILTER_STOP
	if is_instance_valid(collection_view):
		collection_view.set_navigation_mode(enabled)
	if is_instance_valid(detail_view):
		detail_view.set_navigation_mode(enabled)


func set_navigation_reserve(reserve: float) -> void:
	var design_reserve := minf(reserve, 120.0) if navigation_mode else reserve
	if is_instance_valid(collection_view):
		collection_view.set_navigation_reserve(design_reserve)
	if is_instance_valid(detail_view):
		detail_view.set_navigation_reserve(design_reserve)


func _layout_content() -> void:
	if not is_instance_valid(content):
		return
	var local_safe_rect := Rect2(Vector2.ZERO, safe_area.size)
	content.position = ScreenLayout.design_position(local_safe_rect)
	content.size = Vector2(ScreenLayout.DESIGN_SIZE.x, minf(ScreenLayout.DESIGN_SIZE.y, safe_area.size.y))


func close_detail_if_open() -> bool:
	if not is_instance_valid(detail_view) or not detail_view.visible:
		return false
	_close_detail()
	return true


func show_category(category: String) -> void:
	current_category = category
	_close_detail()
	_refresh_tab_labels()
	collection_view.set_selected_tab(category)
	collection_view.clear_cards()
	var entries := CompendiumCatalog.entries(category)
	var discovered_count := 0
	for entry in entries:
		var discovered := _is_discovered(category, entry)
		discovered_count += int(discovered)
		collection_view.add_card(_make_card(category, entry, discovered))
	collection_view.set_progress(discovered_count, entries.size())
	scroll.scroll_vertical = 0


func _build_collection_view() -> void:
	collection_view = CollectionView.new()
	collection_view.build(CATEGORIES)
	collection_view.close_requested.connect(close)
	collection_view.category_requested.connect(show_category)
	content.add_child(collection_view)
	collection_view.set_navigation_mode(navigation_mode)
	list = collection_view.list
	tab_buttons = collection_view.tab_buttons
	scroll = collection_view.scroll
	progress_label = collection_view.progress_label


func _build_detail_view() -> void:
	detail_view = DetailView.new()
	detail_view.build()
	detail_view.close_requested.connect(_close_detail)
	content.add_child(detail_view)
	detail_view.set_navigation_mode(navigation_mode)
	detail_layer = detail_view
	detail_icon = detail_view.detail_icon
	detail_title = detail_view.detail_title
	detail_subtitle = detail_view.detail_subtitle
	detail_description = detail_view.detail_description
	detail_hint = detail_view.detail_hint


func _refresh_tab_labels() -> void:
	for category in CATEGORIES:
		var category_id: String = category["id"]
		if not tab_buttons.has(category_id):
			continue
		var entries := CompendiumCatalog.entries(category_id)
		var total := entries.size()
		var discovered := 0
		for entry in entries:
			discovered += int(_is_discovered(category_id, entry))
		collection_view.set_tab_label(category_id, category["name"], discovered, total)


func _make_card(category: String, entry: Dictionary, discovered: bool) -> Panel:
	var card := CompendiumCard.new()
	card.configure(
		category,
		entry,
		discovered,
		_card_subtitle(category, entry, discovered),
		_entry_description(entry, discovered)
	)
	card.activated.connect(_open_detail)
	return card


func _open_detail(category: String, entry: Dictionary, discovered: bool) -> void:
	var accent: Color = entry["accent"] if discovered else Color("82948b")
	var hint := "已收入星潮图鉴" if discovered else _unlock_hint(category, str(entry["id"]))
	detail_view.present(entry, discovered, accent, _entry_description(entry, discovered), hint)


func _close_detail() -> void:
	if is_instance_valid(detail_layer):
		detail_view.hide_detail()
	pressed_card = null


func _entry_description(entry: Dictionary, discovered: bool) -> String:
	if not discovered:
		return "先在对应远征中找到它，完整名称、效果与故事就会记录在这里。\n\n%s" % _unlock_hint(current_category, str(entry["id"]))
	var text := str(entry["description"])
	for branch in entry.get("branches", []):
		if records == null or records.is_content_discovered("skill_branches", branch["id"]):
			text += "\n\n分支 · %s\n%s" % [branch["name"], branch["description"]]
		else:
			text += "\n\n分支 · ？？？\n在局内选择后解锁"
	return text


func _card_subtitle(category: String, entry: Dictionary, discovered: bool) -> String:
	if discovered:
		return str(entry["subtitle"])
	return _unlock_hint(category, str(entry["id"]))


func _unlock_hint(category: String, content_id: String) -> String:
	var level_id := LevelCatalog.debut_level_id(category, content_id)
	var level := LevelCatalog.by_id(level_id)
	if level != null:
		return "线索：前往%s" % level.display_name
	match category:
		"heroes":
			return "线索：英雄会随旅程加入"
		"skills":
			return "线索：升级时选择它"
		"relics":
			return "线索：远征中获得遗物"
		"pickups":
			return "线索：留意战场掉落"
		_:
			return "线索：继续完成远征"


func _is_discovered(category: String, entry: Dictionary) -> bool:
	return category == "heroes" or records == null or records.is_content_discovered(category, entry["id"])
