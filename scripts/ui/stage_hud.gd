extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const BattleRouteProgress = preload("res://scripts/ui/battle_route_progress.gd")
const BATTLE_PROGRESS_FRAME := preload("res://assets/art/ui/battle/battle_progress_frame.png")

var stage_label: Label
var passive_label: Label
var item_label: Label
var status_panel: Panel
var route_progress: Control
var elite_panel: Panel
var elite_name: Label
var elite_health: ProgressBar
var boss_phase_ticks: Array[ColorRect] = []
var previous_boss_phase := -1
var banner: Panel
var banner_title: Label
var banner_subtitle: Label
var banner_time := 0.0
var elite_active := false


func _ready() -> void:
	ScreenLayout.fill(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel = Panel.new()
	status_panel.anchor_left = 0.5
	status_panel.anchor_right = 0.5
	status_panel.offset_left = -252.0
	status_panel.offset_top = 86.0
	status_panel.offset_right = 252.0
	status_panel.offset_bottom = 134.0
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(status_panel)
	var progress_frame := TextureRect.new()
	progress_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	progress_frame.texture = BATTLE_PROGRESS_FRAME
	progress_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	progress_frame.stretch_mode = TextureRect.STRETCH_SCALE
	progress_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_child(progress_frame)
	route_progress = BattleRouteProgress.new()
	route_progress.position = Vector2(14, 2)
	route_progress.size = Vector2(476, 22)
	status_panel.add_child(route_progress)
	stage_label = UiFactory.surface_label("", 14, UiFactory.HUD_TEXT)
	stage_label.position = Vector2(24, 23)
	stage_label.size = Vector2(160, 16)
	stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_label.clip_text = true
	stage_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stage_label.modulate.a = 0.0
	status_panel.add_child(stage_label)
	passive_label = UiFactory.surface_label("", 14, UiFactory.INK)
	passive_label.position = Vector2(188, 23)
	passive_label.size = Vector2(180, 16)
	passive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	passive_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	passive_label.clip_text = true
	passive_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_panel.add_child(passive_label)
	item_label = UiFactory.surface_label("", 14, UiFactory.INK)
	item_label.position = Vector2(206, 23)
	item_label.size = Vector2(162, 16)
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_label.clip_text = true
	item_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_panel.add_child(item_label)
	_build_elite_panel()
	_build_banner()


func refresh(_stage: StageConfig, passive_text: String, passive_color: Color, magnet_seconds: int, elite: Node, elapsed: float, duration: float) -> void:
	stage_label.text = ""
	route_progress.set_progress(elapsed / maxf(duration, 0.001))
	passive_label.text = passive_text
	passive_label.add_theme_color_override("font_color", passive_color.darkened(0.42))
	item_label.visible = magnet_seconds > 0 and banner_time <= 0.0
	item_label.text = "磁吸状态  %ds" % magnet_seconds
	passive_label.visible = not item_label.visible
	elite_active = is_instance_valid(elite)
	if is_instance_valid(elite):
		elite_panel.visible = banner_time <= 0.0
		status_panel.visible = false
		elite_name.text = "%s · %s" % ["BOSS" if elite.is_boss else "精英", elite.display_name]
		elite_health.max_value = elite.max_health
		elite_health.value = elite.health
		for tick in boss_phase_ticks:
			tick.visible = elite.is_boss
		if elite.is_boss:
			var phase := 2 if elite.health <= elite.max_health * 0.33 else (1 if elite.health <= elite.max_health * 0.66 else 0)
			if previous_boss_phase >= 0 and phase > previous_boss_phase:
				_flash_boss_ticks()
			previous_boss_phase = phase
	else:
		elite_panel.visible = false
		status_panel.visible = banner_time <= 0.0
		for tick in boss_phase_ticks:
			tick.visible = false
		previous_boss_phase = -1


func show_banner(title: String, subtitle: String, duration: float) -> void:
	banner_title.text = title
	banner_subtitle.text = subtitle
	banner_time = minf(duration, 1.5)
	banner.modulate.a = 1.0
	banner.visible = true
	elite_panel.visible = false
	status_panel.visible = false
	stage_label.visible = false
	passive_label.visible = false
	item_label.visible = false


func advance(delta: float) -> void:
	if banner_time <= 0.0:
		banner.visible = false
		status_panel.visible = not elite_active
		stage_label.visible = true
		passive_label.visible = not item_label.visible
		elite_panel.visible = elite_active
		return
	status_panel.visible = false
	stage_label.visible = false
	passive_label.visible = false
	item_label.visible = false
	banner_time = maxf(0.0, banner_time - delta)
	banner.modulate.a = clampf(banner_time / 0.45, 0.0, 1.0)


func _build_elite_panel() -> void:
	elite_panel = Panel.new()
	elite_panel.anchor_left = 0.5
	elite_panel.anchor_right = 0.5
	elite_panel.offset_left = -174.0
	elite_panel.offset_top = 86.0
	elite_panel.offset_right = 174.0
	elite_panel.offset_bottom = 130.0
	SunlitCardStyle.apply_panel(elite_panel, UiFactory.HUD_SURFACE, UiFactory.DANGER, 8.0, false, true, "danger")
	elite_panel.visible = false
	add_child(elite_panel)
	elite_name = UiFactory.surface_label("精英", 14, UiFactory.HUD_TEXT)
	elite_name.position = Vector2(12, 2)
	elite_name.size = Vector2(324, 20)
	elite_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	elite_name.clip_text = true
	elite_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	elite_panel.add_child(elite_name)
	elite_health = ProgressBar.new()
	elite_health.position = Vector2(16, 26)
	elite_health.size = Vector2(316, 8)
	elite_health.show_percentage = false
	elite_health.add_theme_stylebox_override("background", UiFactory.flat_bar_style(Color(0.35, 0.5, 0.52, 0.24), 4.0))
	elite_health.add_theme_stylebox_override("fill", UiFactory.flat_bar_style(UiFactory.DANGER, 4.0))
	elite_panel.add_child(elite_health)
	for ratio in [0.33, 0.66]:
		var tick := ColorRect.new()
		tick.position = Vector2(16.0 + 316.0 * ratio - 1.0, 24.0)
		tick.size = Vector2(2.0, 12.0)
		tick.color = Color("fff4d8")
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.visible = false
		elite_panel.add_child(tick)
		boss_phase_ticks.append(tick)


func _flash_boss_ticks() -> void:
	for tick in boss_phase_ticks:
		tick.modulate = Color(1.0, 0.86, 0.38, 1.0)
		var tween := create_tween()
		tween.tween_property(tick, "modulate", Color.WHITE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _build_banner() -> void:
	banner = Panel.new()
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.offset_left = -220.0
	banner.offset_top = 88.0
	banner.offset_right = 220.0
	banner.offset_bottom = 152.0
	SunlitCardStyle.apply_panel(banner, UiFactory.HUD_SURFACE, UiFactory.ACCENT, 8.0, true, true, "map_tag")
	banner.visible = false
	add_child(banner)
	banner_title = UiFactory.label("", 22, UiFactory.HUD_TEXT)
	banner_title.position = Vector2(14, 7)
	banner_title.size = Vector2(412, 28)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_title)
	banner_subtitle = UiFactory.label("", 14, UiFactory.HUD_TEXT_MUTED)
	banner_subtitle.position = Vector2(14, 35)
	banner_subtitle.size = Vector2(412, 22)
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_subtitle)
