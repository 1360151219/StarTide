extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var glyph_id := "shield"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(32, 32))
	match glyph_id:
		"swords":
			_draw_swords()
		"compass":
			_draw_compass()
		"reward":
			_draw_reward()
		_:
			_draw_shield()


func _draw_shield() -> void:
	var points := PackedVector2Array([Vector2(16, 3), Vector2(26, 7), Vector2(24, 21), Vector2(16, 29), Vector2(8, 21), Vector2(6, 7), Vector2(16, 3)])
	draw_colored_polygon(points, Color("f7ecd0"))
	draw_polyline(points, UiFactory.PRIMARY_DARK, 2.0, true)
	draw_line(Vector2(16, 7), Vector2(16, 23), UiFactory.PRIMARY, 2.0, true)
	draw_line(Vector2(12, 12), Vector2(20, 12), UiFactory.ACCENT, 2.0, true)


func _draw_swords() -> void:
	for mirrored in [false, true]:
		var start := Vector2(7, 5) if not mirrored else Vector2(25, 5)
		var finish := Vector2(24, 25) if not mirrored else Vector2(8, 25)
		draw_line(start, finish, UiFactory.PRIMARY_DARK, 3.0, true)
		draw_line(start, finish, UiFactory.PRIMARY_LIGHT, 1.2, true)
	draw_line(Vector2(5, 22), Vector2(11, 28), UiFactory.ACCENT, 2.5, true)
	draw_line(Vector2(27, 22), Vector2(21, 28), UiFactory.ACCENT, 2.5, true)


func _draw_compass() -> void:
	draw_circle(Vector2(16, 16), 12.0, Color("fff6dd"))
	draw_arc(Vector2(16, 16), 12.0, 0.0, TAU, 32, UiFactory.ACCENT, 2.0, true)
	var points := PackedVector2Array([Vector2(16, 2), Vector2(19, 13), Vector2(30, 16), Vector2(19, 19), Vector2(16, 30), Vector2(13, 19), Vector2(2, 16), Vector2(13, 13)])
	draw_colored_polygon(points, Color(UiFactory.ACCENT, 0.48))
	draw_polyline(points, UiFactory.PRIMARY_DARK, 1.4, true)
	draw_circle(Vector2(16, 16), 3.0, UiFactory.PRIMARY)


func _draw_reward() -> void:
	var points := PackedVector2Array([Vector2(7, 24), Vector2(9, 10), Vector2(23, 4), Vector2(27, 10), Vector2(22, 25), Vector2(7, 24)])
	draw_colored_polygon(points, Color("69c9e8"))
	draw_polyline(points, UiFactory.PRIMARY_DARK, 2.0, true)
	draw_line(Vector2(8, 23), Vector2(25, 8), UiFactory.ACCENT_LIGHT, 2.0, true)
	draw_line(Vector2(13, 20), Vector2(12, 11), UiFactory.HUD_TEXT, 1.4, true)
	draw_line(Vector2(18, 16), Vector2(23, 18), UiFactory.HUD_TEXT, 1.4, true)
