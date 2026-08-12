extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const ChoiceFactory = preload("res://scripts/systems/upgrade_choice_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")

var skill_ids: Array = []
var icons: Array[TextureRect] = []
var badges: Array[Label] = []
var cooldown_bars: Array[ColorRect] = []
var launcher_button: Button
var launcher_icon: TextureRect
var launcher_count: Label
var detail_panel: Panel
var detail_rows: VBoxContainer
var current_skills: Node2D
var current_elapsed := 0.0


func _ready() -> void:
	size = Vector2(72, 72)
	_build_detail_panel()
	_build_launcher()


func configure(active_skill_ids: Array) -> void:
	skill_ids = active_skill_ids.duplicate()
	launcher_count.text = str(_active_count())
	detail_panel.visible = false
	_rebuild_rows(null, 0.0)


func refresh(skills: Node2D, elapsed: float) -> void:
	current_skills = skills
	current_elapsed = elapsed
	if skills.active_skill_ids != skill_ids:
		configure(skills.active_skill_ids)
	launcher_count.text = str(_active_count())
	launcher_icon.texture = _launcher_texture()
	launcher_icon.modulate = _launcher_color(skills, elapsed)
	if detail_panel.visible:
		_rebuild_rows(skills, elapsed)


func collapse() -> void:
	detail_panel.visible = false


func _build_launcher() -> void:
	launcher_button = Button.new()
	launcher_button.position = Vector2.ZERO
	launcher_button.size = Vector2(72, 72)
	launcher_button.tooltip_text = "查看自动技能"
	launcher_button.accessibility_name = "查看自动技能"
	var normal := _launcher_style(UiFactory.HUD_SURFACE_ALT, UiFactory.PRIMARY)
	var hover := _launcher_style(UiFactory.HUD_SURFACE_ALT.lightened(0.06), UiFactory.ACCENT_LIGHT)
	var pressed := _launcher_style(UiFactory.HUD_SURFACE_ALT.darkened(0.08), UiFactory.PRIMARY)
	pressed.shadow_size = 1
	pressed.shadow_offset = Vector2.ZERO
	var focus := _launcher_style(Color.TRANSPARENT, UiFactory.ACCENT)
	focus.set_expand_margin_all(2.0)
	launcher_button.add_theme_stylebox_override("normal", normal)
	launcher_button.add_theme_stylebox_override("hover", hover)
	launcher_button.add_theme_stylebox_override("pressed", pressed)
	launcher_button.add_theme_stylebox_override("focus", focus)
	launcher_button.pressed.connect(_toggle_details)
	add_child(launcher_button)
	launcher_icon = TextureRect.new()
	launcher_icon.position = Vector2(10, 8)
	launcher_icon.size = Vector2(52, 52)
	launcher_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	launcher_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	launcher_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	launcher_button.add_child(launcher_icon)
	launcher_count = UiFactory.surface_label("0", 13, UiFactory.HUD_TEXT)
	launcher_count.position = Vector2(48, 46)
	launcher_count.size = Vector2(21, 21)
	launcher_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	launcher_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	launcher_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	launcher_count.add_theme_stylebox_override("normal", UiFactory.flat_bar_style(UiFactory.PRIMARY_DARK, 10.0))
	launcher_button.add_child(launcher_count)


func _build_detail_panel() -> void:
	detail_panel = Panel.new()
	detail_panel.position = Vector2(-240, -226)
	detail_panel.size = Vector2(312, 218)
	SunlitCardStyle.apply_panel(detail_panel, Color(UiFactory.SURFACE, 0.98), UiFactory.PRIMARY, 10.0, false, true, "canvas")
	detail_panel.visible = false
	add_child(detail_panel)
	var title := UiFactory.surface_label("自动技能", 20, UiFactory.INK)
	UiFactory.apply_key_heading(title, 20, UiFactory.INK)
	title.position = Vector2(18, 12)
	title.size = Vector2(180, 30)
	detail_panel.add_child(title)
	var hint := UiFactory.surface_label("自动释放", 14, UiFactory.MUTED_INK)
	hint.position = Vector2(198, 15)
	hint.size = Vector2(96, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail_panel.add_child(hint)
	detail_rows = VBoxContainer.new()
	detail_rows.position = Vector2(16, 48)
	detail_rows.size = Vector2(280, 154)
	detail_rows.add_theme_constant_override("separation", 5)
	detail_panel.add_child(detail_rows)


func _toggle_details() -> void:
	detail_panel.visible = not detail_panel.visible
	launcher_button.accessibility_name = "收起自动技能" if detail_panel.visible else "查看自动技能"
	if detail_panel.visible:
		_rebuild_rows(current_skills, current_elapsed)


func _rebuild_rows(skills: Node2D, elapsed: float) -> void:
	for child in detail_rows.get_children():
		detail_rows.remove_child(child)
		child.queue_free()
	icons.clear()
	badges.clear()
	cooldown_bars.clear()
	for index in range(3):
		detail_rows.add_child(_build_row(index, skills, elapsed))


func _build_row(index: int, skills: Node2D, elapsed: float) -> Panel:
	var row := Panel.new()
	row.custom_minimum_size = Vector2(280, 48)
	row.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(UiFactory.SURFACE_ALT, 0.86), 6.0, Color(UiFactory.PRIMARY, 0.42)))
	var skill_id := str(skill_ids[index]) if index < skill_ids.size() else ""
	var level := int(skills.levels.get(skill_id, 0)) if skills != null and not skill_id.is_empty() else 0
	var icon := TextureRect.new()
	icon.position = Vector2(6, 4)
	icon.size = Vector2(40, 40)
	icon.texture = SkillCatalog.skill(skill_id).get("icon") if SkillCatalog.has(skill_id) else null
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = _row_icon_color(skills, skill_id, level, elapsed)
	row.add_child(icon)
	icons.append(icon)
	var name := UiFactory.surface_label(_skill_name(skill_id), 15, UiFactory.INK if not skill_id.is_empty() else UiFactory.MUTED_INK)
	name.position = Vector2(52, 4)
	name.size = Vector2(156, 22)
	row.add_child(name)
	var badge := UiFactory.surface_label(_badge(skill_id, level), 13, UiFactory.PRIMARY_DARK)
	badge.position = Vector2(218, 4)
	badge.size = Vector2(48, 22)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(badge)
	badges.append(badge)
	var track := ColorRect.new()
	track.position = Vector2(52, 32)
	track.size = Vector2(214, 4)
	track.color = Color(UiFactory.MUTED_INK, 0.18)
	row.add_child(track)
	var fill := ColorRect.new()
	fill.size = Vector2(214.0 * _cooldown(skills, skill_id), 4)
	fill.color = UiFactory.PRIMARY
	track.add_child(fill)
	cooldown_bars.append(fill)
	return row


func _active_count() -> int:
	var count := 0
	for skill_id in skill_ids:
		if not str(skill_id).is_empty():
			count += 1
	return count


func _launcher_texture() -> Texture2D:
	for skill_id in skill_ids:
		if SkillCatalog.has(str(skill_id)):
			return SkillCatalog.skill(str(skill_id)).get("icon")
	return null


func _launcher_color(skills: Node2D, elapsed: float) -> Color:
	if skills == null:
		return Color.WHITE
	for skill_id in skill_ids:
		if not str(skill_id).is_empty() and skills.is_flashing(str(skill_id), elapsed):
			return UiFactory.ACCENT_LIGHT
	return Color.WHITE


func _row_icon_color(skills: Node2D, skill_id: String, level: int, elapsed: float) -> Color:
	if skill_id.is_empty() or level <= 0:
		return Color(UiFactory.MUTED_INK, 0.28)
	return UiFactory.ACCENT_LIGHT if skills != null and skills.is_flashing(skill_id, elapsed) else Color.WHITE


func _skill_name(skill_id: String) -> String:
	return str(SkillCatalog.skill(skill_id).get("name", "待解锁槽位")) if SkillCatalog.has(skill_id) else "待解锁槽位"


func _badge(skill_id: String, level: int) -> String:
	if skill_id.is_empty() or level <= 0:
		return "—"
	return ChoiceFactory.roman(mini(level, int(SkillCatalog.skill(skill_id)["max_level"])))


func _cooldown(skills: Node2D, skill_id: String) -> float:
	return skills.cooldown_progress(skill_id) if skills != null and not skill_id.is_empty() else 0.0


func _launcher_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 36
	style.corner_radius_top_right = 36
	style.corner_radius_bottom_left = 36
	style.corner_radius_bottom_right = 36
	style.shadow_color = Color(UiFactory.INK, 0.24)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style
