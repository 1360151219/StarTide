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
	size = Vector2(276, 64)
	add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.025, 0.045, 0.115, 0.86), 16.0, Color(0.38, 0.64, 0.78, 0.5)))
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
		icons[index].modulate = color if skill_level > 0 else Color(0.38, 0.44, 0.58, 0.4)
		badges[index].text = _badge(skill_level)
		cooldown_bars[index].size.x = 48.0 * skills.cooldown_progress(skill_id)


func _build_slot(index: int) -> void:
	var icon := TextureRect.new()
	icon.position = Vector2(13 + index * 88, 8)
	icon.size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(icon)
	icons.append(icon)
	var badge := UiFactory.label("—", 14, Color("fff0a8"))
	badge.position = Vector2(53 + index * 88, 35)
	badge.size = Vector2(32, 22)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(badge)
	badges.append(badge)
	var background := ColorRect.new()
	background.position = Vector2(13 + index * 88, 56)
	background.size = Vector2(48, 4)
	background.color = Color(0.05, 0.08, 0.15, 0.92)
	add_child(background)
	var fill := ColorRect.new()
	fill.size = Vector2(0, 4)
	fill.color = Color("f6d782")
	background.add_child(fill)
	cooldown_bars.append(fill)


func _badge(level: int) -> String:
	if level <= 0:
		return "—"
	if level >= 3:
		return "MAX"
	return ["", "I", "II"][level]
