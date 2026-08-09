extends CanvasLayer

signal replay_requested
signal home_requested

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const ResultCardSections = preload("res://scripts/ui/result_card_sections.gd")
const ResultRevealAnimator = preload("res://scripts/ui/result_reveal_animator.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")

const CARD_SURFACE := UiFactory.SURFACE
const INK := UiFactory.INK
const MUTED_INK := UiFactory.MUTED_INK
const AMBER := UiFactory.ACCENT
const TEAL := UiFactory.PRIMARY_DARK

var heading: Label
var summary: Label
var screen_overlay: ColorRect
var design_frame: Control
var result_card: Panel
var content_margin: MarginContainer
var content_stack: VBoxContainer
var hero_preview: Panel
var hero_rig: HeroRig2D
var result_state_label: Label
var stat_values: Array[Label] = []
var reward_strip: Control
var build_icons: HBoxContainer
var replay_button: Button
var home_button: Button
var victory_crest: TextureRect
var celebration_stars: Array[Control] = []
var reveal_tween: Tween

var _sections := ResultCardSections.new()


func _ready() -> void:
	layer = 40
	screen_overlay = ColorRect.new()
	screen_overlay.color = Color(0.012, 0.08, 0.1, 0.68)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_overlay)
	ScreenLayout.fill(screen_overlay)
	design_frame = DesignFrame.new()
	screen_overlay.add_child(design_frame)
	_build_result_card()
	replay_button = _add_button(design_frame, "再战一次", Vector2(54, 752), true, replay_requested.emit)
	home_button = _add_button(design_frame, "返回关卡大厅", Vector2(54, 838), false, home_requested.emit)
	visible = false


func show_result(presentation: Dictionary) -> void:
	var won := bool(presentation.get("won", false))
	heading.text = str(presentation.get("heading", "远征结算"))
	heading.add_theme_color_override("font_color", TEAL if won else UiFactory.DANGER_DARK)
	result_state_label.text = "新纪录" if bool(presentation.get("new_record", false)) else ("远征凯旋" if won else "本次未完成")
	result_state_label.add_theme_color_override("font_color", TEAL if won else UiFactory.DANGER_DARK)
	summary.text = str(presentation.get("outcome_hint", ""))
	stat_values[0].text = str(presentation.get("duration_text", "--:--"))
	stat_values[1].text = str(int(presentation.get("kills", 0)))
	stat_values[2].text = "Lv.%d" % int(presentation.get("player_level", 1))
	reward_strip.present(presentation)
	build_icons.present_snapshot(presentation.get("build_snapshot", {}))
	var hero_id := str(presentation.get("hero_id", ""))
	hero_preview.visible = not hero_id.is_empty()
	hero_rig.set_active(hero_preview.visible)
	if hero_preview.visible:
		hero_rig.configure(hero_id, 168.0)
		hero_rig.play_state("victory" if won else "hit", true)
	replay_button.text = "再战一次" if won else "再次出发"
	screen_overlay.color = Color(0.012, 0.08, 0.1, 0.74 if won else 0.8)
	for star in celebration_stars:
		star.visible = won
	victory_crest.visible = won
	visible = true
	_play_reveal(won)


func _build_result_card() -> void:
	result_card = Panel.new()
	result_card.position = Vector2(30, 40)
	result_card.size = Vector2(480, 690)
	result_card.pivot_offset = result_card.size * 0.5
	SunlitCardStyle.apply_panel(result_card, Color(CARD_SURFACE, 0.98), UiFactory.PRIMARY, 12.0, true, false, "canvas")
	design_frame.add_child(result_card)
	content_margin = MarginContainer.new()
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_theme_constant_override("margin_left", 18)
	content_margin.add_theme_constant_override("margin_top", 14)
	content_margin.add_theme_constant_override("margin_right", 18)
	content_margin.add_theme_constant_override("margin_bottom", 14)
	result_card.add_child(content_margin)
	content_stack = VBoxContainer.new()
	content_stack.add_theme_constant_override("separation", 7)
	content_margin.add_child(content_stack)
	content_stack.add_child(_build_state_pill())
	heading = _surface_label("", 30, TEAL)
	heading.custom_minimum_size = Vector2(0, 48)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.clip_text = true
	content_stack.add_child(heading)
	hero_preview = _build_hero_stage()
	content_stack.add_child(hero_preview)
	content_stack.add_child(_build_reward_panel())
	content_stack.add_child(_build_stat_row())
	summary = _surface_label("", 14, MUTED_INK)
	summary.custom_minimum_size = Vector2(0, 42)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.clip_text = true
	content_stack.add_child(summary)
	content_stack.add_child(_build_build_panel())


func _build_state_pill() -> CenterContainer:
	var pill := _sections.build_state_pill()
	result_state_label = _sections.result_state_label
	return pill


func _build_hero_stage() -> Panel:
	var stage := _sections.build_hero_stage()
	hero_rig = _sections.hero_rig
	victory_crest = _sections.victory_crest
	celebration_stars = _sections.celebration_stars
	return stage


func _build_stat_row() -> HBoxContainer:
	var row := _sections.build_stat_row()
	stat_values = _sections.stat_values
	return row


func _build_reward_panel() -> Panel:
	var panel := _sections.build_reward_panel()
	reward_strip = _sections.reward_strip
	return panel


func _build_build_panel() -> Panel:
	var panel := _sections.build_build_panel()
	build_icons = _sections.build_icons
	return panel


func _add_button(parent: Control, text: String, at: Vector2, primary: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.position = at
	button.size = Vector2(432, 68)
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_constant_override("outline_size", 0)
	if primary:
		UiFactory.apply_primary_button(button)
	else:
		UiFactory.apply_secondary_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _play_reveal(won: bool) -> void:
	reveal_tween = ResultRevealAnimator.play(self, reveal_tween, result_card, victory_crest, celebration_stars, content_stack.get_children(), [replay_button, home_button], won)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or reveal_tween == null or not reveal_tween.is_valid() or not reveal_tween.is_running():
		return
	var wants_skip := false
	if event is InputEventScreenTouch:
		wants_skip = event.pressed
	elif event is InputEventMouseButton:
		wants_skip = event.pressed
	elif event is InputEventKey:
		wants_skip = event.pressed
	if not wants_skip:
		return
	finish_reveal()
	get_viewport().set_input_as_handled()


func finish_reveal() -> void:
	if not visible:
		return
	if reveal_tween != null and reveal_tween.is_valid() and reveal_tween.is_running():
		reveal_tween.kill()
	result_card.scale = Vector2.ONE
	for node in content_stack.get_children():
		if node is CanvasItem:
			node.modulate.a = 1.0
	for button in [replay_button, home_button]:
		button.modulate.a = 1.0
		button.disabled = false


func _surface_label(text: String, font_size: int, color: Color) -> Label:
	return _sections.surface_label(text, font_size, color)
