extends Panel

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
const CompactProgressBar = preload("res://scripts/ui/compact_progress_bar.gd")
const BATTLE_STATUS_FRAME := preload("res://assets/art/ui/battle/battle_status_frame.png")
const HEALTH_BAR_TOP := 18.0

signal pause_requested

var health_bar: Control
var xp_bar: Control
var health_label: Label
var level_label: Label
var stats_label: Label
var kills_label: Label
var health_notch: ColorRect
var pause_button: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_build_frame()
	_build_labels()
	_build_bars()
	_build_pause_button()


func refresh(player_level: int, health: float, max_health: float, experience: float, experience_needed: float, time_text: String, kills: int, low_health: bool) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.configure_colors(UiFactory.DANGER if low_health else UiFactory.SUPPORTING, Color(0.35, 0.5, 0.52, 0.24), 6.0)
	health_label.text = "生命 %d / %d" % [ceili(health), ceili(max_health)]
	health_label.modulate = UiFactory.DANGER_DARK if low_health else Color.WHITE
	xp_bar.max_value = experience_needed
	xp_bar.value = experience
	level_label.text = "LV.%d" % player_level
	stats_label.text = time_text
	kills_label.text = "击败 %d" % kills


func show_health_notch(health_ratio: float) -> void:
	health_notch.position.x = 104.0 + clampf(health_ratio, 0.0, 1.0) * 316.0 - health_notch.size.x * 0.5
	health_notch.visible = true


func _build_frame() -> void:
	var status_frame := TextureRect.new()
	status_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status_frame.texture = BATTLE_STATUS_FRAME
	status_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	status_frame.stretch_mode = TextureRect.STRETCH_SCALE
	status_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_frame)


func _build_labels() -> void:
	level_label = UiFactory.surface_label("LV.1", 23, UiFactory.HUD_TEXT)
	level_label.position = Vector2(16, 0)
	level_label.size = Vector2(82, 62)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.clip_text = true
	add_child(level_label)


func _build_bars() -> void:
	health_bar = _make_bar(Vector2(104, HEALTH_BAR_TOP), Vector2(316, 19), UiFactory.SUPPORTING, 6.0)
	add_child(health_bar)
	health_notch = ColorRect.new()
	health_notch.color = UiFactory.DANGER
	health_notch.position = Vector2(104, HEALTH_BAR_TOP - 2.0)
	health_notch.size = Vector2(5, 23)
	health_notch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_notch.visible = false
	add_child(health_notch)
	xp_bar = _make_bar(Vector2(104, 62), Vector2(316, 6), UiFactory.PRIMARY, 3.0)
	add_child(xp_bar)
	stats_label = UiFactory.surface_label("00:00", 16, UiFactory.INK)
	stats_label.position = Vector2(108, HEALTH_BAR_TOP + 14)
	stats_label.size = Vector2(140, 22)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.clip_text = true
	add_child(stats_label)
	kills_label = UiFactory.surface_label("击败 0", 16, UiFactory.INK)
	kills_label.position = Vector2(244, HEALTH_BAR_TOP + 14)
	kills_label.size = Vector2(164, 22)
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kills_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kills_label.clip_text = true
	add_child(kills_label)
	health_label = UiFactory.surface_label("生命 100 / 100", 14, UiFactory.INK)
	health_label.position = Vector2(104, HEALTH_BAR_TOP - 2.0)
	health_label.size = Vector2(316, 19)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.clip_text = true
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(health_label)


func _build_pause_button() -> void:
	pause_button = Button.new()
	pause_button.position = Vector2(439, 9)
	pause_button.size = Vector2(54, 54)
	pause_button.accessibility_name = "暂停"
	var pause_style := StyleBoxFlat.new()
	pause_style.bg_color = Color.TRANSPARENT
	pause_style.corner_radius_top_left = 27
	pause_style.corner_radius_top_right = 27
	pause_style.corner_radius_bottom_left = 27
	pause_style.corner_radius_bottom_right = 27
	for state in ["normal", "hover", "pressed", "focus"]:
		pause_button.add_theme_stylebox_override(state, pause_style)
	pause_button.pressed.connect(pause_requested.emit)
	add_child(pause_button)
	var pause_glyph := SunlitGlyph.new()
	pause_glyph.glyph_id = "pause"
	pause_glyph.set_selected(true)
	pause_glyph.position = Vector2(7, 10)
	pause_glyph.size = Vector2(26, 26)
	pause_button.add_child(pause_glyph)


func _make_bar(at: Vector2, bar_size: Vector2, color: Color, radius: float) -> Control:
	var bar := CompactProgressBar.new()
	bar.position = at
	bar.size = bar_size
	bar.configure_colors(color, Color(0.35, 0.5, 0.52, 0.24), radius)
	return bar
