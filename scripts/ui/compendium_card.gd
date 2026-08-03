extends Panel

signal activated(category: String, entry: Dictionary, discovered: bool)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

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
	custom_minimum_size = Vector2(238, 242)
	set_meta("content_id", entry["id"])
	set_meta("discovered", discovered)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "查看%s记录" % (entry["name"] if discovered else "解锁线索")
	var accent: Color = entry["accent"] if discovered else Color("82948b")
	var structural_border := UiFactory.GOLD if discovered else Color(UiFactory.GOLD, 0.48)
	var style := UiFactory.paper_panel_style(structural_border, true, 18.0)
	if not discovered:
		style.bg_color = Color(0.87, 0.9, 0.84, 0.98)
	add_theme_stylebox_override("panel", style)
	_add_icon(entry, discovered)
	_add_name(entry, discovered)
	_add_subtitle(subtitle_text, accent, discovered)
	_add_hidden_description(description_text)
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
	icon.position = Vector2(42, 18)
	icon.size = Vector2(154, 124)
	icon.texture = entry["texture"]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if discovered else Color(0.12, 0.2, 0.19, 0.42)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)


func _add_name(entry: Dictionary, discovered: bool) -> void:
	var name_label := _plain_label(entry["name"] if discovered else "尚未发现", 20, UiFactory.INK)
	name_label.position = Vector2(14, 154)
	name_label.size = Vector2(210, 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	add_child(name_label)


func _add_subtitle(text: String, accent: Color, discovered: bool) -> void:
	var subtitle := _plain_label(text, 13, accent if discovered else UiFactory.MUTED_INK)
	subtitle.position = Vector2(14, 186)
	subtitle.size = Vector2(210, 44)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.clip_text = true
	add_child(subtitle)


func _add_hidden_description(text: String) -> void:
	var description := _plain_label(text, 12, UiFactory.MUTED_INK)
	description.visible = false
	add_child(description)


func _add_lock_mark() -> void:
	var lock_mark := _plain_label("？", 25, Color("fff7d5"))
	lock_mark.position = Vector2(182, 22)
	lock_mark.size = Vector2(30, 30)
	lock_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock_mark.add_theme_stylebox_override("normal", UiFactory.flat_bar_style(Color("52746d"), 14.0))
	add_child(lock_mark)


func _plain_label(text: String, font_size: int, color: Color) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
