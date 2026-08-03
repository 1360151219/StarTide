extends Panel

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")

var skill_ids: Array = []
var icons: Array[TextureRect] = []
var badges: Array[Label] = []
var cooldown_bars: Array[ColorRect] = []


func _ready() -> void:
	size = Vector2(286, 88)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiFactory.panel_style(UiFactory.SURFACE, 20.0, UiFactory.GOLD))
	for index in range(3):
		_build_slot(index)


func configure(active_skill_ids: Array) -> void:
	skill_ids = active_skill_ids.duplicate()
	for index in range(3):
		var skill_id := str(skill_ids[index]) if index < skill_ids.size() else ""
		icons[index].texture = SkillCatalog.skill(skill_id).get("icon") if SkillCatalog.has(skill_id) else null


func refresh(skills: Node2D, elapsed: float) -> void:
	if skills.active_skill_ids != skill_ids:
		configure(skills.active_skill_ids)
	for index in range(3):
		var skill_id: String = skill_ids[index]
		if skill_id.is_empty():
			icons[index].modulate = Color(0.3, 0.4, 0.43, 0.28)
			badges[index].text = "＋"
			cooldown_bars[index].size.x = 0.0
			continue
		var skill_level: int = skills.levels[skill_id]
		var color := Color("fff1a8") if skills.is_flashing(skill_id, elapsed) else Color.WHITE
		icons[index].modulate = color if skill_level > 0 else Color(0.38, 0.48, 0.5, 0.38)
		badges[index].text = _badge(skill_level)
		cooldown_bars[index].size.x = 60.0 * skills.cooldown_progress(skill_id)


func _build_slot(index: int) -> void:
	var slot := Panel.new()
	slot.position = Vector2(10 + index * 91, 7)
	slot.size = Vector2(84, 74)
	slot.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.91, 0.97, 0.91, 0.92), 15.0, Color(0.3, 0.7, 0.63, 0.54)))
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slot)
	var icon := TextureRect.new()
	icon.position = Vector2(10, 4)
	icon.size = Vector2(60, 58)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	icons.append(icon)
	var badge := UiFactory.surface_label("—", 12, UiFactory.PRIMARY_DARK)
	badge.position = Vector2(56, 43)
	badge.size = Vector2(25, 22)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(badge)
	badges.append(badge)
	var background := ColorRect.new()
	background.position = Vector2(10, 66)
	background.size = Vector2(60, 5)
	background.color = Color(UiFactory.MUTED_INK, 0.24)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(background)
	var fill := ColorRect.new()
	fill.size = Vector2(0, 5)
	fill.color = UiFactory.PRIMARY
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(fill)
	cooldown_bars.append(fill)


func _badge(level: int) -> String:
	if level <= 0:
		return "—"
	if level >= 3:
		return "MAX"
	return ["", "I", "II"][level]
