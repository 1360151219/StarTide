extends CanvasLayer

signal choice_selected(choice_id: String)
signal reroll_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const UpgradeChoiceCard = preload("res://scripts/ui/upgrade_choice_card.gd")
const UpgradeChoicePresenter = preload("res://scripts/ui/upgrade_choice_presenter.gd")
const TITLE_BANNER := preload("res://assets/art/ui/upgrade/upgrade_title_banner.png")
const LEVEL_MEDALLION := preload("res://assets/art/ui/upgrade/upgrade_level_medallion.png")
const CHOICE_BOARD := preload("res://assets/art/ui/upgrade/upgrade_choice_board.png")
const REROLL_FRAME := preload("res://assets/art/ui/upgrade/upgrade_reroll_frame.png")

var title: Label
var buttons: Array[Button] = []
var choice_cards: Array = []
var screen_overlay: ColorRect
var design_frame: Control
var reroll_button: Button
var title_panel: TextureRect
var level_plate: TextureRect
var choice_board: TextureRect
var reveal_tween: Tween
var selection_tween: Tween
var selection_locked := false
var pending_choice_id := ""
var current_rerolls := 0


func _ready() -> void:
	layer = 35
	_build_background()
	design_frame = DesignFrame.new()
	screen_overlay.add_child(design_frame)
	_build_heading()
	_build_choice_board()
	for index in range(3):
		_build_choice_card(index)
	_build_footer()
	visible = false


func show_choices(player_level: int, choices: Array, upgrade_system: RefCounted, build_state: RefCounted) -> void:
	if selection_tween != null and selection_tween.is_valid():
		selection_tween.kill()
	selection_locked = false
	pending_choice_id = ""
	title.text = "LV.%d" % player_level
	for index in range(3):
		var card = choice_cards[index]
		card.disabled = false
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.focus_mode = Control.FOCUS_ALL
		card.scale = Vector2.ONE
		card.modulate = Color.WHITE
		if index >= choices.size():
			card.visible = false
			continue
		var choice := UpgradeChoicePresenter.normalize(choices[index], upgrade_system)
		card.visible = true
		card.present(choice, UpgradeChoicePresenter.view_model(choice))
	current_rerolls = int(build_state.rerolls_remaining)
	reroll_button.disabled = current_rerolls <= 0
	reroll_button.scale = Vector2.ONE
	reroll_button.text = "重绘选项 · %d" % current_rerolls
	reroll_button.tooltip_text = "重绘本组强化，剩余 %d 次" % current_rerolls
	reroll_button.accessibility_description = reroll_button.tooltip_text
	visible = true
	_play_reveal()


func _build_background() -> void:
	screen_overlay = ColorRect.new()
	screen_overlay.color = Color(0.006, 0.07, 0.09, 0.52)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_overlay)
	ScreenLayout.fill(screen_overlay)


func _build_heading() -> void:
	title_panel = _texture_layer(TITLE_BANNER, Vector2(34, 50), Vector2(472, 142))
	var heading := UiFactory.surface_label("远征强化", 27, UiFactory.INK)
	UiFactory.apply_key_heading(heading, 27, UiFactory.INK)
	heading.position = Vector2(120, 12)
	heading.size = Vector2(232, 40)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_panel.add_child(heading)
	level_plate = _texture_layer(LEVEL_MEDALLION, Vector2(150, 104), Vector2(240, 88))
	level_plate.pivot_offset = level_plate.size * 0.5
	title = UiFactory.surface_label("LV.1", 32, UiFactory.HUD_TEXT)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.offset_left = 26
	title.offset_top = 14
	title.offset_right = -26
	title.offset_bottom = -10
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color(UiFactory.INK, 0.82))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	level_plate.add_child(title)
	var hint := UiFactory.surface_label("选择 1 项", 17, UiFactory.HUD_TEXT)
	hint.position = Vector2(198, 190)
	hint.size = Vector2(144, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	design_frame.add_child(hint)


func _build_choice_board() -> void:
	choice_board = _texture_layer(CHOICE_BOARD, Vector2(22, 192), Vector2(496, 594))


func _build_choice_card(index: int) -> void:
	var card := UpgradeChoiceCard.new()
	card.configure(index)
	card.pivot_offset = card.size * 0.5
	card.pressed.connect(_select.bind(card))
	design_frame.add_child(card)
	choice_cards.append(card)
	buttons.append(card)


func _build_footer() -> void:
	_texture_layer(REROLL_FRAME, Vector2(118, 844), Vector2(304, 72))
	reroll_button = Button.new()
	reroll_button.position = Vector2(151, 852)
	reroll_button.size = Vector2(238, 54)
	reroll_button.add_theme_font_size_override("font_size", 17)
	reroll_button.add_theme_constant_override("outline_size", 0)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		reroll_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	reroll_button.add_theme_color_override("font_color", UiFactory.INK)
	reroll_button.add_theme_color_override("font_hover_color", UiFactory.PRIMARY_DARK)
	reroll_button.add_theme_color_override("font_pressed_color", UiFactory.INK)
	reroll_button.add_theme_color_override("font_disabled_color", Color(UiFactory.MUTED_INK, 0.66))
	reroll_button.pressed.connect(reroll_requested.emit)
	design_frame.add_child(reroll_button)


func _select(button: Button) -> void:
	if selection_locked:
		return
	selection_locked = true
	pending_choice_id = str(button.get_meta("choice_id"))
	for candidate in buttons:
		candidate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		candidate.focus_mode = Control.FOCUS_NONE
		candidate.release_focus()
	reroll_button.disabled = true
	if selection_tween != null and selection_tween.is_valid():
		selection_tween.kill()
	selection_tween = create_tween().set_parallel(true)
	selection_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	selection_tween.tween_property(button, "position:y", button.position.y + 2.0, 0.12)
	selection_tween.tween_property(button, "modulate", Color(1.0, 0.93, 0.66, 1.0), 0.16)
	for candidate in buttons:
		if candidate != button:
			selection_tween.tween_property(candidate, "modulate:a", 0.34, 0.16)
	selection_tween.finished.connect(_commit_selection, CONNECT_ONE_SHOT)


func finish_selection() -> void:
	if selection_tween != null and selection_tween.is_valid():
		selection_tween.kill()
	_commit_selection()


func _commit_selection() -> void:
	if pending_choice_id.is_empty():
		return
	var choice_id := pending_choice_id
	pending_choice_id = ""
	choice_selected.emit(choice_id)


func restore_selection() -> void:
	selection_locked = false
	pending_choice_id = ""
	for candidate in buttons:
		candidate.mouse_filter = Control.MOUSE_FILTER_STOP
		candidate.focus_mode = Control.FOCUS_ALL
		candidate.position = candidate.get_meta("rest_position", candidate.position)
		candidate.scale = Vector2.ONE
		candidate.modulate = Color.WHITE
	reroll_button.disabled = current_rerolls <= 0


func _play_reveal() -> void:
	if reveal_tween != null and reveal_tween.is_valid():
		reveal_tween.kill()
	title_panel.modulate.a = 1.0
	level_plate.scale = Vector2(0.84, 0.84)
	for button in buttons:
		var rest_position: Vector2 = button.get_meta("rest_position", button.position)
		button.position = rest_position + Vector2(0, 16)
		button.modulate.a = 0.0
		button.scale = Vector2.ONE
	reveal_tween = create_tween().set_parallel(true)
	reveal_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(level_plate, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)
	for index in range(buttons.size()):
		var card := buttons[index]
		var target: Vector2 = card.get_meta("rest_position", card.position - Vector2(0, 16))
		var delay := index * 0.045
		reveal_tween.tween_property(card, "position", target, 0.18).set_delay(delay)
		reveal_tween.tween_property(card, "modulate:a", 1.0, 0.12).set_delay(delay)


func _texture_layer(texture: Texture2D, at: Vector2, extent: Vector2) -> TextureRect:
	var layer := UiFactory.texture_rect(texture, TextureRect.STRETCH_SCALE)
	layer.position = at
	layer.size = extent
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	design_frame.add_child(layer)
	return layer
