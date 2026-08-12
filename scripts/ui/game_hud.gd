extends CanvasLayer

signal pause_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const SafeArea = preload("res://scripts/ui/safe_area.gd")
const SkillDock = preload("res://scripts/ui/skill_dock.gd")
const StageHud = preload("res://scripts/ui/stage_hud.gd")
const BattleTopBar = preload("res://scripts/ui/battle_top_bar.gd")
const VirtualJoystickScript = preload("res://scripts/virtual_joystick.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const HudPickupFeedback = preload("res://scripts/ui/hud_pickup_feedback.gd")

var health_bar: Control
var xp_bar: Control
var health_label: Label
var level_label: Label
var stats_label: Label
var skill_dock: Control
var stage_hud: Control
var joystick: Control
var tutorial_panel: Panel
var tutorial_label: Label
var damage_flash: ColorRect
var health_notch: ColorRect
var safe_area: Control
var pause_button: Button
var top_panel: Control
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
	skill_dock.offset_left = -90.0
	skill_dock.offset_top = -114.0
	skill_dock.offset_right = -18.0
	skill_dock.offset_bottom = -42.0
	stage_hud = StageHud.new()
	safe_area.add_child(stage_hud)
	_build_controls(safe_area)
	top_panel.move_to_front()
	stage_hud.move_to_front()
	skill_dock.move_to_front()
	tutorial_panel.move_to_front()
	_build_damage_flash()
	pickup_effect_layer = HudPickupFeedback.new()
	add_child(pickup_effect_layer)
	visible = false


func configure(skill_slots: Array, opening_tutorial_grace := 0.0) -> void:
	skill_dock.configure(skill_slots)
	tutorial_step = 0
	tutorial_time = maxf(5.0, opening_tutorial_grace)
	last_health_value = -1.0
	health_notch_time = 0.0
	health_notch.visible = false
	tutorial_label.text = "在战场任意位置拖动移动"
	tutorial_panel.visible = true
	tutorial_panel.modulate.a = 1.0


func refresh(state: RefCounted, level: LevelConfig, player: Node2D, skills: Node2D, pickups: Node2D, passives: RefCounted, stage: StageConfig, elite: Node) -> void:
	var health_ratio: float = player.health / maxf(player.max_health, 0.001)
	if last_health_value >= 0.0 and player.health < last_health_value:
		_show_health_notch(health_ratio)
	last_health_value = player.health
	top_panel.refresh(state.player_level, player.health, player.max_health, state.experience, state.experience_needed, _format_time(maxf(0.0, level.duration - state.elapsed)), state.kills, health_ratio <= 0.3)
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
	skill_dock.collapse()


func show_banner(title: String, subtitle: String, duration: float) -> void:
	stage_hud.show_banner(title, subtitle, duration)


func _build_top_panel(parent: Control) -> void:
	top_panel = BattleTopBar.new()
	parent.add_child(top_panel)
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.offset_left = -252.0
	top_panel.offset_top = 8.0
	top_panel.offset_right = 252.0
	top_panel.offset_bottom = 80.0
	top_panel.pause_requested.connect(pause_requested.emit)
	health_bar = top_panel.health_bar
	xp_bar = top_panel.xp_bar
	health_label = top_panel.health_label
	level_label = top_panel.level_label
	stats_label = top_panel.stats_label
	health_notch = top_panel.health_notch
	pause_button = top_panel.pause_button


func _build_controls(parent: Control) -> void:
	joystick = VirtualJoystickScript.new()
	parent.add_child(joystick)
	joystick.anchor_right = 1.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 0.0
	joystick.offset_top = 0.0
	joystick.offset_right = 0.0
	joystick.offset_bottom = 0.0
	parent.move_child(joystick, 0)
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
	tutorial_label = UiFactory.label("在战场任意位置拖动移动", 16, UiFactory.HUD_TEXT)
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
	top_panel.show_health_notch(health_ratio)
	health_notch_time = 0.22


func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
