extends "res://scripts/ui/start_screen.gd"

const SafeArea = preload("res://scripts/ui/safe_area.gd")
const BottomBar = preload("res://scripts/ui/bottom_bar.gd")
const CharacterPage = preload("res://scripts/ui/character_page.gd")
const ExpeditionConfirmPanel = preload("res://scripts/ui/expedition_confirm_panel.gd")

var current_page := BottomBar.PAGE_START
var bottom_bar: Panel
var global_chrome: Control
var character_page: Control
var navigation_safe_area: Control
var expedition_confirm: Control


func configure(run_records: RefCounted, audio_manager: Node) -> void:
	super.configure(run_records, audio_manager)
	var active_hero := _record_active_hero()
	if not active_hero.is_empty():
		super.select_hero(active_hero)
	_build_character_page()
	_build_navigation()
	_build_expedition_confirm()
	compendium.set_navigation_mode(true)
	_show_page(BottomBar.PAGE_START)
	visibility_changed.connect(_on_visibility_changed)
	compendium.visibility_changed.connect(_on_compendium_visibility_changed)


func select_hero(hero_id: String) -> void:
	super.select_hero(hero_id)
	if is_instance_valid(character_page) and character_page.selected_hero_id != hero_id:
		character_page.select_hero(hero_id, false)


func refresh_progress() -> void:
	route_map.refresh()
	select_level(selected_level_id)
	if is_instance_valid(character_page):
		character_page.refresh()


func show_page(page_id: String) -> void:
	_show_page(page_id)


func open_compendium(category := "heroes") -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_confirm", -1.0)
	_show_page(BottomBar.PAGE_COMPENDIUM)
	compendium.show_category(category)


func _build_character_page() -> void:
	character_page = CharacterPage.new()
	character_page.z_index = 4
	design_frame.add_child(character_page)
	character_page.configure(records, selected_hero_id, audio)
	character_page.hero_selected.connect(_on_character_selected)
	character_page.profile_changed.connect(refresh_progress)


func _build_navigation() -> void:
	navigation_safe_area = SafeArea.new()
	navigation_safe_area.z_index = 100
	add_child(navigation_safe_area)
	global_chrome = DesignFrame.new()
	global_chrome.name = "GlobalChrome"
	global_chrome.z_index = 100
	add_child(global_chrome)
	audio_settings.reparent(global_chrome, false)
	audio_settings.position = Vector2(462, 18)
	audio_settings.z_index = 10
	bottom_bar = BottomBar.new()
	bottom_bar.position = Vector2(0, 840)
	bottom_bar.size = Vector2(540, 120)
	bottom_bar.z_index = 0
	bottom_bar.navigation_reserve_changed.connect(compendium.set_navigation_reserve)
	global_chrome.add_child(bottom_bar)
	bottom_bar.page_selected.connect(_on_bottom_bar_page_selected)


func _build_expedition_confirm() -> void:
	expedition_confirm = ExpeditionConfirmPanel.new()
	expedition_confirm.z_index = 140
	design_frame.add_child(expedition_confirm)
	expedition_confirm.configure(records)
	expedition_confirm.confirmed.connect(_confirm_start)
	expedition_confirm.adjust_character_requested.connect(_open_character_from_confirmation)
	expedition_confirm.closed.connect(_close_expedition_confirm)


func _show_page(page_id: String) -> void:
	if page_id not in [BottomBar.PAGE_START, BottomBar.PAGE_CHARACTER, BottomBar.PAGE_COMPENDIUM]:
		return
	current_page = page_id
	_close_expedition_confirm()
	var showing_start := page_id == BottomBar.PAGE_START
	var showing_character := page_id == BottomBar.PAGE_CHARACTER
	var showing_compendium := page_id == BottomBar.PAGE_COMPENDIUM
	audio_settings.visible = true
	lobby_view.visible = showing_start
	if is_instance_valid(character_page):
		character_page.visible = showing_character
		character_page.set_active(showing_character and visible)
	if is_instance_valid(route_map):
		route_map.set_active(showing_start and visible)
	if showing_compendium:
		compendium.open(compendium.current_category)
	elif compendium.visible:
		compendium.close()
	if is_instance_valid(bottom_bar):
		bottom_bar.select_page(page_id, false)
	if is_instance_valid(audio_settings):
		audio_settings.close_popup()


func _on_bottom_bar_page_selected(page_id: String) -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_navigate", -1.0)
	_show_page(page_id)


func _show_lobby() -> void:
	if not is_instance_valid(character_page):
		super._show_lobby()
		return
	_show_page(BottomBar.PAGE_START)


func _show_hero_selection() -> void:
	if not records.is_level_unlocked(selected_level_id):
		return
	audio_settings.close_popup()
	var active_hero := _record_active_hero()
	if not active_hero.is_empty():
		super.select_hero(active_hero)
	expedition_confirm.show_for(selected_hero_id, LevelCatalog.by_id(selected_level_id))
	route_map.set_active(false)
	bottom_bar.visible = false


func _request_start() -> void:
	var active_hero := _record_active_hero()
	if not active_hero.is_empty():
		super.select_hero(active_hero)
	super._request_start()


func _confirm_start() -> void:
	_close_expedition_confirm()
	_request_start()


func _open_character_from_confirmation() -> void:
	_close_expedition_confirm()
	_show_page(BottomBar.PAGE_CHARACTER)


func _close_expedition_confirm() -> void:
	if is_instance_valid(expedition_confirm):
		expedition_confirm.visible = false
	if is_instance_valid(bottom_bar):
		bottom_bar.visible = visible
	if is_instance_valid(route_map):
		route_map.set_active(visible and current_page == BottomBar.PAGE_START and lobby_view.visible)


func _on_character_selected(hero_id: String) -> void:
	super.select_hero(hero_id)
	route_map.refresh()
	if is_instance_valid(audio):
		audio.play_sfx("ui_select", -2.0)


func _on_visibility_changed() -> void:
	if is_instance_valid(character_page):
		character_page.set_active(visible and current_page == BottomBar.PAGE_CHARACTER)
	if is_instance_valid(route_map):
		route_map.set_active(visible and current_page == BottomBar.PAGE_START)
	if is_instance_valid(navigation_safe_area):
		navigation_safe_area.visible = visible and not expedition_confirm.visible
	if is_instance_valid(bottom_bar):
		bottom_bar.visible = visible and not expedition_confirm.visible


func _on_compendium_visibility_changed() -> void:
	if is_instance_valid(navigation_safe_area):
		navigation_safe_area.visible = visible and not expedition_confirm.visible
	if is_instance_valid(bottom_bar):
		bottom_bar.visible = visible and not expedition_confirm.visible
	if not compendium.visible and current_page == BottomBar.PAGE_COMPENDIUM:
		_show_page(BottomBar.PAGE_START)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	if is_instance_valid(expedition_confirm) and expedition_confirm.visible:
		_close_expedition_confirm()
	elif current_page == BottomBar.PAGE_COMPENDIUM:
		if not compendium.close_detail_if_open():
			_show_page(BottomBar.PAGE_START)
	elif current_page == BottomBar.PAGE_CHARACTER:
		_show_page(BottomBar.PAGE_START)
	else:
		return
	get_viewport().set_input_as_handled()


func _record_active_hero() -> String:
	return str(records.get_active_hero_id()) if records.has_method("get_active_hero_id") else str(records.last_hero_id)
