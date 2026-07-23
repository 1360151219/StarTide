extends Control

signal level_selected(level_id: String)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const LevelPresentationCatalog = preload("res://scripts/levels/level_presentation_catalog.gd")
const SwipeGesture = preload("res://scripts/ui/swipe_gesture.gd")
const SLOT_OFFSETS := [-1, 0, 1]
const CARD_SIZE := Vector2(160, 160)
const CARD_CENTER_X := 172.0
const CARD_STEP := 344.0

var records: RefCounted
var levels: Array[LevelConfig] = []
var selected_level_id := ""
var current_index := 0
var page_buttons: Array[TextureButton] = []
var title_labels: Array[Label] = []
var left_button: Button
var right_button: Button
var page_label: Label
var detail_label: Label
var _built := false
var swipe_gesture := SwipeGesture.new()
var _transition_tween: Tween


func configure(level_configs: Array[LevelConfig], run_records: RefCounted, initial_level_id: String) -> void:
	levels = level_configs
	records = run_records
	if not _built:
		_build()
	if levels.is_empty():
		selected_level_id = ""
		current_index = 0
		refresh()
		return
	var requested_index := _index_of(initial_level_id)
	current_index = requested_index if requested_index >= 0 and records.is_level_unlocked(initial_level_id) else 0
	selected_level_id = levels[current_index].level_id
	refresh()


func select_level(level_id: String, emit_change := true) -> void:
	var target_index := _index_of(level_id)
	if target_index < 0:
		return
	_stop_transition()
	current_index = target_index
	selected_level_id = level_id
	refresh()
	if emit_change:
		level_selected.emit(level_id)


func move_by(direction: int) -> void:
	if levels.is_empty() or direction == 0:
		return
	var target_index := clampi(current_index + signi(direction), 0, levels.size() - 1)
	if target_index == current_index:
		return
	_stop_transition()
	var normalized_direction := signi(target_index - current_index)
	current_index = target_index
	selected_level_id = levels[current_index].level_id
	_render_slots()
	_update_navigation()
	_animate_slots(normalized_direction)
	level_selected.emit(selected_level_id)


func refresh() -> void:
	_render_slots()
	_update_navigation()


func is_selected_unlocked() -> bool:
	return not selected_level_id.is_empty() and records.is_level_unlocked(selected_level_id)


func _build() -> void:
	_built = true
	size = Vector2(504, 194)
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	for slot_index in range(SLOT_OFFSETS.size()):
		_build_page(slot_index)
	left_button = _build_arrow("◀", Vector2(8, 52))
	left_button.pressed.connect(move_by.bind(-1))
	right_button = _build_arrow("▶", Vector2(442, 52))
	right_button.pressed.connect(move_by.bind(1))
	page_label = UiFactory.label("", 13, Color("fff0b4"))
	page_label.position = Vector2(172, 151)
	page_label.size = Vector2(160, 20)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_label.z_index = 6
	add_child(page_label)
	detail_label = UiFactory.label("", 13, Color("e9f8ef"))
	detail_label.position = Vector2(4, 173)
	detail_label.size = Vector2(496, 21)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.clip_text = true
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_label.z_index = 6
	add_child(detail_label)
	gui_input.connect(_handle_pointer_input)


func _build_page(slot_index: int) -> void:
	var button := TextureButton.new()
	button.size = CARD_SIZE
	button.pivot_offset = CARD_SIZE * 0.5
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_page_pressed.bind(slot_index))
	button.gui_input.connect(_handle_pointer_input)
	add_child(button)
	page_buttons.append(button)
	var title := UiFactory.label("", 14, Color("2b2f2f"))
	title.position = Vector2(26, 127)
	title.size = Vector2(108, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)
	title_labels.append(title)


func _build_arrow(caption: String, at: Vector2) -> Button:
	var button := Button.new()
	button.position = at
	button.size = Vector2(54, 54)
	button.text = caption
	button.add_theme_font_size_override("font_size", 22)
	button.z_index = 7
	UiFactory.apply_glass_button(button, false, UiFactory.GOLD)
	add_child(button)
	return button


func _render_slots() -> void:
	for slot_index in range(page_buttons.size()):
		var offset: int = SLOT_OFFSETS[slot_index]
		var level_index := current_index + offset
		var button := page_buttons[slot_index]
		button.position = Vector2(CARD_CENTER_X + offset * CARD_STEP, 0)
		if level_index < 0 or level_index >= levels.size():
			button.visible = false
			button.focus_mode = Control.FOCUS_NONE
			button.set_meta("level_id", "")
			continue
		var level := levels[level_index]
		var presentation := LevelPresentationCatalog.by_id(level.level_id)
		button.visible = offset == 0
		button.focus_mode = Control.FOCUS_ALL if offset == 0 else Control.FOCUS_NONE
		button.set_meta("level_id", level.level_id)
		button.texture_normal = presentation.medallion_texture if presentation != null else null
		button.texture_hover = button.texture_normal
		button.texture_pressed = button.texture_normal
		button.self_modulate = Color.WHITE if offset == 0 else Color(0.74, 0.8, 0.82, 0.9)
		title_labels[slot_index].text = level.display_name
		button.tooltip_text = "%s · %s" % [level.display_name, level.subtitle]


func _update_navigation() -> void:
	var has_levels := not levels.is_empty()
	left_button.disabled = not has_levels or current_index <= 0
	right_button.disabled = not has_levels or current_index >= levels.size() - 1
	if not has_levels:
		page_label.text = "暂无关卡"
		detail_label.text = ""
		return
	var selected := levels[current_index]
	var unlocked: bool = records.is_level_unlocked(selected.level_id)
	page_label.text = "第 %d / %d 关" % [current_index + 1, levels.size()]
	var progress_text: String = records.level_summary(selected.level_id)
	if unlocked:
		detail_label.text = "%s  ·  首通奖励：%s" % [progress_text, selected.reward.display_name]
	else:
		detail_label.text = "◇ 尚未解锁  ·  首通奖励：%s" % selected.reward.display_name
	detail_label.add_theme_color_override("font_color", Color("e9f8ef") if unlocked else Color("ffe59a"))


func _animate_slots(direction: int) -> void:
	if not is_inside_tree():
		return
	var target_positions: Array[Vector2] = []
	for slot_index in range(page_buttons.size()):
		var button := page_buttons[slot_index]
		target_positions.append(button.position)
		button.position.x += direction * CARD_STEP
		button.visible = slot_index == 1 or slot_index == (0 if direction > 0 else 2)
	_transition_tween = create_tween().set_parallel(true)
	_transition_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for slot_index in range(page_buttons.size()):
		_transition_tween.tween_property(page_buttons[slot_index], "position", target_positions[slot_index], 0.2)
	_transition_tween.chain().tween_callback(_finish_transition)


func _finish_transition() -> void:
	for slot_index in range(page_buttons.size()):
		page_buttons[slot_index].visible = slot_index == 1
		page_buttons[slot_index].focus_mode = Control.FOCUS_ALL if slot_index == 1 else Control.FOCUS_NONE
	_transition_tween = null


func _stop_transition() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null


func _on_page_pressed(slot_index: int) -> void:
	var level_id: String = page_buttons[slot_index].get_meta("level_id", "")
	if not level_id.is_empty() and level_id != selected_level_id:
		select_level(level_id)


func _handle_pointer_input(event: InputEvent) -> void:
	var direction := swipe_gesture.handle(event)
	if direction == 0:
		return
	move_by(direction)
	accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_LEFT:
		move_by(-1)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_RIGHT:
		move_by(1)
		get_viewport().set_input_as_handled()


func _index_of(level_id: String) -> int:
	for index in range(levels.size()):
		if levels[index].level_id == level_id:
			return index
	return -1
