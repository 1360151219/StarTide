extends CanvasLayer

signal choice_selected(choice_id: String)
signal reroll_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const UpgradeChoiceCard = preload("res://scripts/ui/upgrade_choice_card.gd")
const UpgradeChoicePresenter = preload("res://scripts/ui/upgrade_choice_presenter.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const UpgradeHeaderOrnament = preload("res://scripts/ui/upgrade_header_ornament.gd")

const INK := UiFactory.INK
const MUTED_INK := UiFactory.MUTED_INK
const AMBER := UiFactory.ACCENT_DARK

var title: Label
var buttons: Array[Button] = []
var choice_views: Array[Dictionary] = []
var choice_cards: Array = []
var screen_overlay: ColorRect
var design_frame: Control
var reroll_button: Button
var title_panel: Panel
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
	for index in range(3):
		_build_choice_card(index)
	_build_footer()
	visible = false


func show_choices(player_level: int, choices: Array, upgrade_system: RefCounted, build_state: RefCounted) -> void:
	if selection_tween != null and selection_tween.is_valid():
		selection_tween.kill()
	selection_locked = false
	pending_choice_id = ""
	title.text = "Lv.%d" % player_level
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
	var rerolls := int(build_state.rerolls_remaining)
	current_rerolls = rerolls
	reroll_button.disabled = rerolls <= 0
	reroll_button.scale = Vector2.ONE
	reroll_button.text = "重绘选项 · %d" % rerolls
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


func _build_heading() -> void:
	title_panel = Panel.new()
	title_panel.position = Vector2(52, 64)
	title_panel.size = Vector2(436, 98)
	title_panel.pivot_offset = title_panel.size * 0.5
	SunlitCardStyle.apply_panel(title_panel, Color(UiFactory.SURFACE, 0.97), Color("9b7544"), 20.0, true, false, "map_tag")
	design_frame.add_child(title_panel)
	var ornament := UpgradeHeaderOrnament.new()
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_panel.add_child(ornament)
	var level_plate := Panel.new()
	level_plate.position = Vector2(151, 15)
	level_plate.size = Vector2(134, 70)
	SunlitCardStyle.apply_panel(level_plate, UiFactory.HUD_SURFACE_ALT, UiFactory.ACCENT, 8.0, true, true, "enamel", 2)
	title_panel.add_child(level_plate)
	title = _surface_label("Lv.1", 28, UiFactory.HUD_TEXT)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_plate.add_child(title)
	var heading := _surface_label("远征强化", 18, INK)
	heading.position = Vector2(20, 32)
	heading.size = Vector2(120, 32)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_panel.add_child(heading)
	var hint := _surface_label("选择 1 项", 16, MUTED_INK)
	hint.position = Vector2(296, 34)
	hint.size = Vector2(120, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_panel.add_child(hint)


func _build_choice_card(index: int) -> void:
	var card := UpgradeChoiceCard.new()
	card.configure(index)
	card.pivot_offset = card.size * 0.5
	card.pressed.connect(_select.bind(card))
	design_frame.add_child(card)
	choice_cards.append(card)
	buttons.append(card)
	choice_views.append(card.views)


func _build_footer() -> void:
	var footer := Panel.new()
	footer.position = Vector2(125, 774)
	footer.size = Vector2(290, 80)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SunlitCardStyle.apply_panel(footer, Color(UiFactory.SURFACE, 0.96), Color(UiFactory.PRIMARY, 0.7), 8.0, false, true, "ribbon")
	design_frame.add_child(footer)
	reroll_button = Button.new()
	reroll_button.position = Vector2(155, 786)
	reroll_button.size = Vector2(230, 56)
	reroll_button.add_theme_font_size_override("font_size", 17)
	reroll_button.add_theme_constant_override("outline_size", 0)
	UiFactory.apply_secondary_button(reroll_button)
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
	selection_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	selection_tween.tween_property(button, "scale", Vector2(1.04, 1.04), 0.22)
	for candidate in buttons:
		if candidate != button:
			selection_tween.tween_property(candidate, "modulate:a", 0.34, 0.18)
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
		candidate.scale = Vector2.ONE
		candidate.modulate = Color.WHITE
	reroll_button.disabled = current_rerolls <= 0


func _play_reveal() -> void:
	if reveal_tween != null and reveal_tween.is_valid():
		reveal_tween.kill()
	title_panel.scale = Vector2(0.96, 0.96)
	title_panel.modulate.a = 1.0
	for button in buttons:
		button.modulate.a = 1.0
		button.scale = Vector2.ONE
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
