extends Panel

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ICONS := {
	"star_lance": preload("res://assets/art/skills/star_lance.png"),
	"sun_orbit": preload("res://assets/art/skills/sun_orbit.png"),
	"frost_tide": preload("res://assets/art/skills/frost_tide.png"),
	"ember_volley": preload("res://assets/art/skills/ember_volley.png"),
	"meteor_rain": preload("res://assets/art/skills/meteor_rain.png"),
	"phoenix_heart": preload("res://assets/art/skills/phoenix_heart.png"),
}

var skill_ids: Array = []
var icons: Array[TextureRect] = []
var badges: Array[Label] = []
var cooldown_bars: Array[ColorRect] = []


func _ready() -> void:
	size = Vector2(210, 62)
	add_theme_stylebox_override("panel", UiFactory.panel_style(UiFactory.GLASS, 15.0, UiFactory.GOLD))
	for index in range(3):
		_build_slot(index)


func configure(active_skill_ids: Array) -> void:
	skill_ids = active_skill_ids.duplicate()
	for index in range(3):
		icons[index].texture = ICONS[skill_ids[index]]


func refresh(skills: Node2D, elapsed: float) -> void:
	for index in range(skill_ids.size()):
		var skill_id: String = skill_ids[index]
		var skill_level: int = skills.levels[skill_id]
		var color := Color("fff1a8") if skills.is_flashing(skill_id, elapsed) else Color.WHITE
		icons[index].modulate = color if skill_level > 0 else Color(0.38, 0.48, 0.5, 0.38)
		badges[index].text = _badge(skill_level)
		cooldown_bars[index].size.x = 42.0 * skills.cooldown_progress(skill_id)


func _build_slot(index: int) -> void:
	var icon := TextureRect.new()
	icon.position = Vector2(10 + index * 66, 8)
	icon.size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(icon)
	icons.append(icon)
	var badge := UiFactory.label("—", 12, UiFactory.PALE)
	badge.position = Vector2(38 + index * 66, 31)
	badge.size = Vector2(27, 20)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(badge)
	badges.append(badge)
	var background := ColorRect.new()
	background.position = Vector2(10 + index * 66, 54)
	background.size = Vector2(42, 4)
	background.color = Color(0.22, 0.38, 0.41, 0.28)
	add_child(background)
	var fill := ColorRect.new()
	fill.size = Vector2(0, 4)
	fill.color = UiFactory.GOLD
	background.add_child(fill)
	cooldown_bars.append(fill)


func _badge(level: int) -> String:
	if level <= 0:
		return "—"
	if level >= 3:
		return "MAX"
	return ["", "I", "II"][level]
