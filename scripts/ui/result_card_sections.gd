class_name ResultCardSections
extends RefCounted

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const HeroRigScene = preload("res://scenes/presentation/hero_rig_2d.tscn")
const StarTideGlyph = preload("res://scripts/ui/star_tide_glyph.gd")
const ResultRewardStrip = preload("res://scripts/ui/result_reward_strip.gd")
const PauseBuildStrip = preload("res://scripts/ui/pause_build_strip.gd")
const VICTORY_CREST := preload("res://assets/generated/ui/victory_crest.png")

const MINT_SURFACE := Color(0.88, 0.97, 0.91, 0.98)
const INK := Color(0.07, 0.2, 0.24, 1.0)
const AMBER := Color(1.0, 0.67, 0.2, 1.0)
const TEAL := Color(0.08, 0.55, 0.57, 1.0)

var result_state_label: Label
var hero_rig: HeroRig2D
var victory_crest: TextureRect
var celebration_stars: Array[Label] = []
var stat_values: Array[Label] = []
var reward_strip: Control
var build_icons: HBoxContainer


func build_state_pill() -> CenterContainer:
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(0, 26)
	var pill := Panel.new()
	pill.custom_minimum_size = Vector2(176, 26)
	pill.add_theme_stylebox_override("panel", UiFactory.panel_style(MINT_SURFACE, 13.0, Color(0.3, 0.72, 0.66, 0.72)))
	center.add_child(pill)
	result_state_label = surface_label("", 13, TEAL)
	result_state_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(result_state_label)
	return center


func build_hero_stage() -> Panel:
	var stage := Panel.new()
	stage.custom_minimum_size = Vector2(0, 196)
	stage.clip_contents = true
	stage.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.85, 0.96, 0.93, 0.9), 22.0, Color(0.29, 0.72, 0.67, 0.75)))
	victory_crest = TextureRect.new()
	victory_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	victory_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	victory_crest.texture = VICTORY_CREST
	victory_crest.position = Vector2(134, 8)
	victory_crest.size = Vector2(176, 176)
	victory_crest.pivot_offset = Vector2(88, 88)
	victory_crest.modulate = Color(1.0, 1.0, 1.0, 0.3)
	victory_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(victory_crest)
	_add_celebration_stars(stage)
	hero_rig = HeroRigScene.instantiate()
	hero_rig.position = Vector2(222, 190)
	stage.add_child(hero_rig)
	stage.visible = false
	hero_rig.set_active(false)
	return stage


func _add_celebration_stars(stage: Panel) -> void:
	var positions := [Vector2(68, 38), Vector2(354, 32), Vector2(104, 138), Vector2(332, 142)]
	var sizes := [28, 22, 18, 24]
	for index in range(positions.size()):
		var star := surface_label("✦", sizes[index], AMBER if index % 2 == 0 else TEAL)
		star.position = positions[index]
		star.size = Vector2(36, 36)
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.pivot_offset = Vector2(18, 18)
		stage.add_child(star)
		celebration_stars.append(star)


func build_stat_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 62)
	row.add_theme_constant_override("separation", 8)
	for definition in [
		{"glyph": "clock", "tooltip": "远征用时", "fallback": "--:--"},
		{"glyph": "enemy", "tooltip": "击败魔物", "fallback": "0"},
		{"glyph": "level", "tooltip": "局内等级", "fallback": "Lv.1"},
	]:
		row.add_child(_build_stat_chip(definition))
	return row


func _build_stat_chip(definition: Dictionary) -> Panel:
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(0, 62)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.tooltip_text = str(definition["tooltip"])
	chip.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(1.0, 0.95, 0.78, 0.95), 15.0, Color(0.9, 0.67, 0.25, 0.76)))
	var glyph := StarTideGlyph.new()
	glyph.glyph_id = str(definition["glyph"])
	glyph.position = Vector2(10, 15)
	glyph.size = Vector2(32, 32)
	chip.add_child(glyph)
	var value := surface_label(str(definition["fallback"]), 19, INK)
	value.position = Vector2(43, 9)
	value.size = Vector2(94, 44)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.clip_text = true
	chip.add_child(value)
	stat_values.append(value)
	return chip


func build_reward_panel() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 140)
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(MINT_SURFACE, 18.0, Color(0.28, 0.68, 0.62, 0.7)))
	reward_strip = ResultRewardStrip.new()
	reward_strip.position = Vector2(12, 18)
	reward_strip.size = Vector2(420, 104)
	panel.add_child(reward_strip)
	return panel


func build_build_panel() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 82)
	panel.tooltip_text = "本局技能与遗物"
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.95, 0.95, 0.83, 0.94), 16.0, Color(0.48, 0.67, 0.57, 0.6)))
	build_icons = PauseBuildStrip.new()
	build_icons.position = Vector2(26, 12)
	build_icons.size = Vector2(392, 58)
	panel.add_child(build_icons)
	return panel


func surface_label(text: String, font_size: int, color: Color) -> Label:
	var node := UiFactory.label(text, font_size, color)
	node.add_theme_constant_override("outline_size", 0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
