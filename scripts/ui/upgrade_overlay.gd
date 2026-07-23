extends CanvasLayer

signal choice_selected(choice_id: String)
signal reroll_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const FLOOR_TEXTURE := preload("res://assets/art/environment/celestial_floor.png")
const HEART_ICON := preload("res://assets/art/pickups/healing_heart.png")

var title: Label
var buttons: Array[Button] = []
var screen_overlay: ColorRect
var design_frame: Control
var reroll_button: Button


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
	reroll_button = Button.new()
	reroll_button.position = Vector2(140, 808)
	reroll_button.size = Vector2(260, 56)
	reroll_button.add_theme_font_size_override("font_size", 18)
	UiFactory.apply_glass_button(reroll_button, false, UiFactory.GOLD)
	reroll_button.pressed.connect(reroll_requested.emit)
	design_frame.add_child(reroll_button)
	visible = false


func show_choices(player_level: int, choices: Array, upgrade_system: RefCounted, build_state: RefCounted) -> void:
	title.text = "等级 %d · 星辉赐福" % player_level
	for index in range(3):
		var button := buttons[index]
		if index >= choices.size():
			button.visible = false
			continue
		var choice: Dictionary = choices[index]
		button.visible = true
		button.text = upgrade_system.choice_text(choice)
		button.icon = _choice_icon(choice)
		button.set_meta("choice_id", choice["choice_key"])
		var highlighted: bool = int(choice.get("target_level", 0)) >= 3 or str(choice["kind"]) == "skill_branch"
		UiFactory.apply_glass_button(button, highlighted, UiFactory.GOLD if highlighted else UiFactory.STROKE)
	reroll_button.disabled = int(build_state.rerolls_remaining) <= 0
	reroll_button.text = "重抽本组选项 · 剩余 %d 次" % int(build_state.rerolls_remaining)
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


func _choice_icon(choice: Dictionary) -> Texture2D:
	var content_id := str(choice["content_id"])
	if str(choice["kind"]) == "relic_upgrade":
		return RelicCatalog.icon(content_id)
	if SkillCatalog.has(content_id):
		return SkillCatalog.skill(content_id)["icon"]
	return HEART_ICON
