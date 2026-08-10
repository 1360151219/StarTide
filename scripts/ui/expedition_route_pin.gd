extends Button

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const AVAILABLE_FRAME := preload("res://assets/art/ui/home/route_pin_available.png")
const SELECTED_FRAME := preload("res://assets/art/ui/home/route_pin_selected.png")
const MEADOW_ICON := preload("res://assets/art/ui/home/route_icon_meadow.png")
const OASIS_ICON := preload("res://assets/art/ui/home/route_icon_oasis.png")
const VOLCANO_ICON := preload("res://assets/art/ui/home/route_icon_volcano.png")
const LOCKED_ICON := preload("res://assets/art/ui/home/route_icon_locked.png")

var level_id := ""
var biome_id := "windbell_meadow"
var accent := UiFactory.ACCENT
var locked := false
var selected := false
var phase := 0.0
var _content: Control
var _frame: TextureRect
var _icon: TextureRect
var _hovered := false
var _motion_tween: Tween


func _ready() -> void:
	size = Vector2(88, 108)
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_build_assets()
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	button_down.connect(_refresh_visual)
	button_up.connect(_refresh_visual)
	resized.connect(_layout_assets)


func configure(id: String, biome: String, color: Color, is_locked: bool) -> void:
	level_id = id
	biome_id = biome
	accent = color
	locked = is_locked
	accessibility_name = "%s%s" % [tooltip_text, "，尚未解锁" if locked else ""]
	_refresh_assets()
	queue_redraw()


func set_selected(value: bool) -> void:
	selected = value
	_refresh_assets()
	queue_redraw()


func set_phase(value: float) -> void:
	phase = value
	queue_redraw()


func frame_texture_path() -> String:
	return _frame.texture.resource_path


func icon_texture_path() -> String:
	return _icon.texture.resource_path


func _build_assets() -> void:
	_content = Control.new()
	_content.name = "Artwork"
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_frame = _texture_layer("Frame")
	_icon = _texture_layer("Icon")
	_layout_assets()
	_refresh_assets()


func _texture_layer(layer_name: String) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(layer)
	return layer


func _layout_assets() -> void:
	if not is_instance_valid(_content):
		return
	_content.size = size
	_content.pivot_offset = size * 0.5
	_frame.size = size
	_icon.position = Vector2(16, 10)
	_icon.size = Vector2(56, 56)


func _refresh_assets() -> void:
	if not is_instance_valid(_frame):
		return
	_frame.texture = SELECTED_FRAME if selected and not locked else AVAILABLE_FRAME
	_frame.modulate = Color(0.70, 0.73, 0.71, 0.86) if locked else Color.WHITE
	_icon.texture = LOCKED_ICON if locked else _biome_icon()
	_icon.modulate = Color(0.86, 0.88, 0.86, 0.92) if locked else Color.WHITE


func _biome_icon() -> Texture2D:
	match biome_id:
		"golden_oasis":
			return OASIS_ICON
		"crystal_volcano":
			return VOLCANO_ICON
		_:
			return MEADOW_ICON


func _set_hovered(value: bool) -> void:
	_hovered = value
	_refresh_visual()


func _refresh_visual() -> void:
	if not is_instance_valid(_content):
		return
	var target_position := Vector2(0, 2) if is_pressed() else Vector2.ZERO
	var target_scale := Vector2.ONE * (1.025 if _hovered else 1.0)
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.parallel().tween_property(_content, "position", target_position, 0.1)
	_motion_tween.parallel().tween_property(_content, "scale", target_scale, 0.1)
	queue_redraw()


func _draw() -> void:
	if not selected or locked:
		return
	var pulse := 1.8 + sin(phase * TAU) * 1.1
	var offset := Vector2(0, 2) if is_pressed() else Vector2.ZERO
	draw_arc(Vector2(44, 35) + offset, 34.0 + pulse, 0.0, TAU, 48, Color(UiFactory.ACCENT_LIGHT, 0.92), 2.4, true)
