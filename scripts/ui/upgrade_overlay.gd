extends CanvasLayer

signal choice_selected(choice_id: String)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const FLOOR_TEXTURE := preload("res://assets/art/environment/celestial_floor.png")
const SKILL_ICONS := {
	"star_lance": preload("res://assets/art/skills/star_lance.png"),
	"sun_orbit": preload("res://assets/art/skills/sun_orbit.png"),
	"frost_tide": preload("res://assets/art/skills/frost_tide.png"),
	"ember_volley": preload("res://assets/art/skills/ember_volley.png"),
	"meteor_rain": preload("res://assets/art/skills/meteor_rain.png"),
	"phoenix_heart": preload("res://assets/art/skills/phoenix_heart.png"),
}
const HEART_ICON := preload("res://assets/art/pickups/healing_heart.png")
const MAGNET_ICON := preload("res://assets/art/pickups/magnet_charm.png")

var title: Label
var buttons: Array[Button] = []
var screen_overlay: ColorRect
var design_frame: Control


func _ready() -> void:
	layer = 35
	screen_overlay = ColorRect.new()
	screen_overlay.color = Color(0.006, 0.04, 0.07, 0.92)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_overlay)
	ScreenLayout.fill(screen_overlay)
	var backdrop := TextureRect.new()
	backdrop.texture = FLOOR_TEXTURE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.34, 0.72, 0.68, 0.14)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_overlay.add_child(backdrop)
	ScreenLayout.fill(backdrop)
	design_frame = DesignFrame.new()
	screen_overlay.add_child(design_frame)
	title = UiFactory.label("成长三选一", 34, UiFactory.PALE)
	title.position = Vector2(30, 80)
	title.size = Vector2(480, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	design_frame.add_child(title)
	var hint := UiFactory.label("选择 1 项强化，打造你的专属流派", 19, UiFactory.PALE_MUTED)
	hint.position = Vector2(30, 132)
	hint.size = Vector2(480, 34)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	design_frame.add_child(hint)
	for index in range(3):
		buttons.append(_build_choice_button(design_frame, index))
	visible = false


func show_choices(player_level: int, choices: Array, upgrade_system: RefCounted, skill_levels: Dictionary) -> void:
	title.text = "等级 %d · 星辉赐福" % player_level
	for index in range(3):
		var choice_id: String = choices[index]
		var button := buttons[index]
		button.text = upgrade_system.choice_text(choice_id, skill_levels)
		button.icon = _choice_icon(choice_id)
		button.set_meta("choice_id", choice_id)
		var ultimate: bool = skill_levels.has(choice_id) and int(skill_levels[choice_id]) + 1 == 3
		UiFactory.apply_glass_button(button, ultimate, UiFactory.GOLD if ultimate else UiFactory.STROKE)
	visible = true


func _build_choice_button(parent: Control, index: int) -> Button:
	var button := Button.new()
	button.position = Vector2(36, 205 + index * 198)
	button.size = Vector2(468, 166)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = true
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_constant_override("icon_max_width", 112)
	button.add_theme_constant_override("h_separation", 22)
	UiFactory.apply_glass_button(button, false, UiFactory.STROKE)
	button.pressed.connect(_select.bind(button))
	parent.add_child(button)
	return button


func _select(button: Button) -> void:
	choice_selected.emit(button.get_meta("choice_id"))


func _choice_icon(choice_id: String) -> Texture2D:
	if SKILL_ICONS.has(choice_id):
		return SKILL_ICONS[choice_id]
	return MAGNET_ICON if choice_id == "swiftness" else HEART_ICON
