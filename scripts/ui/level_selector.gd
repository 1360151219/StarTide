extends Control

signal level_selected(level_id: String)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SwipeGesture = preload("res://scripts/ui/swipe_gesture.gd")
const Widgets = preload("res://scripts/ui/level_selector_widgets.gd")
const ExpeditionBrief = preload("res://scripts/ui/expedition_brief.gd")
const SLOT_OFFSETS := [-1, 0, 1]
const CARD_CENTER_X := 80.0
const CARD_STEP := 384.0
const MAX_VISIBLE_DOTS := 7
const BRIEF_X := 61.5

var records: RefCounted
var levels: Array[LevelConfig] = []
var selected_level_id := ""
var current_index := 0
var page_buttons: Array[TextureButton] = []
var page_dots: Array[Button] = []
var left_button: Button
var right_button: Button
var page_label: Label
var detail_label: Label
var information_plate: Control
var expedition_brief: Control
var dots_row: HBoxContainer
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
		_rebuild_dots()
		refresh()
		return
	var requested_index := _index_of(initial_level_id)
	current_index = requested_index if requested_index >= 0 and records.is_level_unlocked(initial_level_id) else 0
	selected_level_id = levels[current_index].level_id
	_rebuild_dots()
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
	size = Vector2(504, 138)
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	for slot_index in range(SLOT_OFFSETS.size()):
		page_buttons.append(Widgets.add_page(self, slot_index, _on_page_pressed, _handle_pointer_input))
	var chrome := Widgets.add_chrome(self)
	page_label = chrome["page_label"]
	page_label.visible = false
	dots_row = chrome["dots"]
	expedition_brief = ExpeditionBrief.new()
	expedition_brief._ensure_built()
	expedition_brief.position = Vector2(BRIEF_X, 0)
	expedition_brief.z_index = 3
	add_child(expedition_brief)
	information_plate = expedition_brief
	detail_label = expedition_brief.current_power_label
	left_button = Widgets.add_arrow(self, "‹", Vector2(2, 22))
	left_button.modulate.a = 0.0
	left_button.pressed.connect(move_by.bind(-1))
	right_button = Widgets.add_arrow(self, "›", Vector2(452, 22))
	right_button.modulate.a = 0.0
	right_button.pressed.connect(move_by.bind(1))
	gui_input.connect(_handle_pointer_input)


func _rebuild_dots() -> void:
	if not is_instance_valid(dots_row):
		return
	for dot in page_dots:
		dot.queue_free()
	page_dots.clear()
	var dot_count := mini(levels.size(), MAX_VISIBLE_DOTS)
	for slot_index in range(dot_count):
		page_dots.append(Widgets.add_dot(dots_row, slot_index, _on_dot_pressed))


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
		button.visible = offset == 0
		button.focus_mode = Control.FOCUS_ALL if offset == 0 else Control.FOCUS_NONE
		button.set_meta("level_id", level.level_id)
		button.tooltip_text = "%s · %s" % [level.display_name, level.subtitle]


func _update_navigation() -> void:
	var has_levels := not levels.is_empty()
	left_button.disabled = not has_levels or current_index <= 0
	right_button.disabled = not has_levels or current_index >= levels.size() - 1
	if not has_levels:
		page_label.text = "暂无关卡"
		detail_label.text = "当前战力  0"
		_update_dots()
		return
	var selected := levels[current_index]
	var unlocked: bool = records.is_level_unlocked(selected.level_id)
	page_label.text = "第 %d / %d 关" % [current_index + 1, levels.size()]
	var active_snapshot: Dictionary = records.get_permanent_snapshot(records.get_active_hero_id())
	var current_power := int(active_snapshot.get("power", {}).get("total", 0))
	var cleared: bool = records.has_cleared_level(selected.level_id)
	expedition_brief.configure(selected, current_power, unlocked, cleared)
	_update_dots()


func _update_dots() -> void:
	if page_dots.is_empty():
		return
	var window_start := clampi(current_index - floori(page_dots.size() * 0.5), 0, maxi(0, levels.size() - page_dots.size()))
	for slot_index in range(page_dots.size()):
		var level_index := window_start + slot_index
		var dot := page_dots[slot_index]
		var selected := level_index == current_index
		dot.set_meta("level_index", level_index)
		dot.text = "●" if selected else "○"
		dot.add_theme_font_size_override("font_size", 17 if selected else 19)
		dot.add_theme_color_override(
			"font_color",
			UiFactory.GOLD if selected else Color("72d8cf")
		)
		dot.accessibility_name = "第%d关%s" % [level_index + 1, "，当前选择" if selected else ""]


func _animate_slots(direction: int) -> void:
	if not is_inside_tree():
		return
	information_plate.position.x = BRIEF_X + direction * 18.0
	information_plate.modulate.a = 0.45
	dots_row.modulate.a = 0.45
	_transition_tween = create_tween().set_parallel(true)
	_transition_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(information_plate, "position:x", BRIEF_X, 0.22)
	_transition_tween.tween_property(information_plate, "modulate:a", 1.0, 0.2)
	_transition_tween.tween_property(dots_row, "modulate:a", 1.0, 0.18)
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


func _on_dot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= page_dots.size():
		return
	var level_index := int(page_dots[slot_index].get_meta("level_index", -1))
	if level_index < 0 or level_index >= levels.size() or level_index == current_index:
		return
	select_level(levels[level_index].level_id)


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
