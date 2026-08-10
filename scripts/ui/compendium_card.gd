extends Panel

signal activated(category: String, entry: Dictionary, discovered: bool)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const SunlitLockBadge = preload("res://scripts/ui/sunlit_lock_badge.gd")

var category_id := ""
var entry_data: Dictionary = {}
var is_discovered := false
var touch_active := false
var touch_origin := Vector2.ZERO


func configure(
	category: String,
	entry: Dictionary,
	discovered: bool,
	subtitle_text: String,
	description_text: String
) -> void:
	category_id = category
	entry_data = entry
	is_discovered = discovered
	custom_minimum_size = Vector2(162, 190)
	set_meta("content_id", entry["id"])
	set_meta("discovered", discovered)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "查看%s记录" % (entry["name"] if discovered else "解锁线索")
	var accent: Color = entry["accent"] if discovered else Color("82948b")
	_apply_tile_style(discovered, accent)
	_add_icon(entry, discovered)
	_add_name(entry, discovered)
	_add_subtitle(subtitle_text, accent, discovered)
	_add_hidden_description(description_text)
	_add_identity_mark(accent, discovered)
	if not discovered:
		_add_lock_mark()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_activate()
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_active = true
			touch_origin = event.position
		elif touch_active:
			touch_active = false
			_activate()
			accept_event()
	elif event is InputEventScreenDrag and touch_active:
		if event.position.distance_to(touch_origin) > 14.0:
			touch_active = false
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_SPACE]:
		_activate()
		accept_event()


func _activate() -> void:
	activated.emit(category_id, entry_data, is_discovered)


func _add_icon(entry: Dictionary, discovered: bool) -> void:
	var icon := TextureRect.new()
	icon.position = Vector2(20, 12)
	icon.size = Vector2(124, 108)
	icon.texture = entry["texture"]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if discovered else Color(0.12, 0.2, 0.19, 0.42)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)


func _add_name(entry: Dictionary, discovered: bool) -> void:
	var name_label := _plain_label(entry["name"] if discovered else "？？？", 18, UiFactory.INK if discovered else UiFactory.MUTED_INK)
	name_label.position = Vector2(10, 120)
	name_label.size = Vector2(142, 28)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	add_child(name_label)


func _add_subtitle(text: String, accent: Color, discovered: bool) -> void:
	var subtitle_color := accent.darkened(0.22) if discovered and accent.get_luminance() > 0.48 else accent
	var subtitle := _plain_label(text, 14, subtitle_color if discovered else UiFactory.MUTED_INK)
	subtitle.position = Vector2(10, 150)
	subtitle.size = Vector2(142, 34)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.clip_text = true
	add_child(subtitle)


func _add_hidden_description(text: String) -> void:
	var description := _plain_label(text, 14, UiFactory.MUTED_INK)
	description.visible = false
	add_child(description)


func _add_lock_mark() -> void:
	var lock_mark := SunlitLockBadge.new()
	lock_mark.position = Vector2(116, 10)
	lock_mark.size = Vector2(38, 38)
	add_child(lock_mark)


func _apply_tile_style(discovered: bool, accent: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UiFactory.SURFACE_ALT, 0.5 if discovered else 0.32)
	var structural_border := UiFactory.PRIMARY if discovered else UiFactory.DISABLED
	style.border_color = Color(structural_border, 0.46)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 2
	add_theme_stylebox_override("panel", style)
	SunlitCardStyle.decorate(self, Color(structural_border, 0.2), 4.0, true, false, Color(accent, 0.24), "canvas")


func _add_identity_mark(accent: Color, discovered: bool) -> void:
	var mark := ColorRect.new()
	mark.position = Vector2(4, 12)
	mark.size = Vector2(4, 164)
	mark.color = Color(accent if discovered else UiFactory.DISABLED, 0.7)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mark)


func _plain_label(text: String, font_size: int, color: Color) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
