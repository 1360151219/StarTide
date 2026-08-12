extends Control

var value := Vector2.ZERO
var touch_id := -1
var dragging_mouse := false
var knob_position := Vector2.ZERO
var base_position := Vector2.ZERO
var drag_origin := Vector2.ZERO
var active := false
var fade_time := 0.0
const MAX_DISTANCE := 58.0
const EDGE_MARGIN := 78.0
const RELEASE_FADE_DURATION := 0.16


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_reset()
	set_process(false)


func _process(delta: float) -> void:
	fade_time = maxf(0.0, fade_time - delta)
	queue_redraw()
	if fade_time <= 0.0:
		set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and touch_id < 0 and not dragging_mouse:
		_reset()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id < 0:
			touch_id = event.index
			_begin_input(event.position)
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			_release_input()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_update_value(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging_mouse = event.pressed
		if dragging_mouse:
			_begin_input(event.position)
		else:
			_release_input()
	elif event is InputEventMouseMotion and dragging_mouse:
		_update_value(event.position)


func _update_value(local_position: Vector2) -> void:
	var offset := local_position - drag_origin
	value = offset.limit_length(MAX_DISTANCE) / MAX_DISTANCE
	knob_position = base_position + value * MAX_DISTANCE
	queue_redraw()


func _begin_input(local_position: Vector2) -> void:
	base_position = Vector2(
		clampf(local_position.x, EDGE_MARGIN, size.x - EDGE_MARGIN),
		clampf(local_position.y, EDGE_MARGIN, size.y - EDGE_MARGIN)
	)
	drag_origin = local_position
	knob_position = base_position
	value = Vector2.ZERO
	active = true
	fade_time = 0.0
	set_process(false)
	queue_redraw()


func _release_input() -> void:
	value = Vector2.ZERO
	knob_position = base_position
	active = false
	fade_time = RELEASE_FADE_DURATION
	set_process(true)
	queue_redraw()


func _reset() -> void:
	value = Vector2.ZERO
	base_position = Vector2(108.0, maxf(92.0, size.y - 130.0))
	drag_origin = base_position
	knob_position = base_position
	active = false
	fade_time = 0.0
	queue_redraw()


func cancel_input() -> void:
	touch_id = -1
	dragging_mouse = false
	_reset()


func _draw() -> void:
	var visual_alpha := 1.0 if active else fade_time / RELEASE_FADE_DURATION
	if visual_alpha <= 0.001:
		return
	var center := base_position
	draw_circle(center, 71.0, Color(0.14, 0.31, 0.32, 0.42 * visual_alpha))
	draw_arc(center, 71.0, 0.0, TAU, 64, Color(0.31, 0.65, 0.71, 0.84 * visual_alpha), 3.0)
	draw_arc(center, 57.0, 0.0, TAU, 48, Color(1.0, 0.96, 0.89, 0.52 * visual_alpha), 1.5)
	for index in range(4):
		var direction := Vector2.from_angle(index * PI * 0.5)
		draw_circle(center + direction * 62.0, 3.5, Color(0.95, 0.72, 0.29, visual_alpha))
	draw_line(center + Vector2(-40, 0), center + Vector2(40, 0), Color(1.0, 0.96, 0.89, 0.2 * visual_alpha), 1.0)
	draw_line(center + Vector2(0, -40), center + Vector2(0, 40), Color(1.0, 0.96, 0.89, 0.2 * visual_alpha), 1.0)
	draw_circle(knob_position, 31.0, Color(0.31, 0.65, 0.71, 0.92 * visual_alpha))
	draw_arc(knob_position, 31.0, 0.0, TAU, 36, Color(1.0, 0.96, 0.89, visual_alpha), 2.5)
	var compass := PackedVector2Array()
	for index in range(8):
		var compass_radius := 13.0 if index % 2 == 0 else 4.5
		compass.append(knob_position + Vector2.from_angle(-PI * 0.5 + index * PI * 0.25) * compass_radius)
	draw_colored_polygon(compass, Color(0.95, 0.72, 0.29, visual_alpha))
