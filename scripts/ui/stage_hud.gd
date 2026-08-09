extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const BattleRouteProgress = preload("res://scripts/ui/battle_route_progress.gd")

var stage_label: Label
var passive_label: Label
var item_label: Label
var status_panel: Panel
var route_progress: Control
var elite_panel: Panel
var elite_name: Label
var elite_health: ProgressBar
var banner: Panel
var banner_title: Label
var banner_subtitle: Label
var banner_time := 0.0
var elite_active := false


func _ready() -> void:
	ScreenLayout.fill(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel = Panel.new()
	status_panel.position = Vector2(18, 86)
	status_panel.size = Vector2(504, 64)
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SunlitCardStyle.apply_panel(status_panel, Color(UiFactory.HUD_SURFACE, 0.82), Color(UiFactory.PRIMARY_LIGHT, 0.42), 8.0, false, true, "ribbon")
	add_child(status_panel)
	route_progress = BattleRouteProgress.new()
	route_progress.position = Vector2(14, 6)
	route_progress.size = Vector2(476, 36)
	status_panel.add_child(route_progress)
	stage_label = UiFactory.label("", 13, UiFactory.HUD_TEXT)
	stage_label.position = Vector2(28, 127)
	stage_label.size = Vector2(180, 20)
	add_child(stage_label)
	passive_label = UiFactory.label("", 13, UiFactory.HUD_TEXT)
	passive_label.anchor_left = 1.0
	passive_label.anchor_right = 1.0
	passive_label.offset_left = -342.0
	passive_label.offset_top = 127.0
	passive_label.offset_right = -26.0
	passive_label.offset_bottom = 147.0
	passive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(passive_label)
	item_label = UiFactory.label("", 14, UiFactory.HUD_TEXT)
	item_label.anchor_left = 1.0
	item_label.anchor_right = 1.0
	item_label.offset_left = -216.0
	item_label.offset_top = 119.0
	item_label.offset_right = -26.0
	item_label.offset_bottom = 147.0
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(item_label)
	_build_elite_panel()
	_build_banner()


func refresh(stage: StageConfig, passive_text: String, passive_color: Color, magnet_seconds: int, elite: Node, elapsed: float, duration: float) -> void:
	stage_label.text = stage.display_name
	route_progress.set_progress(elapsed / maxf(duration, 0.001))
	passive_label.text = passive_text
	passive_label.add_theme_color_override("font_color", passive_color)
	item_label.visible = magnet_seconds > 0 and banner_time <= 0.0
	item_label.text = "磁吸状态  %ds" % magnet_seconds
	elite_active = is_instance_valid(elite)
	if is_instance_valid(elite):
		elite_panel.visible = banner_time <= 0.0
		elite_name.text = "精英 · %s" % elite.display_name
		elite_health.max_value = elite.max_health
		elite_health.value = elite.health
	else:
		elite_panel.visible = false


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
		status_panel.visible = true
		stage_label.visible = true
		passive_label.visible = true
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
	elite_panel.offset_top = 156.0
	elite_panel.offset_right = 174.0
	elite_panel.offset_bottom = 200.0
	SunlitCardStyle.apply_panel(elite_panel, UiFactory.HUD_SURFACE, UiFactory.DANGER, 8.0, false, true, "danger")
	elite_panel.visible = false
	add_child(elite_panel)
	elite_name = UiFactory.label("精英", 14, UiFactory.HUD_TEXT)
	elite_name.position = Vector2(12, 2)
	elite_name.size = Vector2(324, 20)
	elite_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_panel.add_child(elite_name)
	elite_health = ProgressBar.new()
	elite_health.position = Vector2(16, 26)
	elite_health.size = Vector2(316, 8)
	elite_health.show_percentage = false
	elite_health.add_theme_stylebox_override("background", UiFactory.flat_bar_style(Color(0.35, 0.5, 0.52, 0.24), 4.0))
	elite_health.add_theme_stylebox_override("fill", UiFactory.flat_bar_style(UiFactory.DANGER, 4.0))
	elite_panel.add_child(elite_health)


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
