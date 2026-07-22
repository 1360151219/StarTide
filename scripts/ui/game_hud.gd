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
var health_label: Label
var level_label: Label
var stats_label: Label
var skill_dock: Panel
var stage_hud: Control
var joystick: Control
var tutorial_label: Label
var damage_flash: ColorRect
var safe_area: Control
var pause_button: Button
var top_panel: Panel
var tutorial_time := 5.0


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
	skill_dock.offset_left = -228.0
	skill_dock.offset_top = -104.0
	skill_dock.offset_right = -18.0
	skill_dock.offset_bottom = -42.0
	stage_hud = StageHud.new()
	safe_area.add_child(stage_hud)
	_build_controls(safe_area)
	_build_damage_flash()
	visible = false


func configure(active_skill_ids: Array) -> void:
	skill_dock.configure(active_skill_ids)
	tutorial_time = 5.0


func refresh(state: RefCounted, level: LevelConfig, player: Node2D, skills: Node2D, pickups: Node2D, passives: RefCounted, stage: StageConfig, elite: Node) -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	health_label.text = "%d / %d" % [ceili(player.health), ceili(player.max_health)]
	health_label.modulate = Color.WHITE if player.health / player.max_health > 0.3 else Color(1.0, 0.74, 0.62)
	xp_bar.max_value = state.experience_needed
	xp_bar.value = state.experience
	level_label.text = "LV.%d" % state.player_level
	stats_label.text = "剩余 %s  ·  击败 %d" % [_format_time(maxf(0.0, level.duration - state.elapsed)), state.kills]
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
	top_panel = Panel.new()
	parent.add_child(top_panel)
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.offset_left = -252.0
	top_panel.offset_top = 8.0
	top_panel.offset_right = 252.0
	top_panel.offset_bottom = 80.0
	top_panel.add_theme_stylebox_override("panel", UiFactory.panel_style(UiFactory.GLASS, 16.0, UiFactory.GOLD))
	level_label = UiFactory.label("LV.1", 21, UiFactory.PALE)
	level_label.position = Vector2(14, 8)
	level_label.size = Vector2(82, 28)
	top_panel.add_child(level_label)
	stats_label = UiFactory.label("", 17, UiFactory.PALE)
	stats_label.position = Vector2(94, 10)
	stats_label.size = Vector2(340, 26)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_panel.add_child(stats_label)
	health_bar = _make_bar(Vector2(14, 39), Vector2(420, 17), UiFactory.CORAL, 8.0)
	top_panel.add_child(health_bar)
	health_label = UiFactory.label("100 / 100", 14, UiFactory.CREAM)
	health_label.position = Vector2(14, 37)
	health_label.size = Vector2(420, 21)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_panel.add_child(health_label)
	xp_bar = _make_bar(Vector2(14, 61), Vector2(420, 5), UiFactory.PRIMARY, 3.0)
	top_panel.add_child(xp_bar)
	pause_button = Button.new()
	pause_button.position = Vector2(444, 10)
	pause_button.size = Vector2(48, 48)
	pause_button.text = "II"
	pause_button.add_theme_font_size_override("font_size", 21)
	pause_button.add_theme_color_override("font_color", UiFactory.CREAM)
	UiFactory.apply_button_styles(pause_button, UiFactory.PRIMARY_DARK, UiFactory.GOLD)
	pause_button.pressed.connect(pause_requested.emit)
	top_panel.add_child(pause_button)


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
	tutorial_label = UiFactory.label("拖动左下摇杆移动 · 技能会自动释放", 17, UiFactory.CREAM)
	parent.add_child(tutorial_label)
	tutorial_label.anchor_top = 1.0
	tutorial_label.anchor_right = 1.0
	tutorial_label.anchor_bottom = 1.0
	tutorial_label.offset_left = 98.0
	tutorial_label.offset_top = -158.0
	tutorial_label.offset_right = -18.0
	tutorial_label.offset_bottom = -126.0
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
	bar.add_theme_stylebox_override("background", UiFactory.flat_bar_style(Color(0.35, 0.5, 0.52, 0.24), radius))
	bar.add_theme_stylebox_override("fill", UiFactory.flat_bar_style(color, radius))
	return bar


func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
