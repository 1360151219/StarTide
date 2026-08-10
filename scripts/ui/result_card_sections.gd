class_name ResultCardSections
extends RefCounted

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const HeroRigScene = preload("res://scenes/presentation/hero_rig_2d.tscn")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
const ResultRewardStrip = preload("res://scripts/ui/result_reward_strip.gd")
const PauseBuildStrip = preload("res://scripts/ui/pause_build_strip.gd")
const VICTORY_CREST := preload("res://assets/generated/ui/victory_crest.png")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")

const RESULT_SURFACE_ALT := UiFactory.SURFACE_ALT
const INK := UiFactory.INK
const AMBER := UiFactory.ACCENT
const TEAL := UiFactory.PRIMARY_DARK

var result_state_label: Label
var hero_rig: HeroRig2D
var victory_crest: TextureRect
var celebration_stars: Array[Control] = []
var stat_values: Array[Label] = []
var reward_strip: Control
var build_icons: HBoxContainer


func build_state_pill() -> CenterContainer:
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(0, 28)
	var pill := Panel.new()
	pill.custom_minimum_size = Vector2(176, 28)
	SunlitCardStyle.apply_panel(pill, RESULT_SURFACE_ALT, Color(UiFactory.PRIMARY, 0.64), 4.0, false, true, "ribbon")
	center.add_child(pill)
	result_state_label = surface_label("", 14, TEAL)
	result_state_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(result_state_label)
	return center


func build_hero_stage() -> Panel:
	var stage := Panel.new()
	stage.custom_minimum_size = Vector2(0, 174)
	stage.clip_contents = true
	stage.add_theme_stylebox_override("panel", UiFactory.flat_bar_style(Color(UiFactory.SURFACE_ALT, 0.74), 6.0))
	var top_rule := ColorRect.new()
	top_rule.position = Vector2(28, 0)
	top_rule.size = Vector2(388, 2)
	top_rule.color = Color(UiFactory.PRIMARY, 0.4)
	top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(top_rule)
	var bottom_rule := ColorRect.new()
	bottom_rule.position = Vector2(28, 172)
	bottom_rule.size = Vector2(388, 2)
	bottom_rule.color = Color(UiFactory.PRIMARY, 0.28)
	bottom_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bottom_rule)
	victory_crest = TextureRect.new()
	victory_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	victory_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	victory_crest.texture = VICTORY_CREST
	victory_crest.position = Vector2(147, 4)
	victory_crest.size = Vector2(150, 150)
	victory_crest.pivot_offset = Vector2(75, 75)
	victory_crest.modulate = Color(1.0, 1.0, 1.0, 0.34)
	victory_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(victory_crest)
	_add_celebration_stars(stage)
	hero_rig = HeroRigScene.instantiate()
	hero_rig.position = Vector2(222, 168)
	stage.add_child(hero_rig)
	stage.visible = false
	hero_rig.set_active(false)
	return stage


func _add_celebration_stars(stage: Panel) -> void:
	var positions := [Vector2(68, 32), Vector2(354, 28), Vector2(104, 122), Vector2(332, 126)]
	var sizes := [28, 22, 18, 24]
	for index in range(positions.size()):
		var star := SunlitGlyph.new()
		star.glyph_id = "expedition"
		star.set_selected(index % 2 == 0)
		star.position = positions[index]
		star.size = Vector2(sizes[index], sizes[index])
		star.pivot_offset = star.size * 0.5
		stage.add_child(star)
		celebration_stars.append(star)


func build_stat_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 50)
	row.add_theme_constant_override("separation", 0)
	var definitions := [
		{"glyph": "clock", "tooltip": "远征用时", "fallback": "--:--"},
		{"glyph": "enemy", "tooltip": "击败魔物", "fallback": "0"},
		{"glyph": "level", "tooltip": "局内等级", "fallback": "LV.1"},
	]
	for index in range(definitions.size()):
		row.add_child(_build_stat_chip(definitions[index], index < definitions.size() - 1))
	return row


func _build_stat_chip(definition: Dictionary, show_separator: bool) -> Panel:
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(0, 50)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.tooltip_text = str(definition["tooltip"])
	chip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var glyph := SunlitGlyph.new()
	glyph.glyph_id = str(definition["glyph"])
	glyph.position = Vector2(18, 11)
	glyph.size = Vector2(28, 28)
	chip.add_child(glyph)
	var value := surface_label(str(definition["fallback"]), 19, INK)
	value.position = Vector2(50, 5)
	value.size = Vector2(88, 40)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.clip_text = true
	chip.add_child(value)
	if show_separator:
		var separator := ColorRect.new()
		separator.anchor_left = 1.0
		separator.anchor_right = 1.0
		separator.offset_left = -1.0
		separator.offset_right = 0.0
		separator.offset_top = 9.0
		separator.offset_bottom = 41.0
		separator.color = Color(UiFactory.PRIMARY, 0.32)
		separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(separator)
	stat_values.append(value)
	return chip


func build_reward_panel() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 146)
	SunlitCardStyle.apply_panel(panel, RESULT_SURFACE_ALT, Color(UiFactory.PRIMARY, 0.68), 6.0, false, true, "ribbon")
	var title := surface_label("本局收获", 16, INK)
	title.position = Vector2(16, 5)
	title.size = Vector2(104, 28)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var title_rule := ColorRect.new()
	title_rule.position = Vector2(118, 19)
	title_rule.size = Vector2(306, 1)
	title_rule.color = Color(UiFactory.PRIMARY, 0.36)
	title_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_rule)
	reward_strip = ResultRewardStrip.new()
	reward_strip.position = Vector2(12, 37)
	reward_strip.size = Vector2(420, 96)
	panel.add_child(reward_strip)
	return panel


func build_build_panel() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 70)
	panel.tooltip_text = "本局技能与遗物"
	SunlitCardStyle.apply_panel(panel, Color(UiFactory.SURFACE, 0.86), Color(UiFactory.SUPPORTING, 0.54), 6.0, false, true, "ribbon")
	build_icons = PauseBuildStrip.new()
	build_icons.position = Vector2(26, 6)
	build_icons.size = Vector2(392, 58)
	panel.add_child(build_icons)
	return panel


func surface_label(text: String, font_size: int, color: Color) -> Label:
	var node := UiFactory.label(text, font_size, color)
	node.add_theme_constant_override("outline_size", 0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
