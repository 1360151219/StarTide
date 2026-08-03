extends CanvasLayer

signal choice_selected(choice_id: String)
signal reroll_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const UpgradeChoiceCard = preload("res://scripts/ui/upgrade_choice_card.gd")
const UpgradeChoicePresenter = preload("res://scripts/ui/upgrade_choice_presenter.gd")
const FLOOR_TEXTURE := preload("res://assets/art/environment/celestial_floor.png")

const INK := Color(0.07, 0.2, 0.24, 1.0)
const MUTED_INK := Color(0.25, 0.39, 0.42, 1.0)
const AMBER := Color(1.0, 0.67, 0.2, 1.0)

var title: Label
var buttons: Array[Button] = []
var choice_views: Array[Dictionary] = []
var choice_cards: Array = []
var screen_overlay: ColorRect
var design_frame: Control
var reroll_button: Button
var title_panel: Panel
var reveal_tween: Tween


func _ready() -> void:
	layer = 35
	_build_background()
	design_frame = DesignFrame.new()
	screen_overlay.add_child(design_frame)
	_build_heading()
	for index in range(3):
		_build_choice_card(index)
	_build_footer()
	visible = false


func show_choices(player_level: int, choices: Array, upgrade_system: RefCounted, build_state: RefCounted) -> void:
	title.text = "Lv.%d" % player_level
	for index in range(3):
		var card = choice_cards[index]
		if index >= choices.size():
			card.visible = false
			continue
		var choice := UpgradeChoicePresenter.normalize(choices[index], upgrade_system)
		card.visible = true
		card.present(choice, UpgradeChoicePresenter.view_model(choice))
	var rerolls := int(build_state.rerolls_remaining)
	reroll_button.disabled = rerolls <= 0
	reroll_button.text = "↻  重绘 · %d" % rerolls
	reroll_button.tooltip_text = "重绘本组强化，剩余 %d 次" % rerolls
	reroll_button.accessibility_description = reroll_button.tooltip_text
	visible = true
	_play_reveal()


func _build_background() -> void:
	screen_overlay = ColorRect.new()
	screen_overlay.color = Color(0.006, 0.07, 0.09, 0.72)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_overlay)
	ScreenLayout.fill(screen_overlay)
	var backdrop := TextureRect.new()
	backdrop.texture = FLOOR_TEXTURE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.34, 0.72, 0.68, 0.12)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_overlay.add_child(backdrop)
	ScreenLayout.fill(backdrop)


func _build_heading() -> void:
	title_panel = Panel.new()
	title_panel.position = Vector2(44, 48)
	title_panel.size = Vector2(452, 108)
	title_panel.pivot_offset = title_panel.size * 0.5
	title_panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(1.0, 0.97, 0.84, 0.96), 25.0, UiFactory.GOLD))
	design_frame.add_child(title_panel)
	var level_plate := Panel.new()
	level_plate.position = Vector2(20, 18)
	level_plate.size = Vector2(96, 72)
	level_plate.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.05, 0.37, 0.42, 0.98), 20.0, Color(0.34, 0.8, 0.72, 0.96)))
	title_panel.add_child(level_plate)
	title = _surface_label("Lv.1", 22, UiFactory.CREAM)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_plate.add_child(title)
	var heading := _surface_label("星辉赐福", 29, INK)
	heading.position = Vector2(136, 18)
	heading.size = Vector2(234, 38)
	title_panel.add_child(heading)
	var hint := _surface_label("选择 1 项强化", 16, MUTED_INK)
	hint.position = Vector2(136, 58)
	hint.size = Vector2(234, 26)
	title_panel.add_child(hint)
	_add_crest("✦", Vector2(380, 30))


func _add_crest(text: String, at: Vector2) -> void:
	var crest := _surface_label(text, 32, AMBER)
	crest.position = at
	crest.size = Vector2(48, 48)
	crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crest.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_panel.add_child(crest)


func _build_choice_card(index: int) -> void:
	var card := UpgradeChoiceCard.new()
	card.configure(index)
	card.pressed.connect(_select.bind(card))
	design_frame.add_child(card)
	choice_cards.append(card)
	buttons.append(card)
	choice_views.append(card.views)


func _build_footer() -> void:
	var footer := Panel.new()
	footer.position = Vector2(30, 752)
	footer.size = Vector2(480, 106)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.025, 0.19, 0.22, 0.94), 22.0, Color(0.31, 0.76, 0.7, 0.78)))
	design_frame.add_child(footer)
	reroll_button = Button.new()
	reroll_button.position = Vector2(140, 776)
	reroll_button.size = Vector2(276, 58)
	reroll_button.add_theme_font_size_override("font_size", 17)
	reroll_button.add_theme_constant_override("outline_size", 0)
	reroll_button.add_theme_color_override("font_color", UiFactory.CREAM)
	reroll_button.add_theme_color_override("font_hover_color", Color.WHITE)
	reroll_button.add_theme_color_override("font_pressed_color", UiFactory.CREAM)
	UiFactory.apply_button_styles(reroll_button, Color(0.05, 0.37, 0.42, 0.98), Color(0.34, 0.8, 0.72, 0.96))
	reroll_button.pressed.connect(reroll_requested.emit)
	design_frame.add_child(reroll_button)


func _select(button: Button) -> void:
	choice_selected.emit(button.get_meta("choice_id"))


func _play_reveal() -> void:
	if reveal_tween != null and reveal_tween.is_valid():
		reveal_tween.kill()
	title_panel.scale = Vector2(0.96, 0.96)
	title_panel.modulate.a = 1.0
	for button in buttons:
		button.modulate.a = 1.0
		button.position.x = 38.0
	reveal_tween = create_tween().set_parallel(true)
	reveal_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(title_panel, "scale", Vector2.ONE, 0.24)
	for index in range(buttons.size()):
		reveal_tween.tween_property(buttons[index], "position:x", 30.0, 0.22).set_delay(0.05 + index * 0.05)


func _surface_label(text: String, font_size: int, color: Color) -> Label:
	var node := UiFactory.label(text, font_size, color)
	node.add_theme_constant_override("outline_size", 0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
