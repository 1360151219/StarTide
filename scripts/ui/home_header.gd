extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var title_label: Label
var subtitle_label: Label


func _init() -> void:
	size = Vector2(540, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label = UiFactory.label("星潮守望者", 52, UiFactory.GOLD_LIGHT)
	title_label.position = Vector2(20, 67)
	title_label.size = Vector2(500, 72)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiFactory.apply_home_title(title_label, 52)
	add_child(title_label)
	title_label.visibility_changed.connect(queue_redraw)
	subtitle_label = UiFactory.label("✦  远征大厅  ·  选择今天要守护的世界  ✦", 14, UiFactory.CREAM)
	subtitle_label.position = Vector2(20, 151)
	subtitle_label.size = Vector2(500, 30)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiFactory.apply_home_subtitle(subtitle_label, 14)
	add_child(subtitle_label)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if not title_label.visible:
		return
	var gold := Color(UiFactory.GOLD_LIGHT, 0.88)
	draw_colored_polygon(_star_points(Vector2(270, 58), 13.0, 4.0), gold)
	draw_polyline(_bezier(Vector2(174, 72), Vector2(213, 60), Vector2(240, 62), Vector2(257, 68)), Color(gold, 0.72), 1.2, true)
	draw_polyline(_bezier(Vector2(366, 72), Vector2(327, 60), Vector2(300, 62), Vector2(283, 68)), Color(gold, 0.72), 1.2, true)
	draw_polyline(_bezier(Vector2(134, 135), Vector2(170, 148), Vector2(222, 146), Vector2(250, 132)), Color(gold, 0.72), 1.3, true)
	draw_polyline(_bezier(Vector2(406, 135), Vector2(370, 148), Vector2(318, 146), Vector2(290, 132)), Color(gold, 0.72), 1.3, true)
	for center in [Vector2(121, 122), Vector2(419, 122)]:
		draw_colored_polygon(_star_points(center, 5.0, 1.7), gold)


func _star_points(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(8):
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + float(index) * PI * 0.25
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _bezier(start: Vector2, control_a: Vector2, control_b: Vector2, finish: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(17):
		var t := float(index) / 16.0
		var inverse := 1.0 - t
		points.append(inverse * inverse * inverse * start + 3.0 * inverse * inverse * t * control_a + 3.0 * inverse * t * t * control_b + t * t * t * finish)
	return points
