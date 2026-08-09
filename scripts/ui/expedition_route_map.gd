extends Control

signal level_selected(level_id: String)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
const RoutePin = preload("res://scripts/ui/expedition_route_pin.gd")
const ExpeditionBrief = preload("res://scripts/ui/expedition_brief.gd")
const SwipeGesture = preload("res://scripts/ui/swipe_gesture.gd")
const HeroRigScene = preload("res://scenes/presentation/hero_rig_2d.tscn")
const MAP_TEXTURE := preload("res://assets/art/sunlit/backgrounds/expedition_route_map.png")
const PIN_CENTERS := [Vector2(270, 614), Vector2(428, 414), Vector2(298, 176)]
const HERO_POSITIONS := [Vector2(155, 628), Vector2(338, 494), Vector2(225, 318)]
const PIN_COLORS := [UiFactory.ACCENT, UiFactory.PRIMARY, UiFactory.DANGER]

var records: RefCounted
var levels: Array[LevelConfig] = []
var selected_level_id := ""
var current_index := 0
var route_pins: Array[Button] = []
var scene_texture: TextureRect
var map_frame: Control
var preview_hero: HeroRig2D
var title_label: Label
var detail_label: Label
var page_label: Label
var expedition_brief: Control
var animation_player: AnimationPlayer
var requested_active := true
var swipe_gesture := SwipeGesture.new()
var _built := false
var phase := 0.0:
	set(value):
		phase = value
		if is_instance_valid(preview_hero):
			var base: Vector2 = HERO_POSITIONS[current_index]
			preview_hero.position = base + Vector2(sin(phase * TAU) * 3.0, sin(phase * TAU * 2.0) * 1.5)
		for pin in route_pins:
			pin.set_phase(phase)


func _ready() -> void:
	_ensure_built()


func configure(level_configs: Array[LevelConfig], run_records: RefCounted, initial_level_id: String) -> void:
	_ensure_built()
	levels = level_configs
	records = run_records
	_build_pins()
	var requested := _index_of(initial_level_id)
	current_index = requested if requested >= 0 and records.is_level_unlocked(initial_level_id) else 0
	selected_level_id = levels[current_index].level_id if not levels.is_empty() else ""
	refresh()


func select_level(level_id: String, emit_change := true) -> void:
	var target_index := _index_of(level_id)
	if target_index < 0:
		return
	current_index = target_index
	selected_level_id = level_id
	_refresh_selection(true)
	if emit_change:
		level_selected.emit(level_id)


func move_by(direction: int) -> void:
	if levels.is_empty() or direction == 0:
		return
	var target := clampi(current_index + signi(direction), 0, levels.size() - 1)
	if target != current_index:
		select_level(levels[target].level_id)


func show_level(level: LevelConfig, unlocked: bool) -> void:
	title_label.text = level.display_name
	page_label.text = "%d / %d" % [current_index + 1, levels.size()]
	var active_snapshot: Dictionary = records.get_permanent_snapshot(records.get_active_hero_id())
	var power := int(active_snapshot.get("power", {}).get("total", 0))
	expedition_brief.configure(level, power, unlocked, records.has_cleared_level(level.level_id))
	detail_label = expedition_brief.current_power_label
	_refresh_selection(false)


func refresh() -> void:
	for index in range(route_pins.size()):
		var level := levels[index]
		route_pins[index].configure(level.level_id, level.map.biome_id, PIN_COLORS[index], not records.is_level_unlocked(level.level_id))
	_refresh_selection(false)


func set_preview_hero(hero_id: String) -> void:
	_ensure_built()
	preview_hero.configure(hero_id, 150.0)
	preview_hero.play_state("menu_idle", true)


func set_active(value: bool) -> void:
	requested_active = value
	if value:
		animation_player.play("route_loop")
		preview_hero.set_active(true)
	else:
		animation_player.pause()
		preview_hero.set_active(false)


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	size = Vector2(540, 960)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_background()
	_build_compass()
	_build_information()
	_build_hero()
	_build_animation()
	gui_input.connect(_handle_pointer_input)


func _build_background() -> void:
	scene_texture = TextureRect.new()
	scene_texture.texture = MAP_TEXTURE
	scene_texture.size = size
	scene_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene_texture)
	map_frame = Control.new()
	map_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_frame)


func _build_compass() -> void:
	var plate := Panel.new()
	plate.position = Vector2(16, 18)
	plate.size = Vector2(72, 72)
	SunlitCardStyle.apply_panel(plate, UiFactory.HUD_SURFACE, UiFactory.ACCENT, 36.0, true, true, "enamel", 2)
	add_child(plate)
	var glyph := SunlitGlyph.new()
	glyph.glyph_id = "expedition"
	glyph.set_selected(true)
	glyph.position = Vector2(18, 18)
	glyph.size = Vector2(36, 36)
	plate.add_child(glyph)


func _build_information() -> void:
	var title_plate := Panel.new()
	title_plate.position = Vector2(32, 674)
	title_plate.size = Vector2(282, 48)
	SunlitCardStyle.apply_panel(title_plate, Color(UiFactory.SURFACE, 0.98), UiFactory.ACCENT, 8.0, true, true, "map_tag")
	add_child(title_plate)
	title_label = UiFactory.surface_label("风铃草原", 22, UiFactory.INK)
	title_label.position = Vector2(18, 7)
	title_label.size = Vector2(190, 34)
	title_plate.add_child(title_label)
	page_label = UiFactory.surface_label("1 / 3", 14, UiFactory.PRIMARY_DARK)
	page_label.position = Vector2(210, 9)
	page_label.size = Vector2(54, 30)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_plate.add_child(page_label)
	expedition_brief = ExpeditionBrief.new()
	expedition_brief._ensure_built()
	expedition_brief.position = Vector2(18, 720)
	expedition_brief.scale = Vector2.ONE * 0.84
	expedition_brief.z_index = 8
	add_child(expedition_brief)
	detail_label = expedition_brief.current_power_label


func _build_hero() -> void:
	preview_hero = HeroRigScene.instantiate()
	preview_hero.position = HERO_POSITIONS[0]
	preview_hero.z_index = 6
	add_child(preview_hero)
	preview_hero.configure("star_warden", 150.0)
	preview_hero.play_state("menu_idle", true)


func _build_pins() -> void:
	for pin in route_pins:
		pin.queue_free()
	route_pins.clear()
	for index in range(levels.size()):
		var level := levels[index]
		var pin := RoutePin.new()
		pin.position = PIN_CENTERS[index] - Vector2(44, 54)
		pin.z_index = 7
		pin.tooltip_text = "%s · %s" % [level.display_name, level.subtitle]
		pin.pressed.connect(select_level.bind(level.level_id))
		add_child(pin)
		route_pins.append(pin)


func _build_animation() -> void:
	animation_player = AnimationPlayer.new()
	add_child(animation_player)
	var animation := Animation.new()
	animation.length = 3.2
	animation.loop_mode = Animation.LOOP_LINEAR
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(".:phase"))
	animation.track_insert_key(track, 0.0, 0.0)
	animation.track_insert_key(track, animation.length, 1.0)
	var library := AnimationLibrary.new()
	library.add_animation("route_loop", animation)
	animation_player.add_animation_library("", library)
	animation_player.play("route_loop")


func _refresh_selection(_animate: bool) -> void:
	for index in range(route_pins.size()):
		route_pins[index].set_selected(index == current_index)
	if not is_instance_valid(preview_hero) or current_index >= HERO_POSITIONS.size():
		return
	preview_hero.position = HERO_POSITIONS[current_index]


func _handle_pointer_input(event: InputEvent) -> void:
	var direction := swipe_gesture.handle(event)
	if direction != 0:
		move_by(direction)
		accept_event()


func _index_of(level_id: String) -> int:
	for index in range(levels.size()):
		if levels[index].level_id == level_id:
			return index
	return -1
