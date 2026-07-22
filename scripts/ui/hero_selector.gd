extends Control

signal hero_selected(hero_id: String)

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const HERO_TEXTURES := {
	"star_warden": preload("res://assets/art/characters/star_tide_warden.png"),
	"ember_ranger": preload("res://assets/art/characters/emberwing_ranger.png"),
}

var records: RefCounted
var selected_hero_id := "star_warden"
var hero_panels: Dictionary = {}
var hero_record_labels: Dictionary = {}
var hero_growth_labels: Dictionary = {}


func configure(run_records: RefCounted, initial_hero_id: String) -> void:
	records = run_records
	selected_hero_id = initial_hero_id
	size = Vector2(504, 384)
	for index in range(HeroCatalog.ids().size()):
		var hero_id: String = HeroCatalog.ids()[index]
		var card := Panel.new()
		card.position = Vector2(index * 254, 0)
		card.size = Vector2(242, 384)
		add_child(card)
		hero_panels[hero_id] = card
		_build_card(card, hero_id)
	refresh()
	_update_selection()


func select_hero(hero_id: String, emit_change := true) -> void:
	if not hero_panels.has(hero_id):
		return
	selected_hero_id = hero_id
	_update_selection()
	if emit_change:
		hero_selected.emit(hero_id)


func refresh() -> void:
	for hero_id in hero_record_labels:
		hero_record_labels[hero_id].text = _record_summary(hero_id)
		hero_growth_labels[hero_id].text = _growth_summary(hero_id)


func _build_card(card: Panel, hero_id: String) -> void:
	var hero := HeroCatalog.hero(hero_id)
	var accent := Color("5dd9dc") if hero_id == "star_warden" else Color("ff8b6d")
	var name_label := UiFactory.label(hero["name"], 22, UiFactory.PALE)
	name_label.position = Vector2(10, 10)
	name_label.size = Vector2(222, 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)
	var portrait_plate := Panel.new()
	portrait_plate.position = Vector2(20, 40)
	portrait_plate.size = Vector2(202, 150)
	portrait_plate.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.015, 0.07, 0.11, 0.82), 18.0, Color(accent, 0.62)))
	card.add_child(portrait_plate)
	var portrait := TextureRect.new()
	portrait.position = Vector2(26, 42)
	portrait.size = Vector2(190, 146)
	portrait.texture = HERO_TEXTURES[hero_id]
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(portrait)
	var role := UiFactory.label(hero["title"], 17, accent)
	role.position = Vector2(10, 188)
	role.size = Vector2(222, 25)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(role)
	var description := UiFactory.label(hero["description"], 13, UiFactory.PALE_MUTED)
	description.position = Vector2(14, 216)
	description.size = Vector2(214, 40)
	description.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(description)
	var growth := UiFactory.label("", 13, UiFactory.CYAN)
	growth.position = Vector2(10, 262)
	growth.size = Vector2(222, 23)
	growth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(growth)
	hero_growth_labels[hero_id] = growth
	var record := UiFactory.label("", 12, UiFactory.PALE_MUTED)
	record.position = Vector2(10, 287)
	record.size = Vector2(222, 22)
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record.clip_text = true
	card.add_child(record)
	hero_record_labels[hero_id] = record
	var select_button := Button.new()
	select_button.position = Vector2(22, 322)
	select_button.size = Vector2(198, 48)
	select_button.text = "选择"
	select_button.add_theme_font_size_override("font_size", 18)
	select_button.pressed.connect(select_hero.bind(hero_id))
	card.add_child(select_button)


func _growth_summary(hero_id: String) -> String:
	if not records.has_method("progression_snapshot"):
		return "Lv.1 · 熟练度待提升"
	var snapshot: Dictionary = records.progression_snapshot(hero_id)
	return "Lv.%d · 熟练 %d/%d · 技能点 %d" % [
		int(snapshot.get("level", 1)),
		int(snapshot.get("level_progress", 0)),
		int(snapshot.get("level_progress_max", 100)),
		int(snapshot.get("available_skill_points", 0)),
	]


func _record_summary(hero_id: String) -> String:
	var record: Dictionary = records.hero_record(hero_id)
	if int(record.get("runs", 0)) <= 0:
		return "尚未出征"
	return "通关 %d · 最高击败 %d" % [int(record.get("wins", 0)), int(record.get("best_kills", 0))]


func _update_selection() -> void:
	for hero_id in hero_panels:
		var selected: bool = hero_id == selected_hero_id
		var background := UiFactory.GLASS if selected else Color(0.02, 0.1, 0.14, 0.78)
		var border := UiFactory.GOLD if selected else Color(0.23, 0.53, 0.55, 0.72)
		hero_panels[hero_id].add_theme_stylebox_override("panel", UiFactory.panel_style(background, 20.0, border))
		var button: Button = hero_panels[hero_id].get_child(hero_panels[hero_id].get_child_count() - 1)
		button.text = "已选择" if selected else "选择"
		UiFactory.apply_glass_button(button, selected, border)
