extends CanvasLayer

signal start_requested(hero_id: String, level_id: String)

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const AudioSettingsPanel = preload("res://scripts/ui/audio_settings_panel.gd")
const LevelSelector = preload("res://scripts/ui/level_selector.gd")
const CompendiumOverlay = preload("res://scripts/ui/compendium_overlay.gd")
const FLOOR_TEXTURE := preload("res://assets/art/environment/celestial_floor.png")
const HERO_TEXTURES := {
	"star_warden": preload("res://assets/art/characters/star_tide_warden.png"),
	"ember_ranger": preload("res://assets/art/characters/emberwing_ranger.png"),
}

var records: RefCounted
var audio: Node
var selected_hero_id := "star_warden"
var selected_level_id := "level_01"
var hero_panels: Dictionary = {}
var hero_record_labels: Dictionary = {}
var start_button: Button
var level_selector: Control
var compendium: ColorRect
var audio_settings: Control
var screen_background: ColorRect
var design_frame: Control


func configure(run_records: RefCounted, audio_manager: Node) -> void:
	records = run_records
	audio = audio_manager
	selected_hero_id = records.last_hero_id
	selected_level_id = records.last_level_id
	layer = 20
	design_frame = _build_background()
	_build_header(design_frame)
	_build_level_selector(design_frame)
	_build_hero_cards(design_frame)
	_build_actions(design_frame)
	compendium = CompendiumOverlay.new()
	add_child(compendium)
	select_hero(selected_hero_id)


func select_hero(hero_id: String) -> void:
	selected_hero_id = hero_id
	if is_instance_valid(audio):
		audio.play_sfx("ui_select", -2.0)
	for card_hero_id in hero_panels:
		var selected: bool = card_hero_id == hero_id
		var border := Color("f2ca72") if selected else Color(0.34, 0.5, 0.68, 0.6)
		var background := Color(0.045, 0.075, 0.15, 0.97) if selected else Color(0.025, 0.045, 0.1, 0.9)
		hero_panels[card_hero_id].add_theme_stylebox_override("panel", UiFactory.panel_style(background, 20.0, border))
	start_button.text = "以%s进入%s" % [HeroCatalog.hero(hero_id)["name"], LevelCatalog.by_id(selected_level_id).display_name]


func select_level(level_id: String) -> void:
	selected_level_id = level_id
	start_button.text = "以%s进入%s" % [HeroCatalog.hero(selected_hero_id)["name"], LevelCatalog.by_id(level_id).display_name]


func refresh_progress() -> void:
	for hero_id in hero_record_labels:
		hero_record_labels[hero_id].text = records.summary(hero_id)
	level_selector.refresh()


func open_compendium(category := "heroes") -> void:
	audio.play_sfx("ui_confirm", -1.0)
	compendium.open(category)


func _build_background() -> Control:
	screen_background = ColorRect.new()
	screen_background.color = Color("071126")
	add_child(screen_background)
	ScreenLayout.fill(screen_background)
	var floor_art := TextureRect.new()
	floor_art.texture = FLOOR_TEXTURE
	floor_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	floor_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	floor_art.modulate = Color(0.62, 0.72, 1.0, 0.42)
	floor_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_background.add_child(floor_art)
	ScreenLayout.fill(floor_art)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.08, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_background.add_child(shade)
	ScreenLayout.fill(shade)
	var content := DesignFrame.new()
	add_child(content)
	return content


func _build_header(background: Control) -> void:
	audio_settings = AudioSettingsPanel.new()
	audio_settings.position = Vector2(136, 8)
	background.add_child(audio_settings)
	audio_settings.configure(audio)
	var title := UiFactory.label("星潮守望者", 42, Color("f6d782"))
	title.position = Vector2(20, 80)
	title.size = Vector2(500, 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	background.add_child(title)
	var subtitle := UiFactory.label("选择英雄与远征关卡", 18, Color("d3e5f3"))
	subtitle.position = Vector2(20, 132)
	subtitle.size = Vector2(500, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	background.add_child(subtitle)


func _build_level_selector(background: Control) -> void:
	level_selector = LevelSelector.new()
	level_selector.position = Vector2(18, 172)
	background.add_child(level_selector)
	level_selector.configure(LevelCatalog.all(), records, selected_level_id)
	selected_level_id = level_selector.selected_level_id
	level_selector.level_selected.connect(select_level)


func _build_hero_cards(background: Control) -> void:
	var hero_ids := HeroCatalog.ids()
	for index in range(hero_ids.size()):
		var hero_id: String = hero_ids[index]
		var card := Panel.new()
		card.position = Vector2(18 + index * 254, 296)
		card.size = Vector2(232, 350)
		background.add_child(card)
		hero_panels[hero_id] = card
		_build_hero_card(card, hero_id)


func _build_hero_card(card: Panel, hero_id: String) -> void:
	var hero := HeroCatalog.hero(hero_id)
	var name_label := UiFactory.label(hero["name"], 23, Color("fff0b0"))
	name_label.position = Vector2(10, 10)
	name_label.size = Vector2(212, 32)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)
	var portrait := TextureRect.new()
	portrait.position = Vector2(21, 42)
	portrait.size = Vector2(190, 155)
	portrait.texture = HERO_TEXTURES[hero_id]
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(portrait)
	var role := UiFactory.label(hero["title"], 17, Color("70e8ff") if hero_id == "star_warden" else Color("ff9a62"))
	role.position = Vector2(10, 198)
	role.size = Vector2(212, 25)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(role)
	var description := UiFactory.label("%s\n%s" % [hero["passive_name"], hero["passive_description"]], 12, Color("d3ddea"))
	description.position = Vector2(14, 222)
	description.size = Vector2(204, 48)
	description.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	description.clip_text = true
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(description)
	var record := UiFactory.label(records.summary(hero_id), 12, Color("9db8d2"))
	record.position = Vector2(12, 269)
	record.size = Vector2(208, 22)
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(record)
	hero_record_labels[hero_id] = record
	var select_button := Button.new()
	select_button.position = Vector2(22, 296)
	select_button.size = Vector2(188, 44)
	select_button.text = "选择"
	select_button.add_theme_font_size_override("font_size", 18)
	select_button.add_theme_stylebox_override("normal", UiFactory.button_style(Color("17304e"), Color("527fa8")))
	select_button.pressed.connect(select_hero.bind(hero_id))
	card.add_child(select_button)


func _build_actions(background: Control) -> void:
	start_button = Button.new()
	start_button.position = Vector2(72, 674)
	start_button.size = Vector2(396, 68)
	start_button.add_theme_font_size_override("font_size", 23)
	start_button.add_theme_stylebox_override("normal", UiFactory.button_style(Color("173c63"), Color("f2ca72")))
	start_button.pressed.connect(_request_start)
	background.add_child(start_button)
	var compendium_button := Button.new()
	compendium_button.position = Vector2(126, 766)
	compendium_button.size = Vector2(288, 58)
	compendium_button.text = "★  星潮图鉴"
	compendium_button.add_theme_font_size_override("font_size", 21)
	compendium_button.add_theme_stylebox_override("normal", UiFactory.button_style(Color(0.045, 0.07, 0.14, 0.96), Color("6285ad")))
	compendium_button.pressed.connect(open_compendium)
	background.add_child(compendium_button)
	var hint := UiFactory.label("左下摇杆移动 · 技能自动释放 · 通关解锁下一关", 15, Color("aebfd2"))
	hint.position = Vector2(20, 850)
	hint.size = Vector2(500, 34)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	background.add_child(hint)


func _request_start() -> void:
	start_requested.emit(selected_hero_id, selected_level_id)
