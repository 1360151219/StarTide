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
	var glyph := SunlitGlyph.new()
	glyph.glyph_id = destination_data["glyph_id"]
	glyph.position = from_screen - Vector2(14, 14)
	glyph.size = Vector2(28, 28)
	glyph.scale = Vector2.ONE * 0.72
	glyph.modulate.a = 0.96
	add_child(glyph)
	var destination := target.get_global_rect().get_center() - Vector2(14, 14)
	var midpoint := (glyph.position + destination) * 0.5 + Vector2(0, -24)
	var tween := create_tween()
	tween.tween_property(glyph, "position", midpoint, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(glyph, "scale", Vector2.ONE, 0.1)
	tween.tween_property(glyph, "position", destination, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(glyph, "scale", Vector2.ONE * 0.54, 0.1)
	tween.tween_callback(_finish_destination.bind(glyph, target))


func _destination_data(pickup_id: String, xp_bar: Control, health_bar: Control, status_panel: Control) -> Dictionary:
	match pickup_id:
		"xp":
			return {"target": xp_bar, "glyph_id": "level"}
		"heart":
			return {"target": health_bar, "glyph_id": "heal"}
		"magnet":
			return {"target": status_panel, "glyph_id": "magnet"}
		"haste_leaf":
			return {"target": status_panel, "glyph_id": "haste"}
	return {}


func _finish_destination(glyph: Control, target: Control) -> void:
	if is_instance_valid(glyph):
		glyph.queue_free()
	if not is_instance_valid(target):
		return
	var flash := ColorRect.new()
	flash.color = Color(UiFactory.ACCENT, 0.62)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(flash)
	ScreenLayout.fill(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)
