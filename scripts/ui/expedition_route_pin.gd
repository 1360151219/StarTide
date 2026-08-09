extends Button

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var level_id := ""
var biome_id := "windbell_meadow"
var accent := UiFactory.ACCENT
var locked := false
var selected := false
var phase := 0.0


func _ready() -> void:
	size = Vector2(88, 108)
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	resized.connect(queue_redraw)


func configure(id: String, biome: String, color: Color, is_locked: bool) -> void:
	level_id = id
	biome_id = biome
	accent = color
	locked = is_locked
	accessibility_name = "%s%s" % [tooltip_text, "，尚未解锁" if locked else ""]
	queue_redraw()


func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()


func set_phase(value: float) -> void:
	phase = value
	queue_redraw()


func _draw() -> void:
	var center := Vector2(44, 39)
	var pressed_offset := Vector2(0, 2) if is_pressed() else Vector2.ZERO
	draw_set_transform(pressed_offset)
	_draw_pedestal(center)
	_draw_pin(center)
	if locked:
		_draw_lock(center)
	else:
		_draw_biome_mark(center)
	if selected:
		var pulse := 2.0 + sin(phase * TAU) * 1.2
		draw_arc(center, 35.0 + pulse, 0.0, TAU, 48, Color(UiFactory.ACCENT_LIGHT, 0.9), 2.4, true)
	draw_set_transform(Vector2.ZERO)


func _draw_pedestal(center: Vector2) -> void:
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2(center.x + 3, 255), 28.0, Color(0.03, 0.08, 0.08, 0.34))
	draw_set_transform(Vector2.ZERO)
	_draw_oval(Vector2(center.x, 92), Vector2(29, 10), Color("8c6b3c"))
	_draw_oval(Vector2(center.x, 89), Vector2(25, 8), Color("e7c980"))
	draw_arc(Vector2(center.x, 89), 24.0, 0.18, PI - 0.18, 28, Color("5c4b32"), 2.0, true)


func _draw_pin(center: Vector2) -> void:
	var body := accent.lerp(UiFactory.DISABLED, 0.46) if locked else accent
	var tail := PackedVector2Array([
		Vector2(23, 48), Vector2(65, 48), Vector2(58, 72), Vector2(44, 88), Vector2(30, 72),
	])
	draw_colored_polygon(tail, Color(UiFactory.INK, 0.96))
	draw_circle(center, 31.0, Color(UiFactory.INK, 0.96))
	var inner_tail := PackedVector2Array([
		Vector2(27, 48), Vector2(61, 48), Vector2(54, 69), Vector2(44, 82), Vector2(34, 69),
	])
	draw_colored_polygon(inner_tail, body)
	draw_circle(center, 27.0, body)
	draw_arc(center, 24.0, 0.0, TAU, 40, Color(UiFactory.SURFACE, 0.86), 2.2, true)
	draw_arc(center, 31.0, 0.0, TAU, 40, Color(UiFactory.ACCENT_LIGHT, 0.72), 2.0, true)


func _draw_biome_mark(center: Vector2) -> void:
	match biome_id:
		"golden_oasis":
			_draw_palm(center)
		"crystal_volcano":
			_draw_crystal(center)
		_:
			_draw_flower(center)


func _draw_flower(center: Vector2) -> void:
	for index in range(5):
		var offset := Vector2.from_angle(-PI * 0.5 + index * TAU / 5.0) * 9.0
		draw_circle(center + offset, 5.5, UiFactory.SURFACE)
	draw_circle(center, 5.0, UiFactory.ACCENT_LIGHT)
	draw_line(center + Vector2(0, 9), center + Vector2(0, 19), UiFactory.SUPPORTING, 2.8, true)


func _draw_palm(center: Vector2) -> void:
	draw_line(center + Vector2(-2, 18), center + Vector2(2, -2), Color("f7dfaa"), 4.0, true)
	for angle in [-2.75, -2.2, -1.55, -0.9, -0.35]:
		draw_line(center + Vector2(2, -2), center + Vector2.from_angle(angle) * 16.0, UiFactory.SURFACE, 4.0, true)


func _draw_crystal(center: Vector2) -> void:
	var crystal := PackedVector2Array([
		center + Vector2(0, -18), center + Vector2(12, -4), center + Vector2(7, 17),
		center + Vector2(-7, 17), center + Vector2(-12, -4),
	])
	draw_colored_polygon(crystal, UiFactory.SURFACE)
	draw_polyline(PackedVector2Array([crystal[0], crystal[2], crystal[3], crystal[0]]), Color("b7edf0"), 2.0, true)


func _draw_lock(center: Vector2) -> void:
	draw_arc(center + Vector2(0, -4), 8.0, PI, TAU, 20, UiFactory.SURFACE, 3.0, true)
	draw_rect(Rect2(center + Vector2(-10, -3), Vector2(20, 16)), Color(UiFactory.INK, 0.62), true)
	draw_rect(Rect2(center + Vector2(-10, -3), Vector2(20, 16)), UiFactory.SURFACE, false, 2.2)
	draw_circle(center + Vector2(0, 4), 2.0, UiFactory.SURFACE)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(28):
		var angle := index * TAU / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
