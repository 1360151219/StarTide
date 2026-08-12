extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const FRAME := preload("res://assets/art/ui/home/expedition_brief_frame.png")
const RECOMMENDED_ICON := preload("res://assets/art/ui/home/brief_icon_recommended.png")
const POWER_ICON := preload("res://assets/art/ui/home/brief_icon_power.png")
const FIRST_CLEAR_ICON := preload("res://assets/art/ui/home/brief_icon_first_clear.png")
const REWARD_ICON := preload("res://assets/art/ui/home/brief_icon_reward.png")
const PANEL_SIZE := Vector2(350, 160)
const ICON_SIZE := Vector2(24, 24)
const ICON_X := 34.0
const CAPTION_X := 62.0
const CAPTION_WIDTH := 58.0
const POWER_VAL_X := 116.0
const POWER_VAL_RIGHT := 153.0
const RIGHT_ICON_X := 182.0
const REWARD_TEXT_X := 214.0
const REWARD_TEXT_RIGHT := 293.0
const REWARD_TEXT_GAP := 4.0
const FIRST_ROW_Y := 78.0
const SECOND_ROW_Y := 108.0
const ROW_HEIGHT := 24.0

var title_label: Label
var page_label: Label
var recommended_caption_label: Label
var recommended_label: Label
var current_power_caption_label: Label
var current_power_label: Label
var reward_title_label: Label
var reward_label: Label
var reward_count_label: Label
var recommended_icon: TextureRect
var power_icon: TextureRect
var first_clear_icon: TextureRect
var reward_icon: TextureRect
var _paper: TextureRect
var _built := false


func _ready() -> void:
	_ensure_built()


func configure(level: LevelConfig, current_power: int, unlocked: bool, cleared: bool) -> void:
	_ensure_built()
	var recommended_power := level.recommended_power
	var reward_name := level.reward.display_name if level.reward != null else "待揭晓"
	recommended_label.text = str(recommended_power)
	current_power_label.text = str(current_power)
	reward_title_label.text = "通关掉落" if cleared else "首通奖励"
	reward_label.text = "随机装备" if cleared else reward_name
	reward_count_label.text = "×1–4" if cleared else "×1"
	_layout_reward_text(40.0 if cleared else 24.0)
	var reached := current_power >= recommended_power
	current_power_label.add_theme_color_override(
		"font_color",
		UiFactory.ACCENT_DARK if reached else UiFactory.PRIMARY_DARK
	)
	var reward_color := UiFactory.PRIMARY_DARK if cleared else UiFactory.ACCENT_DARK
	reward_label.add_theme_color_override("font_color", reward_color)
	reward_count_label.add_theme_color_override("font_color", reward_color)
	modulate = Color(1, 1, 1, 1.0 if unlocked else 0.78)
	tooltip_text = "建议评分%d，当前养成评分%d；评分未经通关率校准，%s" % [recommended_power, current_power, "胜利掉落一到四件随机装备" if cleared else "首通奖励%s一份，另掉落一到四件随机装备" % reward_name]
	accessibility_name = tooltip_text


func set_page(current: int, total: int) -> void:
	page_label.text = "%d / %d" % [current, total]


func frame_texture_path() -> String:
	return _paper.texture.resource_path


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper = TextureRect.new()
	_paper.name = "Plaque"
	_paper.size = size
	_paper.texture = FRAME
	_paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paper.stretch_mode = TextureRect.STRETCH_SCALE
	_paper.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paper)
	_build_content()


func _build_content() -> void:
	title_label = _add_label(Vector2(36, 26), Vector2(198, 38), 24, UiFactory.INK)
	UiFactory.apply_level_title(title_label, 24)
	page_label = _add_label(Vector2(243, 30), Vector2(50, 30), 14, UiFactory.INK)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	recommended_icon = _add_icon(RECOMMENDED_ICON, Vector2(ICON_X, FIRST_ROW_Y))
	power_icon = _add_icon(POWER_ICON, Vector2(ICON_X, SECOND_ROW_Y))
	first_clear_icon = _add_icon(FIRST_CLEAR_ICON, Vector2(RIGHT_ICON_X, FIRST_ROW_Y))
	reward_icon = _add_icon(REWARD_ICON, Vector2(RIGHT_ICON_X, SECOND_ROW_Y))
	recommended_caption_label = _add_label(Vector2(CAPTION_X, FIRST_ROW_Y), Vector2(CAPTION_WIDTH, ROW_HEIGHT), 14, UiFactory.INK)
	recommended_caption_label.text = "建议评分"
	recommended_label = _add_label(Vector2(POWER_VAL_X, FIRST_ROW_Y), Vector2(POWER_VAL_RIGHT - POWER_VAL_X, ROW_HEIGHT), 14, UiFactory.INK)
	recommended_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	current_power_caption_label = _add_label(Vector2(CAPTION_X, SECOND_ROW_Y), Vector2(CAPTION_WIDTH, ROW_HEIGHT), 14, UiFactory.INK)
	current_power_caption_label.text = "养成评分"
	current_power_label = _add_label(Vector2(POWER_VAL_X, SECOND_ROW_Y), Vector2(POWER_VAL_RIGHT - POWER_VAL_X, ROW_HEIGHT), 14, UiFactory.PRIMARY_DARK)
	current_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward_title_label = _add_label(Vector2(REWARD_TEXT_X, FIRST_ROW_Y), Vector2(REWARD_TEXT_RIGHT - REWARD_TEXT_X, ROW_HEIGHT), 14, UiFactory.INK)
	reward_label = _add_label(Vector2(REWARD_TEXT_X, SECOND_ROW_Y), Vector2(75, ROW_HEIGHT), 14, UiFactory.ACCENT_DARK)
	reward_count_label = _add_label(Vector2(279, SECOND_ROW_Y), Vector2(24, ROW_HEIGHT), 14, UiFactory.ACCENT_DARK)
	reward_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _layout_reward_text(count_width: float) -> void:
	reward_count_label.position.x = REWARD_TEXT_RIGHT - count_width
	reward_count_label.size.x = count_width
	reward_label.size.x = reward_count_label.position.x - REWARD_TEXT_GAP - REWARD_TEXT_X


func _add_icon(texture: Texture2D, at: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.position = at
	icon.size = ICON_SIZE
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(icon)
	return icon


func _add_label(at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := UiFactory.surface_label("", font_size, color)
	label.position = at
	label.size = label_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(label)
	return label
