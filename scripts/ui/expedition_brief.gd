extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const HomeInfoGlyph = preload("res://scripts/ui/home_info_glyph.gd")
const FRAME := preload("res://assets/art/ui/home/expedition_brief_frame.png")

var recommended_label: Label
var current_power_label: Label
var reward_title_label: Label
var reward_label: Label
var reward_icon: Control
var _paper: TextureRect
var _built := false


func _ready() -> void:
	_ensure_built()


func configure(level: LevelConfig, current_power: int, unlocked: bool, cleared: bool) -> void:
	_ensure_built()
	var recommended_power := level.recommended_power
	var reward_name := level.reward.display_name if level.reward != null else "待揭晓"
	recommended_label.text = "推荐战力 %d" % recommended_power
	current_power_label.text = "当前战力 %d" % current_power
	reward_title_label.text = "通关掉落" if cleared else "首通奖励"
	reward_label.text = "随机装备 ×1–4" if cleared else "%s ×1" % reward_name
	reward_label.add_theme_font_size_override("font_size", 15)
	var reached := current_power >= recommended_power
	current_power_label.add_theme_color_override(
		"font_color",
		UiFactory.PRIMARY_DARK if reached else UiFactory.DANGER_DARK
	)
	reward_label.add_theme_color_override(
		"font_color",
		UiFactory.PRIMARY_DARK if cleared else UiFactory.ACCENT_DARK
	)
	modulate = Color(1, 1, 1, 1.0 if unlocked else 0.78)
	tooltip_text = "推荐战力%d，当前战力%d，%s" % [recommended_power, current_power, "胜利掉落一到四件随机装备" if cleared else "首通奖励%s一份，另掉落一到四件随机装备" % reward_name]
	accessibility_name = tooltip_text


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	size = Vector2(381, 116)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper = TextureRect.new()
	_paper.size = size
	_paper.texture = FRAME
	_paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paper.stretch_mode = TextureRect.STRETCH_SCALE
	_paper.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paper)
	_build_rows()


func _build_rows() -> void:
	_add_glyph("shield", Vector2(30.5, 9))
	_add_glyph("swords", Vector2(215.5, 9))
	_add_glyph("compass", Vector2(30.5, 57))
	reward_icon = _add_glyph("reward", Vector2(215.5, 57))
	recommended_label = _add_label(Vector2(65.5, 10), Vector2(126, 34), 16, UiFactory.INK)
	current_power_label = _add_label(Vector2(250.5, 10), Vector2(126, 34), 16, UiFactory.PRIMARY_DARK)
	reward_title_label = _add_label(Vector2(65.5, 60), Vector2(126, 34), 16, UiFactory.INK)
	reward_label = _add_label(Vector2(250.5, 60), Vector2(126, 34), 15, UiFactory.ACCENT_DARK)


func _add_glyph(glyph_id: String, at: Vector2) -> Control:
	var glyph := HomeInfoGlyph.new()
	glyph.position = at
	glyph.size = Vector2(32, 32)
	glyph.glyph_id = glyph_id
	_paper.add_child(glyph)
	return glyph


func _add_label(at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := UiFactory.surface_label("", font_size, color)
	label.position = at
	label.size = label_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(label)
	return label
