extends CanvasLayer

signal start_requested(hero_id: String, level_id: String)

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const AudioSettingsPanel = preload("res://scripts/ui/audio_settings_panel.gd")
const ExpeditionRouteMap = preload("res://scripts/ui/expedition_route_map.gd")
const HomePrimaryButton = preload("res://scripts/ui/home_primary_button.gd")
const CompendiumOverlay = preload("res://scripts/ui/compendium_overlay.gd")
const HOME_BACKGROUND := preload("res://assets/art/sunlit/backgrounds/expedition_route_map.png")

var records: RefCounted
var audio: Node
var selected_hero_id := "star_warden"
var selected_level_id := "level_01"
var start_button: HomePrimaryButton
var route_map: Control
var compendium: ColorRect
var audio_settings: Control
var screen_background: TextureRect
var design_frame: Control
var lobby_view: Control


func configure(run_records: RefCounted, audio_manager: Node) -> void:
	records = run_records
	audio = audio_manager
	selected_hero_id = records.last_hero_id
	selected_level_id = records.last_level_id
	layer = 20
	design_frame = _build_background()
	_build_header(design_frame)
	_build_lobby(design_frame)
	compendium = CompendiumOverlay.new()
	add_child(compendium)
	compendium.configure(records)
	_show_lobby()
	select_level(selected_level_id)
	select_hero(selected_hero_id)


func select_hero(hero_id: String) -> void:
	selected_hero_id = hero_id
	if is_instance_valid(route_map):
		route_map.set_preview_hero(hero_id)


func select_level(level_id: String) -> void:
	var level := LevelCatalog.by_id(level_id)
	if level == null:
		return
	selected_level_id = level_id
	if is_instance_valid(route_map) and route_map.selected_level_id != level_id:
		route_map.select_level(level_id, false)
	var unlocked: bool = records.is_level_unlocked(level_id)
	route_map.show_level(level, unlocked)
	start_button.set_caption("开始远征" if unlocked else "完成上一关后解锁", unlocked)


func refresh_progress() -> void:
	route_map.refresh()
	select_level(selected_level_id)


func open_compendium(category := "heroes") -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_confirm", -1.0)
	compendium.open(category)


func _build_background() -> Control:
	screen_background = TextureRect.new()
	screen_background.texture = HOME_BACKGROUND
	screen_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	screen_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_background)
	ScreenLayout.fill(screen_background)
	var veil := ColorRect.new()
	veil.color = Color(UiFactory.BACKGROUND, 0.32)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_background.add_child(veil)
	ScreenLayout.fill(veil)
	var content := DesignFrame.new()
	add_child(content)
	return content


func _build_header(parent: Control) -> void:
	audio_settings = AudioSettingsPanel.new()
	audio_settings.position = Vector2(462, 18)
	parent.add_child(audio_settings)
	audio_settings.configure(audio, true)


func _build_lobby(parent: Control) -> void:
	lobby_view = Control.new()
	parent.add_child(lobby_view)
	ScreenLayout.fill(lobby_view)
	route_map = ExpeditionRouteMap.new()
	lobby_view.add_child(route_map)
	route_map.configure(LevelCatalog.all(), records, selected_level_id)
	selected_level_id = route_map.selected_level_id
	route_map.level_selected.connect(_on_level_selected)
	start_button = HomePrimaryButton.new()
	start_button.position = Vector2(374, 704)
	start_button.size = Vector2(154, 154)
	start_button.z_index = 120
	lobby_view.add_child(start_button)
	start_button.set_caption("开始远征", true)
	start_button.pressed.connect(_show_hero_selection)


func _on_level_selected(level_id: String) -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_select", -2.0)
	select_level(level_id)


func _show_lobby() -> void:
	lobby_view.visible = true
	route_map.set_active(true)


func _show_hero_selection() -> void:
	if not records.is_level_unlocked(selected_level_id):
		return
	audio_settings.close_popup()
	_request_start()


func _request_start() -> void:
	if records.is_level_unlocked(selected_level_id):
		start_requested.emit(selected_hero_id, selected_level_id)
