extends CanvasLayer

signal pause_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const SafeArea = preload("res://scripts/ui/safe_area.gd")
const SkillDock = preload("res://scripts/ui/skill_dock.gd")
const StageHud = preload("res://scripts/ui/stage_hud.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
const VirtualJoystickScript = preload("res://scripts/virtual_joystick.gd")
const CompactProgressBar = preload("res://scripts/ui/compact_progress_bar.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const HudPickupFeedback = preload("res://scripts/ui/hud_pickup_feedback.gd")

var health_bar: Control
var xp_bar: Control
var health_label: Label
var level_label: Label
var stats_label: Label
var skill_dock: Panel
var stage_hud: Control
var joystick: Control
var tutorial_panel: Panel
var tutorial_label: Label
var damage_flash: ColorRect
var health_notch: ColorRect
var safe_area: Control
var pause_button: Button
var top_panel: Panel
var pickup_effect_layer: Control
var tutorial_time := 0.0
var tutorial_step := 0
var health_notch_time := 0.0
var last_health_value := -1.0


func _ready() -> void:
	layer = 10
	safe_area = SafeArea.new()
	add_child(safe_area)
	_build_top_panel(safe_area)
	skill_dock = SkillDock.new()
	safe_area.add_child(skill_dock)
	skill_dock.anchor_left = 1.0
	skill_dock.anchor_top = 1.0
	skill_dock.anchor_right = 1.0
	skill_dock.anchor_bottom = 1.0
	skill_dock.offset_left = -304.0
	skill_dock.offset_top = -130.0
	skill_dock.offset_right = -18.0
	skill_dock.offset_bottom = -42.0
	stage_hud = StageHud.new()
	safe_area.add_child(stage_hud)
	_build_controls(safe_area)
	_build_damage_flash()
	pickup_effect_layer = HudPickupFeedback.new()
	add_child(pickup_effect_layer)
	visible = false


func configure(active_skill_ids: Array, opening_tutorial_grace := 0.0) -> void:
	skill_dock.configure(active_skill_ids)
	tutorial_step = 0
	tutorial_time = maxf(5.0, opening_tutorial_grace)
	last_health_value = -1.0
	health_notch_time = 0.0
	health_notch.visible = false
	tutorial_label.text = "拖动左下摇杆移动"
	tutorial_panel.visible = true
	tutorial_panel.modulate.a = 1.0


func refresh(state: RefCounted, level: LevelConfig, player: Node2D, skills: Node2D, pickups: Node2D, passives: RefCounted, stage: StageConfig, elite: Node) -> void:
	var health_ratio: float = player.health / maxf(player.max_health, 0.001)
	if last_health_value >= 0.0 and player.health < last_health_value:
		_show_health_notch(health_ratio)
	last_health_value = player.health
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	health_bar.configure_colors(UiFactory.DANGER if health_ratio <= 0.3 else UiFactory.SUPPORTING, Color(0.35, 0.5, 0.52, 0.24), 6.0)
	health_label.text = "生命 %d / %d" % [ceili(player.health), ceili(player.max_health)]
	health_label.modulate = Color.WHITE if health_ratio > 0.3 else UiFactory.DANGER_DARK
	xp_bar.max_value = state.experience_needed
	xp_bar.value = state.experience
	level_label.text = "LV.%d" % state.player_level
	stats_label.text = "%s  ·  击败 %d" % [_format_time(maxf(0.0, level.duration - state.elapsed)), state.kills]
	skill_dock.refresh(skills, state.elapsed)
	var passive_color := Color("70e8ff") if state.hero_id == "star_warden" else Color("ff9a62")
	stage_hud.refresh(stage, passives.status_text(state.elapsed), passive_color, pickups.remaining_magnet_seconds(state.elapsed), elite, state.elapsed, level.duration)


func advance(delta: float) -> void:
	tutorial_time = maxf(0.0, tutorial_time - delta)
	if tutorial_step == 0:
		tutorial_panel.modulate.a = 1.0 if tutorial_time > 0.0 else 0.0
	else:
		tutorial_panel.modulate.a = clampf(tutorial_time / 0.8, 0.0, 1.0)
	tutorial_panel.visible = tutorial_panel.modulate.a > 0.001
	health_notch_time = maxf(0.0, health_notch_time - delta)
	health_notch.visible = health_notch_time > 0.0
	health_notch.modulate.a = clampf(health_notch_time / 0.22, 0.0, 1.0)
	stage_hud.advance(delta)


func show_pickup_destination(pickup_id: String, from_screen: Vector2) -> void:
	pickup_effect_layer.show_destination(pickup_id, from_screen, xp_bar, health_bar, stage_hud.status_panel)


func observe_movement(direction: Vector2) -> void:
	if tutorial_step != 0 or direction.length_squared() < 0.04:
		return
	tutorial_step = 1
	tutorial_time = 2.4
	tutorial_label.text = "很好！技能会自动释放"


func movement_vector() -> Vector2:
	return joystick.value


func cancel_input() -> void:
	joystick.cancel_input()


func show_banner(title: String, subtitle: String, duration: float) -> void:
	stage_hud.show_banner(title, subtitle, duration)


func _build_top_panel(parent: Control) -> void:
	top_panel = Panel.new()
	parent.add_child(top_panel)
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.offset_left = -252.0
	top_panel.offset_top = 8.0
	top_panel.offset_right = 252.0
	top_panel.offset_bottom = 80.0
	SunlitCardStyle.apply_panel(top_panel, Color(UiFactory.SURFACE, 0.98), Color("8d7248"), 8.0, false, true, "hud_top")
	var level_plate := Panel.new()
	level_plate.position = Vector2(-4, -4)
	level_plate.size = Vector2(102, 80)
	SunlitCardStyle.apply_panel(level_plate, UiFactory.HUD_SURFACE_ALT, UiFactory.ACCENT, 8.0, true, true, "map_tag", 2)
	top_panel.add_child(level_plate)
	level_label = UiFactory.label("LV.1", 23, UiFactory.HUD_TEXT)
	level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_plate.add_child(level_label)
	stats_label = UiFactory.label("", 16, UiFactory.INK)
	stats_label.position = Vector2(106, 37)
	stats_label.size = Vector2(310, 24)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_panel.add_child(stats_label)
	health_bar = _make_bar(Vector2(102, 10), Vector2(322, 21), UiFactory.SUPPORTING, 6.0)
	top_panel.add_child(health_bar)
	health_notch = ColorRect.new()
	health_notch.color = UiFactory.DANGER
	health_notch.position = Vector2(102, 8)
	health_notch.size = Vector2(5, 25)
	health_notch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_notch.visible = false
	top_panel.add_child(health_notch)
	health_label = UiFactory.label("生命 100 / 100", 14, UiFactory.INK)
	health_label.position = Vector2(102, 10)
	health_label.size = Vector2(322, 21)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_panel.add_child(health_label)
	xp_bar = _make_bar(Vector2(102, 64), Vector2(322, 5), UiFactory.PRIMARY, 2.5)
	top_panel.add_child(xp_bar)
	pause_button = Button.new()
	pause_button.position = Vector2(438, 10)
	pause_button.size = Vector2(52, 52)
	var pause_style := UiFactory.panel_style(UiFactory.HUD_SURFACE, 26.0, UiFactory.ACCENT)
	pause_style.set_border_width_all(3)
	for state in ["normal", "hover", "pressed", "focus"]:
		pause_button.add_theme_stylebox_override(state, pause_style)
	pause_button.pressed.connect(pause_requested.emit)
	top_panel.add_child(pause_button)
	var pause_glyph := SunlitGlyph.new()
	pause_glyph.glyph_id = "pause"
	pause_glyph.set_selected(true)
	pause_glyph.position = Vector2(13, 13)
	pause_glyph.size = Vector2(26, 26)
	pause_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_button.add_child(pause_glyph)


func _build_controls(parent: Control) -> void:
	joystick = VirtualJoystickScript.new()
	parent.add_child(joystick)
	joystick.anchor_top = 0.5
	joystick.anchor_right = 0.5
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 0.0
	joystick.offset_top = 0.0
	joystick.offset_right = 0.0
	joystick.offset_bottom = 0.0
	tutorial_panel = Panel.new()
	parent.add_child(tutorial_panel)
	tutorial_panel.anchor_top = 1.0
	tutorial_panel.anchor_right = 1.0
	tutorial_panel.anchor_bottom = 1.0
	tutorial_panel.offset_left = 88.0
	tutorial_panel.offset_top = -220.0
	tutorial_panel.offset_right = -88.0
	tutorial_panel.offset_bottom = -176.0
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SunlitCardStyle.apply_panel(tutorial_panel, Color(UiFactory.HUD_SURFACE, 0.92), Color(UiFactory.PRIMARY_LIGHT, 0.72), 8.0, false, true, "map_tag")
	tutorial_label = UiFactory.label("拖动左下摇杆移动", 16, UiFactory.HUD_TEXT)
	tutorial_panel.add_child(tutorial_label)
	tutorial_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_label.offset_left = 12.0
	tutorial_label.offset_right = -12.0
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_damage_flash() -> void:
	damage_flash = ColorRect.new()
	damage_flash.color = Color(0.85, 0.035, 0.08, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)
	ScreenLayout.fill(damage_flash)


func _show_health_notch(health_ratio: float) -> void:
	health_notch.position.x = 102.0 + clampf(health_ratio, 0.0, 1.0) * 322.0 - health_notch.size.x * 0.5
	health_notch_time = 0.22
	health_notch.visible = true


func _make_bar(at: Vector2, bar_size: Vector2, color: Color, radius: float) -> Control:
	var bar := CompactProgressBar.new()
	bar.position = at
	bar.size = bar_size
	bar.configure_colors(color, Color(0.35, 0.5, 0.52, 0.24), radius)
	return bar


func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
