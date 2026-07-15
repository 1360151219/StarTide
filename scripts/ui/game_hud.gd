extends CanvasLayer

signal pause_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const SafeArea = preload("res://scripts/ui/safe_area.gd")
const SkillDock = preload("res://scripts/ui/skill_dock.gd")
const StageHud = preload("res://scripts/ui/stage_hud.gd")
const VirtualJoystickScript = preload("res://scripts/virtual_joystick.gd")

var health_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var stats_label: Label
var skill_dock: Panel
var stage_hud: Control
var joystick: Control
var tutorial_label: Label
var damage_flash: ColorRect
var safe_area: Control
var pause_button: Button
var tutorial_time := 8.0


func _ready() -> void:
	layer = 10
	safe_area = SafeArea.new()
	add_child(safe_area)
	_build_top_panel(safe_area)
	skill_dock = SkillDock.new()
	safe_area.add_child(skill_dock)
	skill_dock.anchor_left = 0.5
	skill_dock.anchor_right = 0.5
	skill_dock.offset_left = -138.0
	skill_dock.offset_top = 140.0
	skill_dock.offset_right = 138.0
	skill_dock.offset_bottom = 204.0
	stage_hud = StageHud.new()
	safe_area.add_child(stage_hud)
	_build_controls(safe_area)
	_build_damage_flash()
	visible = false


func configure(active_skill_ids: Array) -> void:
	skill_dock.configure(active_skill_ids)
	tutorial_time = 8.0


func refresh(state: RefCounted, level: LevelConfig, player: Node2D, skills: Node2D, pickups: Node2D, passives: RefCounted, stage: StageConfig, elite: Node) -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	xp_bar.max_value = state.experience_needed
	xp_bar.value = state.experience
	level_label.text = "LV.%d" % state.player_level
	stats_label.text = "星门 %s   击败 %d" % [_format_time(maxf(0.0, level.duration - state.elapsed)), state.kills]
	skill_dock.refresh(skills, state.elapsed)
	var passive_color := Color("70e8ff") if state.hero_id == "star_warden" else Color("ff9a62")
	stage_hud.refresh(stage, passives.status_text(state.elapsed), passive_color, pickups.remaining_magnet_seconds(state.elapsed), elite)


func advance(delta: float) -> void:
	tutorial_time = maxf(0.0, tutorial_time - delta)
	tutorial_label.modulate.a = clampf(tutorial_time / 2.0, 0.0, 1.0)
	stage_hud.advance(delta)


func movement_vector() -> Vector2:
	return joystick.value


func cancel_input() -> void:
	joystick.cancel_input()


func show_banner(title: String, subtitle: String, duration: float) -> void:
	stage_hud.show_banner(title, subtitle, duration)


func _build_top_panel(parent: Control) -> void:
	var panel := Panel.new()
	parent.add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -252.0
	panel.offset_top = 18.0
	panel.offset_right = 252.0
	panel.offset_bottom = 130.0
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.025, 0.045, 0.115, 0.92), 18.0, Color(0.75, 0.58, 0.27, 0.65)))
	level_label = UiFactory.label("LV.1", 24, Color("f6d782"))
	level_label.position = Vector2(18, 12)
	panel.add_child(level_label)
	stats_label = UiFactory.label("", 19, Color("d9e8f4"))
	stats_label.position = Vector2(190, 15)
	stats_label.size = Vector2(292, 28)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(stats_label)
	health_bar = _make_bar(Vector2(18, 49), Vector2(466, 17), Color("f0647d"), 8.0)
	panel.add_child(health_bar)
	xp_bar = _make_bar(Vector2(18, 76), Vector2(466, 9), Color("55d9e8"), 5.0)
	panel.add_child(xp_bar)


func _build_controls(parent: Control) -> void:
	pause_button = Button.new()
	parent.add_child(pause_button)
	pause_button.anchor_left = 0.5
	pause_button.anchor_right = 0.5
	pause_button.offset_left = 168.0
	pause_button.offset_top = 140.0
	pause_button.offset_right = 252.0
	pause_button.offset_bottom = 204.0
	pause_button.text = "Ⅱ"
	pause_button.add_theme_font_size_override("font_size", 25)
	pause_button.add_theme_stylebox_override("normal", UiFactory.button_style(Color(0.025, 0.045, 0.115, 0.9), Color(0.75, 0.58, 0.27, 0.65)))
	pause_button.pressed.connect(pause_requested.emit)
	joystick = VirtualJoystickScript.new()
	parent.add_child(joystick)
	joystick.anchor_top = 0.5
	joystick.anchor_right = 0.5
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 0.0
	joystick.offset_top = 0.0
	joystick.offset_right = 0.0
	joystick.offset_bottom = 0.0
	tutorial_label = UiFactory.label("拖动左下摇杆移动 · 技能会自动释放", 18, Color("dff7ff"))
	parent.add_child(tutorial_label)
	tutorial_label.anchor_top = 1.0
	tutorial_label.anchor_right = 1.0
	tutorial_label.anchor_bottom = 1.0
	tutorial_label.offset_left = 110.0
	tutorial_label.offset_top = -68.0
	tutorial_label.offset_right = -20.0
	tutorial_label.offset_bottom = -32.0
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_damage_flash() -> void:
	damage_flash = ColorRect.new()
	damage_flash.color = Color(0.85, 0.035, 0.08, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)
	ScreenLayout.fill(damage_flash)


func _make_bar(at: Vector2, bar_size: Vector2, color: Color, radius: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.size = bar_size
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", UiFactory.flat_bar_style(Color("18203c"), radius))
	bar.add_theme_stylebox_override("fill", UiFactory.flat_bar_style(color, radius))
	return bar


func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
