extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var accent_color := UiFactory.PRIMARY
var corner_radius := UiFactory.RADIUS_M
var compact := false
var selected := false
var ornament_color := UiFactory.ACCENT
var variant := "canvas"
var rarity_level := 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func configure(
	accent: Color,
	radius: float,
	is_compact := false,
	is_selected := false,
	ornament := UiFactory.ACCENT,
	frame_variant := "canvas",
	quality_level := 1
) -> void:
	accent_color = accent
	corner_radius = radius
	compact = is_compact
	selected = is_selected
	ornament_color = ornament
	variant = frame_variant
	rarity_level = clampi(quality_level, 1, 3)
	queue_redraw()


func _draw() -> void:
	if size.x < 28.0 or size.y < 24.0:
		return
	var alpha := 1.0
	var parent_button := get_parent() as BaseButton
	if parent_button != null and parent_button.disabled:
		alpha = 0.42
	var accent := Color(accent_color, accent_color.a * alpha)
	var ornament := Color(ornament_color, ornament_color.a * alpha)
	_draw_inner_seam(accent)
	_draw_cut_corners(accent)
	_draw_woven_tab(accent)
	if variant != "reward_card":
		_draw_buckles(accent, ornament)
	if variant == "danger":
		_draw_danger_notches(accent)
	elif variant == "map":
		_draw_map_pointer(accent)
	elif variant == "reward_card":
		_draw_reward_ornaments(accent, ornament)
	elif variant == "hud_top":
		_draw_hud_beams(accent)


func _draw_inner_seam(accent: Color) -> void:
	var inset := 5.0 if compact else 7.0
	var seam := StyleBoxFlat.new()
	seam.bg_color = Color.TRANSPARENT
	seam.border_color = Color(accent, 0.46 if not selected else 0.72)
	seam.set_border_width_all(1)
	seam.corner_radius_top_left = 3
	seam.corner_radius_top_right = maxi(4, int(corner_radius - inset * 0.5))
	seam.corner_radius_bottom_left = maxi(4, int(corner_radius - inset * 0.5))
	seam.corner_radius_bottom_right = 3
	draw_style_box(seam, Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0)))


func _draw_cut_corners(accent: Color) -> void:
	var length := 11.0 if compact else 16.0
	var color := Color(accent, 0.88 if selected else 0.62)
	draw_line(Vector2(2, length), Vector2(length, 2), color, 1.6, true)
	draw_line(size - Vector2(2, length), size - Vector2(length, 2), color, 1.6, true)


func _draw_woven_tab(accent: Color) -> void:
	var tab_width := 20.0 if compact else 28.0
	var tab_height := 7.0 if compact else 9.0
	var left := 10.0 if compact else 16.0
	var points := PackedVector2Array([
		Vector2(left, 0),
		Vector2(left + tab_width, 0),
		Vector2(left + tab_width - 4.0, tab_height),
		Vector2(left + 4.0, tab_height),
	])
	draw_colored_polygon(points, Color(accent, 0.88 if selected else 0.66))
	var stitch := Color(UiFactory.SURFACE, 0.72)
	for index in range(3):
		var x := left + 6.0 + float(index) * (tab_width - 12.0) * 0.5
		draw_line(Vector2(x, 2.0), Vector2(x + 2.0, 4.0), stitch, 1.0, true)


func _draw_buckles(accent: Color, ornament: Color) -> void:
	var count := rarity_level
	if compact:
		count = mini(count, 2)
	var spacing := 8.0
	var start_y := size.y * 0.5 - float(count - 1) * spacing * 0.5
	for index in range(count):
		var center := Vector2(size.x - 7.0, start_y + float(index) * spacing)
		var fill := ornament if rarity_level == 3 else accent
		draw_circle(center, 2.7 if selected else 2.2, Color(fill, 0.86))
		draw_arc(center, 3.8, 0.0, TAU, 16, Color(UiFactory.INK, 0.72), 1.0, true)


func _draw_danger_notches(accent: Color) -> void:
	var center_y := size.y * 0.5
	var fill := Color(accent, 0.72)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, center_y - 6), Vector2(7, center_y), Vector2(0, center_y + 6),
	]), fill)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x, center_y - 6), Vector2(size.x - 7, center_y), Vector2(size.x, center_y + 6),
	]), fill)


func _draw_map_pointer(accent: Color) -> void:
	var center_x := clampf(size.x * 0.26, 24.0, size.x - 24.0)
	var points := PackedVector2Array([
		Vector2(center_x - 6, size.y - 1),
		Vector2(center_x, size.y + 5),
		Vector2(center_x + 6, size.y - 1),
	])
	draw_colored_polygon(points, Color(accent, 0.78))


func _draw_reward_ornaments(accent: Color, ornament: Color) -> void:
	_draw_leaf(Vector2(16, 13), -0.75, Color(UiFactory.SUPPORTING, 0.9))
	_draw_leaf(Vector2(26, 9), -0.25, Color(UiFactory.SUPPORTING, 0.76))
	_draw_leaf(size - Vector2(18, 13), 2.35, Color(UiFactory.SUPPORTING, 0.82))
	var count := rarity_level
	var start_y := size.y * 0.5 - float(count - 1) * 19.0
	for index in range(count):
		var center := Vector2(size.x - 13, start_y + index * 19.0)
		draw_rect(Rect2(center - Vector2(17, 8), Vector2(18, 16)), Color(UiFactory.PRIMARY_DARK, 0.9), true)
		draw_circle(center, 8.0, Color("b78e52"))
		draw_circle(center, 4.5, ornament if rarity_level == 3 else accent)
		draw_arc(center, 8.0, 0.0, TAU, 20, UiFactory.INK, 1.2, true)


func _draw_hud_beams(accent: Color) -> void:
	var wood := Color("8d7248", 0.92)
	draw_line(Vector2(8, 3), Vector2(size.x - 8, 3), wood, 4.0, true)
	draw_line(Vector2(8, size.y - 3), Vector2(size.x - 8, size.y - 3), Color(wood, 0.72), 3.0, true)
	for x in [8.0, size.x - 8.0]:
		draw_circle(Vector2(x, 3), 4.0, UiFactory.ACCENT_LIGHT)
		draw_circle(Vector2(x, size.y - 3), 3.5, accent)


func _draw_leaf(center: Vector2, rotation: float, color: Color) -> void:
	var direction := Vector2.from_angle(rotation)
	var side := direction.orthogonal()
	var points := PackedVector2Array([
		center - direction * 9.0,
		center + side * 5.0,
		center + direction * 10.0,
		center - side * 5.0,
	])
	draw_colored_polygon(points, color)
	draw_line(center - direction * 7.0, center + direction * 8.0, Color(UiFactory.INK, 0.36), 1.0, true)
