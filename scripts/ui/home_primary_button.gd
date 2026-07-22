extends TextureButton

const FRAME := preload("res://assets/art/ui/home/primary_button_frame.png")

var caption: Label
var _hovered := false
var _held := false


func _init() -> void:
	texture_normal = FRAME
	texture_hover = FRAME
	texture_pressed = FRAME
	texture_disabled = FRAME
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	caption = Label.new()
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 25)
	caption.add_theme_color_override("font_color", Color("fff6cf"))
	caption.add_theme_color_override("font_outline_color", Color(0.02, 0.12, 0.17, 0.84))
	caption.add_theme_constant_override("outline_size", 4)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	resized.connect(_layout_caption)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	button_down.connect(_set_held.bind(true))
	button_up.connect(_set_held.bind(false))
	focus_entered.connect(_set_hovered.bind(true))
	focus_exited.connect(_set_hovered.bind(false))


func _ready() -> void:
	_layout_caption()


func set_caption(value: String, available: bool) -> void:
	caption.text = value
	disabled = not available
	_refresh_visual()


func _layout_caption() -> void:
	caption.position = Vector2(34, 22)
	caption.size = size - Vector2(68, 35)
	pivot_offset = size * 0.5


func _set_hovered(value: bool) -> void:
	_hovered = value
	_refresh_visual()


func _set_held(value: bool) -> void:
	_held = value
	_refresh_visual()


func _refresh_visual() -> void:
	var target_scale := Vector2.ONE * (0.975 if _held else 1.018 if _hovered and not disabled else 1.0)
	var target_color := Color(0.52, 0.58, 0.58, 0.76) if disabled else Color(1.08, 1.08, 1.03) if _hovered else Color.WHITE
	caption.modulate = Color(0.72, 0.74, 0.69, 0.78) if disabled else Color.WHITE
	if not is_inside_tree():
		scale = target_scale
		self_modulate = target_color
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", target_scale, 0.09)
	tween.tween_property(self, "self_modulate", target_color, 0.09)
