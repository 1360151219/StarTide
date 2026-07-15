extends RefCounted

const DESIGN_SIZE := Vector2(540.0, 960.0)


static func fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func current_safe_rect(viewport: Viewport) -> Rect2:
	var visible_rect := viewport.get_visible_rect()
	if not OS.has_feature("mobile"):
		return visible_rect
	var window := viewport.get_window()
	var window_rect := Rect2(Vector2(window.position), Vector2(window.size))
	var display_safe := DisplayServer.get_display_safe_area()
	var physical_safe := Rect2(Vector2(display_safe.position), Vector2(display_safe.size))
	return physical_safe_to_logical(visible_rect, window_rect, physical_safe)


static func physical_safe_to_logical(visible_rect: Rect2, window_rect: Rect2, physical_safe: Rect2) -> Rect2:
	if window_rect.size.x <= 0.0 or window_rect.size.y <= 0.0 or not physical_safe.has_area():
		return visible_rect
	var clipped := window_rect.intersection(physical_safe)
	if not clipped.has_area():
		return visible_rect
	var scale := visible_rect.size / window_rect.size
	return Rect2(
		visible_rect.position + (clipped.position - window_rect.position) * scale,
		clipped.size * scale
	)


static func design_position(safe_rect: Rect2) -> Vector2:
	return Vector2(
		safe_rect.position.x + (safe_rect.size.x - DESIGN_SIZE.x) * 0.5,
		safe_rect.position.y + maxf(0.0, (safe_rect.size.y - DESIGN_SIZE.y) * 0.5)
	)
