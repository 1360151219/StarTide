extends Panel

signal activated(category: String, entry: Dictionary, discovered: bool)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterAssets = preload("res://scripts/ui/character_asset_catalog.gd")
const LOCK_TEXTURE = preload("res://assets/art/ui/home/route_icon_locked.png")
const CATEGORY_SILHOUETTES := {
	"heroes": preload("res://assets/art/ui/compendium/category_heroes.png"),
	"enemies": preload("res://assets/art/ui/compendium/category_enemies.png"),
	"pickups": preload("res://assets/art/ui/compendium/category_pickups.png"),
	"skills": preload("res://assets/art/ui/compendium/category_skills.png"),
	"relics": preload("res://assets/art/ui/compendium/category_relics.png"),
}

var category_id := ""
var entry_data: Dictionary = {}
var is_discovered := false
var touch_active := false
var touch_origin := Vector2.ZERO
var owner_badge: Panel


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
	custom_minimum_size = Vector2(154, 276)
	set_meta("content_id", entry["id"])
	set_meta("discovered", discovered)
	set_meta("owner_hero_id", str(entry.get("owner_hero_id", "")))
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "查看%s记录" % (entry["name"] if discovered else "解锁线索")
	accessibility_name = _accessibility_name(entry, discovered)
	_apply_tile_style()
	_add_dividers()
	_add_icon(entry, discovered)
	_add_name(entry, discovered)
	if category == "skills" and discovered:
		_add_owner_badge(entry)
	else:
		_add_subtitle(subtitle_text, discovered)
	_add_hidden_description(description_text)
	if not discovered:
		_add_lock_mark()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		self_modulate = Color(0.9, 0.96, 0.94) if event.pressed else Color.WHITE
		if event.pressed:
			_activate()
			accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_active = true
			touch_origin = event.position
			self_modulate = Color(0.9, 0.96, 0.94)
		elif touch_active:
			touch_active = false
			self_modulate = Color.WHITE
			_activate()
			accept_event()
	elif event is InputEventScreenDrag and touch_active:
		if event.position.distance_to(touch_origin) > 14.0:
			touch_active = false
			self_modulate = Color.WHITE
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_SPACE]:
		_activate()
		accept_event()


func _activate() -> void:
	activated.emit(category_id, entry_data, is_discovered)


func _add_dividers() -> void:
	var right := ColorRect.new()
	right.position = Vector2(153, 10)
	right.size = Vector2(1, 256)
	right.color = Color("d5b87e80")
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right)
	var bottom := ColorRect.new()
	bottom.position = Vector2(8, 275)
	bottom.size = Vector2(138, 1)
	bottom.color = Color("d5b87e80")
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)


func _add_icon(entry: Dictionary, discovered: bool) -> void:
	var icon := TextureRect.new()
	icon.name = "SubjectIcon"
	icon.position = Vector2(14, 14)
	icon.size = Vector2(126, 134)
	icon.texture = entry["texture"] if discovered else CATEGORY_SILHOUETTES[category_id]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if discovered else Color(0.22, 0.38, 0.38, 0.48)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)


func _add_name(entry: Dictionary, discovered: bool) -> void:
	var name_label := _plain_label(entry["name"] if discovered else "？？？", 19, UiFactory.INK if discovered else UiFactory.MUTED_INK)
	name_label.name = "EntryName"
	name_label.position = Vector2(10, 154)
	name_label.size = Vector2(134, 38)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	add_child(name_label)


func _add_subtitle(text: String, discovered: bool) -> void:
	var subtitle := _plain_label(text, 14, UiFactory.PRIMARY_DARK if discovered else UiFactory.MUTED_INK)
	subtitle.name = "EntryMarker"
	subtitle.position = Vector2(12, 198)
	subtitle.size = Vector2(130, 48)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.max_lines_visible = 2
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle.clip_text = true
	add_child(subtitle)


func _add_owner_badge(entry: Dictionary) -> void:
	var hero_id := str(entry.get("owner_hero_id", ""))
	var avatar := CharacterAssets.hero_avatar_texture(hero_id)
	if avatar == null:
		return
	owner_badge = Panel.new()
	owner_badge.name = "OwnerAvatarBadge"
	owner_badge.position = Vector2(53, 198)
	owner_badge.size = Vector2(48, 48)
	owner_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner_badge.add_theme_stylebox_override("panel", _owner_style(entry["accent"]))
	add_child(owner_badge)
	var portrait := TextureRect.new()
	portrait.position = Vector2(4, 4)
	portrait.size = Vector2(40, 40)
	portrait.texture = avatar
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner_badge.add_child(portrait)


func _add_hidden_description(text: String) -> void:
	var description := _plain_label(text, 14, UiFactory.MUTED_INK)
	description.name = "DetailDescription"
	description.visible = false
	add_child(description)


func _add_lock_mark() -> void:
	var lock_mark := TextureRect.new()
	lock_mark.name = "LockBadge"
	lock_mark.position = Vector2(104, 8)
	lock_mark.size = Vector2(46, 46)
	lock_mark.texture = LOCK_TEXTURE
	lock_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lock_mark)


func _apply_tile_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	add_theme_stylebox_override("panel", style)


func _owner_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiFactory.SURFACE
	style.border_color = Color(accent, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	return style


func _accessibility_name(entry: Dictionary, discovered: bool) -> String:
	if not discovered:
		return "尚未发现，查看解锁线索"
	var hero_name := str(entry.get("owner_name", ""))
	return str(entry["name"]) if hero_name.is_empty() else "%s，%s英雄技能" % [entry["name"], hero_name]


func _plain_label(text: String, font_size: int, color: Color) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
