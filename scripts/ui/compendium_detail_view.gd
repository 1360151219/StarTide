extends Control

signal close_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterAssets = preload("res://scripts/ui/character_asset_catalog.gd")
const BACK_ICON = preload("res://assets/art/ui/compendium/back_icon.png")
const CATEGORY_SILHOUETTES := {
	"heroes": preload("res://assets/art/ui/compendium/category_heroes.png"),
	"enemies": preload("res://assets/art/ui/compendium/category_enemies.png"),
	"pickups": preload("res://assets/art/ui/compendium/category_pickups.png"),
	"skills": preload("res://assets/art/ui/compendium/category_skills.png"),
	"relics": preload("res://assets/art/ui/compendium/category_relics.png"),
}
const SECTION_MARKERS := ["基础效果", "终极效果", "分支 ·"]

var detail_icon: TextureRect
var detail_title: Label
var detail_subtitle: Label
var detail_description: RichTextLabel
var detail_hint: Label
var detail_panel: Control
var back_button: Button
var detail_scroll_hint: Label
var owner_badge: Panel
var owner_portrait: TextureRect
var navigation_mode := false
var navigation_reserve := 142.0
var reveal_tween: Tween


func build() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_top = 216.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 12
	detail_panel = Control.new()
	detail_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(detail_panel)
	_build_back(detail_panel)
	_build_record(detail_panel)
	_build_description(detail_panel)
	resized.connect(_layout)
	_layout()
	visible = false


func set_navigation_mode(enabled: bool) -> void:
	navigation_mode = enabled
	offset_bottom = -navigation_reserve if enabled else 0.0
	_layout()


func set_navigation_reserve(reserve: float) -> void:
	navigation_reserve = maxf(120.0, reserve)
	offset_bottom = -navigation_reserve if navigation_mode else 0.0
	_layout()


func present(
	entry: Dictionary,
	discovered: bool,
	accent: Color,
	description: String,
	hint: String,
	category: String
) -> void:
	detail_icon.texture = entry["texture"] if discovered else CATEGORY_SILHOUETTES[category]
	detail_icon.modulate = Color.WHITE if discovered else Color(0.22, 0.38, 0.38, 0.48)
	detail_title.text = entry["name"] if discovered else "？？？"
	detail_title.add_theme_color_override("font_color", UiFactory.INK)
	detail_subtitle.text = _detail_summary(entry) if discovered else "这条记录还藏在远征途中"
	detail_subtitle.add_theme_color_override("font_color", UiFactory.PRIMARY_DARK if discovered else UiFactory.MUTED_INK)
	_show_owner(entry, discovered and category == "skills", accent)
	detail_description.text = _structured_description(description)
	detail_description.scroll_to_line(0)
	detail_hint.text = hint
	detail_hint.visible = not discovered
	detail_scroll_hint.visible = discovered and (category == "skills" or description.length() > 160)
	visible = true
	if reveal_tween != null and reveal_tween.is_valid():
		reveal_tween.kill()
	position.x = 8.0
	modulate.a = 0.0
	reveal_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(self, "position:x", 0.0, 0.18)
	reveal_tween.tween_property(self, "modulate:a", 1.0, 0.18)


func hide_detail() -> void:
	visible = false
	position.x = 0.0
	modulate.a = 1.0


func _build_back(parent: Control) -> void:
	back_button = Button.new()
	back_button.name = "BackToCollection"
	back_button.position = Vector2(36, 4)
	back_button.size = Vector2(70, 56)
	back_button.icon = BACK_ICON
	back_button.expand_icon = true
	back_button.add_theme_constant_override("icon_max_width", 60)
	back_button.flat = true
	back_button.tooltip_text = "返回收藏"
	back_button.accessibility_name = "返回收藏"
	back_button.pressed.connect(close_requested.emit)
	parent.add_child(back_button)


func _build_record(parent: Control) -> void:
	detail_icon = TextureRect.new()
	detail_icon.name = "DetailSubject"
	detail_icon.position = Vector2(48, 58)
	detail_icon.size = Vector2(168, 170)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(detail_icon)
	detail_title = _plain_label("", 30, UiFactory.INK)
	UiFactory.apply_key_heading(detail_title, 30, UiFactory.INK)
	detail_title.position = Vector2(236, 74)
	detail_title.size = Vector2(252, 44)
	detail_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail_title.clip_text = true
	parent.add_child(detail_title)
	detail_subtitle = _plain_label("", 16, UiFactory.PRIMARY_DARK)
	detail_subtitle.position = Vector2(236, 126)
	detail_subtitle.size = Vector2(252, 88)
	detail_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_subtitle.max_lines_visible = 3
	detail_subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(detail_subtitle)
	owner_badge = Panel.new()
	owner_badge.name = "OwnerAvatarBadge"
	owner_badge.position = Vector2(236, 136)
	owner_badge.size = Vector2(52, 52)
	owner_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(owner_badge)
	owner_portrait = TextureRect.new()
	owner_portrait.position = Vector2(4, 4)
	owner_portrait.size = Vector2(44, 44)
	owner_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	owner_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	owner_badge.add_child(owner_portrait)
	var divider := ColorRect.new()
	divider.position = Vector2(48, 246)
	divider.size = Vector2(440, 2)
	divider.color = Color(UiFactory.PRIMARY, 0.36)
	parent.add_child(divider)


func _build_description(parent: Control) -> void:
	detail_description = RichTextLabel.new()
	detail_description.position = Vector2(52, 270)
	detail_description.size = Vector2(432, 280)
	detail_description.bbcode_enabled = true
	detail_description.fit_content = false
	detail_description.scroll_active = true
	detail_description.add_theme_font_size_override("normal_font_size", 17)
	detail_description.add_theme_color_override("default_color", UiFactory.MUTED_INK)
	detail_description.add_theme_constant_override("line_separation", 8)
	parent.add_child(detail_description)
	detail_scroll_hint = _plain_label("继续下滑查看", 14, UiFactory.PRIMARY_DARK)
	detail_scroll_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail_scroll_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(detail_scroll_hint)
	detail_hint = _plain_label("", 15, UiFactory.PRIMARY_DARK)
	detail_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_hint.clip_text = true
	parent.add_child(detail_hint)


func _layout() -> void:
	if not is_instance_valid(detail_description):
		return
	var footer_y := maxf(330.0, size.y - 46.0)
	detail_description.size.y = maxf(80.0, footer_y - 278.0)
	detail_scroll_hint.position = Vector2(328, footer_y - 30.0)
	detail_scroll_hint.size = Vector2(156, 28)
	detail_hint.position = Vector2(52, footer_y - 22.0)
	detail_hint.size = Vector2(432, 34)


func _show_owner(entry: Dictionary, visible_owner: bool, accent: Color) -> void:
	owner_badge.visible = visible_owner
	if not visible_owner:
		detail_subtitle.position.x = 236
		detail_subtitle.size.x = 252
		return
	owner_portrait.texture = CharacterAssets.hero_avatar_texture(str(entry.get("owner_hero_id", "")))
	owner_badge.add_theme_stylebox_override("panel", _owner_style(accent))
	detail_subtitle.position.x = 302
	detail_subtitle.size.x = 186


func _owner_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiFactory.SURFACE
	style.border_color = Color(accent, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(26)
	return style


func _detail_summary(entry: Dictionary) -> String:
	var lines: Array[String] = []
	var subtitle := str(entry.get("subtitle", ""))
	var summary := str(entry.get("summary", ""))
	if not subtitle.is_empty():
		lines.append(subtitle)
	if not summary.is_empty():
		lines.append(summary)
	return "\n".join(lines)


func _structured_description(description: String) -> String:
	var result: Array[String] = []
	for line in description.split("\n"):
		var text := str(line)
		if _is_section_marker(text):
			result.append("[font=%s][font_size=18][color=#286b78]%s[/color][/font_size][/font]" % [UiFactory.expedition_heading_font().resource_path, text])
		else:
			result.append(text)
	return "\n".join(result)


func _is_section_marker(text: String) -> bool:
	for marker in SECTION_MARKERS:
		if text == marker or text.begins_with(marker):
			return true
	return false


func _plain_label(text: String, font_size: int, color: Color) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	return label
