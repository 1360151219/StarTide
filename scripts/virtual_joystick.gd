extends Control

var value := Vector2.ZERO
var touch_id := -1
var dragging_mouse := false
var knob_position := Vector2.ZERO
const MAX_DISTANCE := 58.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	knob_position = size * 0.5


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and touch_id < 0 and not dragging_mouse:
		knob_position = size * 0.5
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id < 0:
			touch_id = event.index
			_update_value(event.position)
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			_reset()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_update_value(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging_mouse = event.pressed
		if dragging_mouse:
			_update_value(event.position)
		else:
			_reset()
	elif event is InputEventMouseMotion and dragging_mouse:
		_update_value(event.position)


func _update_value(local_position: Vector2) -> void:
	var center := size * 0.5
	var offset := local_position - center
	value = offset.limit_length(MAX_DISTANCE) / MAX_DISTANCE
	knob_position = center + value * MAX_DISTANCE
	queue_redraw()


func _reset() -> void:
	value = Vector2.ZERO
	knob_position = size * 0.5
	queue_redraw()


func cancel_input() -> void:
	touch_id = -1
	dragging_mouse = false
	_reset()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 71.0, Color(0.025, 0.045, 0.13, 0.58))
	draw_arc(center, 71.0, 0.0, TAU, 64, Color(0.83, 0.67, 0.3, 0.52), 3.0)
	draw_arc(center, 57.0, 0.0, TAU, 48, Color(0.33, 0.82, 0.93, 0.25), 1.5)
	for index in range(4):
		var direction := Vector2.from_angle(index * PI * 0.5)
		draw_circle(center + direction * 62.0, 3.5, Color("f6d782"))
	draw_line(center + Vector2(-40, 0), center + Vector2(40, 0), Color(0.4, 0.82, 0.9, 0.12), 1.0)
	draw_line(center + Vector2(0, -40), center + Vector2(0, 40), Color(0.4, 0.82, 0.9, 0.12), 1.0)
	draw_circle(knob_position, 31.0, Color(0.08, 0.17, 0.34, 0.92))
	draw_arc(knob_position, 31.0, 0.0, TAU, 36, Color("6fe9f5"), 2.5)
	var star := PackedVector2Array()
	for index in range(8):
		var star_radius := 13.0 if index % 2 == 0 else 5.0
		star.append(knob_position + Vector2.from_angle(-PI * 0.5 + index * PI * 0.25) * star_radius)
	draw_colored_polygon(star, Color("f6d782"))
