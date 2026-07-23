extends CanvasLayer

signal start_requested(hero_id: String, level_id: String)

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const LevelPresentationCatalog = preload("res://scripts/levels/level_presentation_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const AudioSettingsPanel = preload("res://scripts/ui/audio_settings_panel.gd")
const LevelSelector = preload("res://scripts/ui/level_selector.gd")
const LevelPreview = preload("res://scripts/ui/level_preview.gd")
const HomePrimaryButton = preload("res://scripts/ui/home_primary_button.gd")
const HeroSelector = preload("res://scripts/ui/hero_selector.gd")
const HeroTrainingPanel = preload("res://scripts/ui/hero_training_panel.gd")
const CompendiumOverlay = preload("res://scripts/ui/compendium_overlay.gd")
const HOME_BACKGROUND := preload("res://assets/art/ui/home/star_harbor_background.png")

var records: RefCounted
var audio: Node
var selected_hero_id := "star_warden"
var selected_level_id := "level_01"
var hero_panels: Dictionary = {}
var hero_record_labels: Dictionary = {}
var start_button: HomePrimaryButton
var confirm_button: Button
var level_selector: Control
var level_preview: Control
var hero_selector: Control
var training_panel: Panel
var compendium: ColorRect
var audio_settings: Control
var screen_background: TextureRect
var design_frame: Control
var lobby_view: Control
var hero_view: Control
var subtitle_label: Label
var selected_level_label: Label


func configure(run_records: RefCounted, audio_manager: Node) -> void:
	records = run_records
	audio = audio_manager
	selected_hero_id = records.last_hero_id
	selected_level_id = records.last_level_id
	layer = 20
	design_frame = _build_background()
	_build_header(design_frame)
	_build_lobby(design_frame)
	_build_hero_view(design_frame)
	compendium = CompendiumOverlay.new()
	add_child(compendium)
	compendium.configure(records)
	_show_lobby()
	select_level(selected_level_id)
	select_hero(selected_hero_id)


func select_hero(hero_id: String) -> void:
	selected_hero_id = hero_id
	if is_instance_valid(hero_selector):
		hero_selector.select_hero(hero_id, false)
	confirm_button.text = "使用%s出发" % HeroCatalog.hero(hero_id)["name"]


func select_level(level_id: String) -> void:
	var level := LevelCatalog.by_id(level_id)
	if level == null:
		return
	selected_level_id = level_id
	if is_instance_valid(level_selector) and level_selector.selected_level_id != level_id:
		level_selector.select_level(level_id, false)
	var unlocked: bool = records.is_level_unlocked(level_id)
	level_preview.show_level(level, LevelPresentationCatalog.by_id(level_id), records.level_summary(level_id), unlocked)
	selected_level_label.text = "%s  ·  %s" % [level.display_name, level.subtitle]
	start_button.set_caption("踏入星门" if unlocked else "完成上一关后解锁", unlocked)


func refresh_progress() -> void:
	hero_selector.refresh()
	level_selector.refresh()
	select_level(selected_level_id)
	if training_panel.visible:
		training_panel.refresh()


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
	veil.color = Color(0.015, 0.09, 0.14, 0.13)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_background.add_child(veil)
	ScreenLayout.fill(veil)
	var content := DesignFrame.new()
	add_child(content)
	return content


func _build_header(parent: Control) -> void:
	audio_settings = AudioSettingsPanel.new()
	audio_settings.position = Vector2(386, 18)
	parent.add_child(audio_settings)
	audio_settings.configure(audio, true)
	var title := UiFactory.label("星潮守望者", 43, Color("fff1b8"))
	title.position = Vector2(20, 58)
	title.size = Vector2(500, 54)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(title)
	subtitle_label = UiFactory.label("远征大厅  ·  选择今天要守护的世界", 16, Color("d8f7ef"))
	subtitle_label.position = Vector2(20, 110)
	subtitle_label.size = Vector2(500, 30)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(subtitle_label)


func _build_lobby(parent: Control) -> void:
	lobby_view = Control.new()
	parent.add_child(lobby_view)
	ScreenLayout.fill(lobby_view)
	level_preview = LevelPreview.new()
	level_preview.position = Vector2(18, 136)
	level_preview.size = Vector2(504, 390)
	lobby_view.add_child(level_preview)
	level_selector = LevelSelector.new()
	level_selector.position = Vector2(18, 520)
	lobby_view.add_child(level_selector)
	level_selector.configure(LevelCatalog.all(), records, selected_level_id)
	selected_level_id = level_selector.selected_level_id
	level_selector.level_selected.connect(_on_level_selected)
	level_preview.swipe_requested.connect(level_selector.move_by)
	start_button = HomePrimaryButton.new()
	start_button.position = Vector2(58, 718)
	start_button.size = Vector2(424, 82)
	lobby_view.add_child(start_button)
	start_button.set_caption("踏入星门", true)
	start_button.pressed.connect(_show_hero_selection)
	var compendium_button := _make_button(lobby_view, "✦  星潮图鉴", Vector2(126, 820), Vector2(288, 52), false)
	compendium_button.pressed.connect(open_compendium)
	var hint := UiFactory.label("选择远征地后，再挑选一位守望者", 14, Color("deeee5"))
	hint.position = Vector2(20, 888)
	hint.size = Vector2(500, 32)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby_view.add_child(hint)


func _build_hero_view(parent: Control) -> void:
	hero_view = Control.new()
	parent.add_child(hero_view)
	ScreenLayout.fill(hero_view)
	selected_level_label = UiFactory.label("", 16, UiFactory.PALE_MUTED)
	selected_level_label.position = Vector2(20, 170)
	selected_level_label.size = Vector2(500, 34)
	selected_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_view.add_child(selected_level_label)
	hero_selector = HeroSelector.new()
	hero_selector.position = Vector2(18, 218)
	hero_view.add_child(hero_selector)
	hero_selector.configure(records, selected_hero_id)
	hero_selector.hero_selected.connect(_on_hero_selected)
	hero_panels = hero_selector.hero_panels
	hero_record_labels = hero_selector.hero_record_labels
	var train_button := _make_button(hero_view, "培养英雄技能", Vector2(126, 620), Vector2(288, 54), false)
	train_button.pressed.connect(_open_training)
	confirm_button = _make_button(hero_view, "出发", Vector2(72, 692), Vector2(396, 68), true)
	confirm_button.pressed.connect(_request_start)
	var back_button := _make_button(hero_view, "返回选择关卡", Vector2(150, 784), Vector2(240, 52), false)
	back_button.pressed.connect(_show_lobby)
	training_panel = HeroTrainingPanel.new()
	training_panel.position = Vector2(18, 166)
	hero_view.add_child(training_panel)
	training_panel.configure(records)
	training_panel.closed.connect(_close_training)
	training_panel.progression_changed.connect(_on_progression_changed)


func _make_button(parent: Control, text: String, at: Vector2, button_size: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.position = at
	button.size = button_size
	button.text = text
	button.add_theme_font_size_override("font_size", 22 if primary else 18)
	UiFactory.apply_glass_button(button, primary, UiFactory.GOLD if primary else UiFactory.STROKE)
	parent.add_child(button)
	return button


func _on_level_selected(level_id: String) -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_select", -2.0)
	select_level(level_id)


func _on_hero_selected(hero_id: String) -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_select", -2.0)
	select_hero(hero_id)


func _show_lobby() -> void:
	lobby_view.visible = true
	hero_view.visible = false
	training_panel.visible = false
	level_preview.set_active(true)
	subtitle_label.text = "远征大厅  ·  选择今天要守护的世界"


func _show_hero_selection() -> void:
	if not records.is_level_unlocked(selected_level_id):
		return
	audio_settings.close_popup()
	lobby_view.visible = false
	hero_view.visible = true
	level_preview.set_active(false)
	subtitle_label.text = "选择出征英雄"
	hero_selector.refresh()


func _open_training() -> void:
	training_panel.show_for(selected_hero_id)


func _close_training() -> void:
	hero_selector.refresh()


func _on_progression_changed() -> void:
	hero_selector.refresh()


func _request_start() -> void:
	if records.is_level_unlocked(selected_level_id):
		start_requested.emit(selected_hero_id, selected_level_id)
