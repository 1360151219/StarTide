extends "res://scripts/presentation/combat_effect_draw_abilities.gd"

const GAME_FONT := preload("res://assets/fonts/NotoSansSC-Regular.otf")


func _draw_floating_text(effect: Dictionary, center: Vector2, progress: float, alpha: float) -> void:
	var is_player: bool = bool(effect["is_player"])
	var font_size := 27 if is_player else 20
	var position := center + Vector2(0, -28.0 - progress * (42.0 if is_player else 27.0))
	var color: Color = effect["color"]
	color.a = alpha
	var shadow := Color(0.015, 0.02, 0.06, alpha * 0.9)
	draw_string(GAME_FONT, position + Vector2(2, 2), effect["text"], HORIZONTAL_ALIGNMENT_CENTER, 54.0, font_size, shadow)
	draw_string(GAME_FONT, position, effect["text"], HORIZONTAL_ALIGNMENT_CENTER, 54.0, font_size, color)


func _draw_star_shield(center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var reach := radius * (0.58 + (1.0 - pow(1.0 - progress, 2.0)) * 0.08)
	var points := PackedVector2Array()
	for point in [Vector2(-0.7, -0.8), Vector2(0.7, -0.8), Vector2(1, -0.25), Vector2(0.75, 0.55), Vector2(0, 1), Vector2(-0.75, 0.55), Vector2(-1, -0.25), Vector2(-0.7, -0.8)]:
		points.append(center + Vector2(0, -20) + point * reach)
	draw_polyline(points, Color(0.03, 0.27, 0.38, alpha * 0.86), 5.0, true)
	draw_polyline(points, Color(0.62, 0.91, 1.0, alpha), 2.2, true)
