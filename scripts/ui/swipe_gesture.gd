extends RefCounted

const THRESHOLD := 54.0
const DOMINANCE := 1.2

var pointer := -1
var origin := Vector2.ZERO
var current := Vector2.ZERO


func handle(event: InputEvent) -> int:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin(event.index, event.position)
		elif event.index == pointer:
			return _finish(event.position)
	elif event is InputEventScreenDrag and event.index == pointer:
		current = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin(0, event.position)
		elif pointer == 0:
			return _finish(event.position)
	elif event is InputEventMouseMotion and pointer == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		current = event.position
	return 0


func _begin(pointer_id: int, at: Vector2) -> void:
	pointer = pointer_id
	origin = at
	current = at


func _finish(at: Vector2) -> int:
	current = at
	var distance := current - origin
	pointer = -1
	if absf(distance.x) < THRESHOLD or absf(distance.x) < absf(distance.y) * DOMINANCE:
		return 0
	return 1 if distance.x < 0.0 else -1
