extends Button

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const FRAME := preload("res://assets/art/ui/home/start_button_frame.png")
const SAIL := preload("res://assets/art/ui/home/start_button_sail.png")

var caption: Label
var _frame: TextureRect
var _sail: TextureRect
var _hovered := false
var _held := false
var _motion_tween: Tween


func _init() -> void:
	text = ""
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_frame = _texture_layer("Frame", FRAME)
	_sail = _texture_layer("Sail", SAIL)
	caption = UiFactory.surface_label("出发", 20, UiFactory.INK)
	UiFactory.apply_key_heading(caption, 24, UiFactory.INK)
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	resized.connect(_layout_content)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	button_down.connect(_set_held.bind(true))
	button_up.connect(_set_held.bind(false))
	focus_entered.connect(_set_hovered.bind(true))
	focus_exited.connect(_set_hovered.bind(false))


func _ready() -> void:
	_layout_content()
	call_deferred("_play_attention")


func set_caption(value: String, available: bool) -> void:
	disabled = not available
	caption.text = "出发" if available else "未解锁"
	accessibility_name = value
	tooltip_text = value
	_refresh_visual()


func frame_texture_path() -> String:
	return _frame.texture.resource_path


func sail_texture_path() -> String:
	return _sail.texture.resource_path


func _texture_layer(layer_name: String, texture: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	return layer


func _layout_content() -> void:
	var press_offset := 2.0 if _held else 0.0
	_frame.position = Vector2(0, press_offset)
	_frame.size = size
	_sail.position = Vector2(size.x * 0.25, size.y * 0.14 + press_offset)
	_sail.size = size * 0.5
	caption.position = Vector2(24, size.y * 0.52)
	caption.size = Vector2(size.x - 48.0, size.y * 0.23)
	pivot_offset = size * 0.5


func _set_hovered(value: bool) -> void:
	_hovered = value
	_refresh_visual()


func _set_held(value: bool) -> void:
	_held = value
	_refresh_visual()


func _refresh_visual() -> void:
	var target_scale := Vector2.ONE * (0.965 if _held else 1.025 if _hovered and not disabled else 1.0)
	var enabled_modulate := Color.WHITE
	var disabled_modulate := Color(0.70, 0.73, 0.71, 0.88)
	_frame.modulate = disabled_modulate if disabled else enabled_modulate
	_sail.modulate = Color(0.62, 0.66, 0.64, 0.84) if disabled else enabled_modulate
	caption.modulate = Color(0.52, 0.57, 0.54, 0.82) if disabled else enabled_modulate
	_layout_content()
	if not is_inside_tree():
		scale = target_scale
		return
	_stop_motion()
	_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", target_scale, 0.1)


func _play_attention() -> void:
	if disabled or _hovered or _held or not is_inside_tree():
		return
	_stop_motion()
	scale = Vector2.ONE * 0.96
	_motion_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", Vector2.ONE * 1.02, 0.22)
	_motion_tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func _stop_motion() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = null
