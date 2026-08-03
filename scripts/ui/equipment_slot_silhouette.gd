extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var slot_id := "weapon"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func present(value: String) -> void:
	slot_id = value
	queue_redraw()


func _draw() -> void:
	var ink := Color(UiFactory.PRIMARY, 0.86)
	var glow := Color(UiFactory.GOLD, 0.48)
	match slot_id:
		"armor":
			_draw_armor(ink, glow)
		"charm":
			_draw_charm(ink, glow)
		_:
			_draw_weapon(ink, glow)
	_draw_add_mark()


func _draw_weapon(ink: Color, glow: Color) -> void:
	draw_line(Vector2(14, 34), Vector2(36, 12), glow, 6.0, true)
	draw_line(Vector2(14, 34), Vector2(36, 12), ink, 3.0, true)
	var head := PackedVector2Array([Vector2(34, 5), Vector2(43, 8), Vector2(40, 17), Vector2(32, 13)])
	draw_colored_polygon(head, Color(UiFactory.SKY, 0.82))
	draw_polyline(PackedVector2Array([head[0], head[1], head[2], head[3], head[0]]), ink, 2.0, true)
	draw_circle(Vector2(13, 35), 4.0, Color(UiFactory.GOLD, 0.9))


func _draw_armor(ink: Color, glow: Color) -> void:
	var body := PackedVector2Array([
		Vector2(12, 13), Vector2(22, 7), Vector2(30, 7), Vector2(40, 13),
		Vector2(36, 36), Vector2(16, 36),
	])
	draw_colored_polygon(body, Color(UiFactory.SKY, 0.28))
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[4], body[5], body[0]]), ink, 2.5, true)
	draw_line(Vector2(18, 16), Vector2(34, 16), glow, 3.0, true)
	draw_line(Vector2(26, 10), Vector2(26, 34), ink, 2.0, true)


func _draw_charm(ink: Color, glow: Color) -> void:
	draw_arc(Vector2(26, 21), 13.0, 0.0, TAU, 32, ink, 3.0, true)
	draw_arc(Vector2(26, 21), 8.0, 0.0, TAU, 24, glow, 3.0, true)
	var star := PackedVector2Array([
		Vector2(26, 9), Vector2(29, 18), Vector2(38, 21), Vector2(29, 24),
		Vector2(26, 33), Vector2(23, 24), Vector2(14, 21), Vector2(23, 18),
	])
	draw_colored_polygon(star, Color(UiFactory.GOLD, 0.74))
	var outline := star.duplicate()
	outline.append(star[0])
	draw_polyline(outline, ink, 1.5, true)


func _draw_add_mark() -> void:
	var center := Vector2(43, 35)
	draw_circle(center, 8.0, UiFactory.SURFACE)
	draw_arc(center, 8.0, 0.0, TAU, 20, UiFactory.PRIMARY, 2.0, true)
	draw_line(center - Vector2(4, 0), center + Vector2(4, 0), UiFactory.PRIMARY_DARK, 2.0, true)
	draw_line(center - Vector2(0, 4), center + Vector2(0, 4), UiFactory.PRIMARY_DARK, 2.0, true)
