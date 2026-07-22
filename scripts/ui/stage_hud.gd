extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")

var stage_label: Label
var passive_label: Label
var item_label: Label
var elite_panel: Panel
var elite_name: Label
var elite_health: ProgressBar
var banner: Panel
var banner_title: Label
var banner_subtitle: Label
var banner_time := 0.0


func _ready() -> void:
	ScreenLayout.fill(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_label = UiFactory.label("", 15, UiFactory.CREAM)
	stage_label.position = Vector2(24, 91)
	stage_label.size = Vector2(180, 28)
	add_child(stage_label)
	passive_label = UiFactory.label("", 14, UiFactory.CREAM)
	passive_label.anchor_left = 1.0
	passive_label.anchor_right = 1.0
	passive_label.offset_left = -342.0
	passive_label.offset_top = 91.0
	passive_label.offset_right = -26.0
	passive_label.offset_bottom = 119.0
	passive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(passive_label)
	item_label = UiFactory.label("", 14, UiFactory.CREAM)
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


func refresh(stage: StageConfig, passive_text: String, passive_color: Color, magnet_seconds: int, elite: Node) -> void:
	stage_label.text = stage.display_name
	passive_label.text = passive_text
	passive_label.add_theme_color_override("font_color", passive_color)
	item_label.visible = magnet_seconds > 0
	item_label.text = "★ 星引磁场  %ds" % magnet_seconds
	if is_instance_valid(elite):
		elite_panel.visible = true
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
	stage_label.visible = false
	passive_label.visible = false


func advance(delta: float) -> void:
	if banner_time <= 0.0:
		banner.visible = false
		stage_label.visible = true
		passive_label.visible = true
		return
	banner_time = maxf(0.0, banner_time - delta)
	banner.modulate.a = clampf(banner_time / 0.45, 0.0, 1.0)


func _build_elite_panel() -> void:
	elite_panel = Panel.new()
	elite_panel.anchor_left = 0.5
	elite_panel.anchor_right = 0.5
	elite_panel.offset_left = -174.0
	elite_panel.offset_top = 126.0
	elite_panel.offset_right = 174.0
	elite_panel.offset_bottom = 170.0
	elite_panel.add_theme_stylebox_override("panel", UiFactory.panel_style(UiFactory.GLASS, 12.0, UiFactory.GOLD))
	elite_panel.visible = false
	add_child(elite_panel)
	elite_name = UiFactory.label("精英", 14, UiFactory.PALE)
	elite_name.position = Vector2(12, 2)
	elite_name.size = Vector2(324, 20)
	elite_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_panel.add_child(elite_name)
	elite_health = ProgressBar.new()
	elite_health.position = Vector2(16, 26)
	elite_health.size = Vector2(316, 8)
	elite_health.show_percentage = false
	elite_health.add_theme_stylebox_override("background", UiFactory.flat_bar_style(Color(0.35, 0.5, 0.52, 0.24), 4.0))
	elite_health.add_theme_stylebox_override("fill", UiFactory.flat_bar_style(UiFactory.GOLD, 4.0))
	elite_panel.add_child(elite_health)


func _build_banner() -> void:
	banner = Panel.new()
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.offset_left = -220.0
	banner.offset_top = 88.0
	banner.offset_right = 220.0
	banner.offset_bottom = 152.0
	banner.add_theme_stylebox_override("panel", UiFactory.panel_style(UiFactory.GLASS, 16.0, UiFactory.GOLD))
	banner.visible = false
	add_child(banner)
	banner_title = UiFactory.label("", 22, UiFactory.PALE)
	banner_title.position = Vector2(14, 7)
	banner_title.size = Vector2(412, 28)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_title)
	banner_subtitle = UiFactory.label("", 14, UiFactory.PALE_MUTED)
	banner_subtitle.position = Vector2(14, 35)
	banner_subtitle.size = Vector2(412, 22)
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_subtitle)
