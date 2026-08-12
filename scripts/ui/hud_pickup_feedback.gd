extends Control

const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ScreenLayout.fill(self)


func show_destination(pickup_id: String, from_screen: Vector2, xp_bar: Control, health_bar: Control, status_panel: Control) -> void:
	var destination_data := _destination_data(pickup_id, xp_bar, health_bar, status_panel)
	if destination_data.is_empty():
		return
	var target: Control = destination_data["target"]
	var accent: Color = destination_data["accent"]
	var glyph := _build_flight_glyph(destination_data["glyph_id"])
	glyph.position = from_screen - Vector2(17, 17)
	glyph.scale = Vector2.ONE * 0.82
	glyph.modulate.a = 0.98
	glyph.z_index = 2
	var destination := target.get_global_rect().get_center() - Vector2(17, 17)
	var midpoint := (glyph.position + destination) * 0.5 + Vector2(0, -28)
	var trail := _build_trail(glyph.position + Vector2(17, 17), midpoint + Vector2(17, 17), destination + Vector2(17, 17), accent)
	add_child(trail)
	add_child(glyph)
	var tween := create_tween()
	tween.tween_method(_move_glyph.bind(glyph, glyph.position, midpoint, destination), 0.0, 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(glyph, "scale", Vector2.ONE * 0.58, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_finish_destination.bind(glyph, trail, target, accent))


func _build_flight_glyph(glyph_id: String) -> Panel:
	var badge := Panel.new()
	badge.size = Vector2(34, 34)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UiFactory.SURFACE, 0.96)
	style.border_color = Color(UiFactory.SURFACE, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(17)
	style.shadow_color = Color(UiFactory.PRIMARY_DARK, 0.18)
	style.shadow_size = 2
	badge.add_theme_stylebox_override("panel", style)
	var glyph := SunlitGlyph.new()
	glyph.glyph_id = glyph_id
	glyph.position = Vector2(5, 5)
	glyph.size = Vector2(24, 24)
	badge.add_child(glyph)
	return badge


func _build_trail(start: Vector2, control: Vector2, finish: Vector2, accent: Color) -> Line2D:
	var trail := Line2D.new()
	trail.width = 4.0
	trail.antialiased = true
	var points := PackedVector2Array()
	for index in range(13):
		points.append(_quadratic(start, control, finish, float(index) / 12.0))
	trail.points = points
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([
		Color(accent, 0.08), Color(UiFactory.SURFACE, 0.72), Color(accent, 0.92),
	])
	trail.gradient = gradient
	return trail


func _move_glyph(progress: float, glyph: Control, start: Vector2, control: Vector2, finish: Vector2) -> void:
	if is_instance_valid(glyph):
		glyph.position = _quadratic(start, control, finish, progress)


func _quadratic(start: Vector2, control: Vector2, finish: Vector2, progress: float) -> Vector2:
	var inverse := 1.0 - progress
	return inverse * inverse * start + 2.0 * inverse * progress * control + progress * progress * finish


func _destination_data(pickup_id: String, xp_bar: Control, health_bar: Control, status_panel: Control) -> Dictionary:
	match pickup_id:
		"xp":
			return {"target": xp_bar, "glyph_id": "level", "accent": UiFactory.PRIMARY}
		"heart":
			return {"target": health_bar, "glyph_id": "heal", "accent": UiFactory.HEALING}
		"magnet":
			return {"target": status_panel, "glyph_id": "magnet", "accent": UiFactory.BLOCK}
		"haste_leaf":
			return {"target": status_panel, "glyph_id": "haste", "accent": UiFactory.SUPPORTING}
	return {}


func _finish_destination(glyph: Control, trail: Line2D, target: Control, accent: Color) -> void:
	if is_instance_valid(glyph):
		glyph.queue_free()
	if is_instance_valid(trail):
		trail.queue_free()
	if not is_instance_valid(target):
		return
	var flash := Panel.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(accent, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(mini(8, roundi(target.size.y * 0.5)))
	flash.add_theme_stylebox_override("panel", style)
	target.add_child(flash)
	ScreenLayout.fill(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)
