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
	stage_label = UiFactory.label("", 17, Color("f6d782"))
	stage_label.position = Vector2(24, 210)
	stage_label.size = Vector2(180, 34)
	add_child(stage_label)
	passive_label = UiFactory.label("", 16, Color("70e8ff"))
	passive_label.anchor_left = 1.0
	passive_label.anchor_right = 1.0
	passive_label.offset_left = -342.0
	passive_label.offset_top = 210.0
	passive_label.offset_right = -26.0
	passive_label.offset_bottom = 244.0
	passive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(passive_label)
	item_label = UiFactory.label("", 18, Color("70e8ff"))
	item_label.anchor_left = 1.0
	item_label.anchor_right = 1.0
	item_label.offset_left = -216.0
	item_label.offset_top = 236.0
	item_label.offset_right = -26.0
	item_label.offset_bottom = 270.0
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
	banner_time = duration
	banner.modulate.a = 1.0
	banner.visible = true


func advance(delta: float) -> void:
	if banner_time <= 0.0:
		banner.visible = false
		return
	banner_time = maxf(0.0, banner_time - delta)
	banner.modulate.a = clampf(banner_time / 0.45, 0.0, 1.0)


func _build_elite_panel() -> void:
	elite_panel = Panel.new()
	elite_panel.anchor_left = 0.5
	elite_panel.anchor_right = 0.5
	elite_panel.offset_left = -188.0
	elite_panel.offset_top = 270.0
	elite_panel.offset_right = 188.0
	elite_panel.offset_bottom = 328.0
	elite_panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.04, 0.055, 0.11, 0.95), 14.0, Color("f6c968")))
	elite_panel.visible = false
	add_child(elite_panel)
	elite_name = UiFactory.label("精英", 17, Color("fff0a8"))
	elite_name.position = Vector2(14, 5)
	elite_name.size = Vector2(348, 24)
	elite_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_panel.add_child(elite_name)
	elite_health = ProgressBar.new()
	elite_health.position = Vector2(18, 34)
	elite_health.size = Vector2(340, 10)
	elite_health.show_percentage = false
	elite_health.add_theme_stylebox_override("background", UiFactory.flat_bar_style(Color("221d2c"), 4.0))
	elite_health.add_theme_stylebox_override("fill", UiFactory.flat_bar_style(Color("f6c968"), 4.0))
	elite_panel.add_child(elite_health)


func _build_banner() -> void:
	banner = Panel.new()
	banner.anchor_left = 0.5
	banner.anchor_top = 0.5
	banner.anchor_right = 0.5
	banner.anchor_bottom = 0.5
	banner.offset_left = -208.0
	banner.offset_top = -130.0
	banner.offset_right = 208.0
	banner.offset_bottom = -14.0
	banner.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.025, 0.045, 0.11, 0.95), 18.0, Color("f6c968")))
	banner.visible = false
	add_child(banner)
	banner_title = UiFactory.label("", 28, Color("f6d782"))
	banner_title.position = Vector2(16, 15)
	banner_title.size = Vector2(384, 38)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_title)
	banner_subtitle = UiFactory.label("", 17, Color("d5e5f4"))
	banner_subtitle.position = Vector2(16, 61)
	banner_subtitle.size = Vector2(384, 30)
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_subtitle)
