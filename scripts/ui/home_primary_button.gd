extends Button

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var caption: Label
var _hovered := false
var _held := false
var _motion_tween: Tween


func _init() -> void:
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	caption = UiFactory.surface_label("出发", 20, UiFactory.INK)
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	resized.connect(_layout_caption)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	button_down.connect(_set_held.bind(true))
	button_up.connect(_set_held.bind(false))
	focus_entered.connect(_set_hovered.bind(true))
	focus_exited.connect(_set_hovered.bind(false))


func _ready() -> void:
	_layout_caption()
	call_deferred("_play_attention")


func set_caption(value: String, available: bool) -> void:
	disabled = not available
	caption.text = "出发" if available else "未解锁"
	accessibility_name = value
	tooltip_text = value
	_refresh_visual()


func _layout_caption() -> void:
	caption.position = Vector2(24, size.y * 0.64)
	caption.size = Vector2(size.x - 48.0, size.y * 0.22)
	pivot_offset = size * 0.5
	queue_redraw()


func _set_hovered(value: bool) -> void:
	_hovered = value
	_refresh_visual()


func _set_held(value: bool) -> void:
	_held = value
	_refresh_visual()


func _refresh_visual() -> void:
	var target_scale := Vector2.ONE * (0.965 if _held else 1.025 if _hovered and not disabled else 1.0)
	caption.modulate = Color(0.52, 0.57, 0.54, 0.82) if disabled else Color.WHITE
	queue_redraw()
	if not is_inside_tree():
		scale = target_scale
		return
	_stop_motion()
	_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", target_scale, 0.1)


func _draw() -> void:
	var radius := minf(size.x, size.y) * 0.47
	var center := size * 0.5
	var ink := Color(UiFactory.INK, 0.65 if disabled else 1.0)
	var surface := Color(UiFactory.SURFACE_ALT, 0.9 if disabled else 1.0)
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2(center.x, center.y * 2.45), radius * 0.86, Color(0.03, 0.08, 0.08, 0.35))
	draw_set_transform(Vector2.ZERO)
	draw_circle(center, radius, Color("8a6a3c"))
	draw_arc(center, radius - 2.0, 0.0, TAU, 64, Color("e8cf91"), 5.0, true)
	draw_circle(center, radius - 10.0, surface)
	draw_arc(center, radius - 11.0, 0.0, TAU, 64, ink, 3.0, true)
	draw_arc(center, radius - 18.0, 0.0, TAU, 64, Color(UiFactory.ACCENT, 0.86), 2.0, true)
	_draw_sail(center + Vector2(0, -19), ink)


func _draw_sail(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(0, -25), center + Vector2(0, 28), color, 3.4, true)
	var left_sail := PackedVector2Array([
		center + Vector2(-3, -21), center + Vector2(-29, 14), center + Vector2(-3, 9),
	])
	var right_sail := PackedVector2Array([
		center + Vector2(4, -17), center + Vector2(28, 13), center + Vector2(4, 9),
	])
	draw_colored_polygon(left_sail, Color(UiFactory.ACCENT, 0.88))
	draw_colored_polygon(right_sail, Color(UiFactory.PRIMARY, 0.92))
	draw_polyline(PackedVector2Array([left_sail[0], left_sail[1], left_sail[2], left_sail[0]]), color, 2.2, true)
	draw_polyline(PackedVector2Array([right_sail[0], right_sail[1], right_sail[2], right_sail[0]]), color, 2.2, true)
	draw_arc(center + Vector2(0, 29), 24.0, 0.18, PI - 0.18, 24, color, 2.4, true)


func _play_attention() -> void:
	if disabled or _hovered or _held or not is_inside_tree():
		return
	_stop_motion()
	scale = Vector2.ONE * 0.96
	_motion_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", Vector2.ONE * 1.02, 0.22)
	_motion_tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func _stop_motion() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = null
