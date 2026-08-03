extends TextureButton

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const FRAME := preload("res://assets/art/ui/home/primary_button_frame.png")
const AMBER_SHADER := """
shader_type canvas_item;

void fragment() {
	vec4 source = COLOR;
	float teal_mask = smoothstep(0.02, 0.22, source.b - source.r) * smoothstep(0.02, 0.18, source.g - source.r);
	float brightness = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 amber = mix(vec3(0.76, 0.19, 0.035), vec3(1.0, 0.56, 0.08), smoothstep(0.08, 0.62, brightness));
	source.rgb = mix(source.rgb, amber, teal_mask * 0.94);
	COLOR = source;
}
"""

var caption: Label
var _hovered := false
var _held := false
var _motion_tween: Tween


func _init() -> void:
	texture_normal = FRAME
	texture_hover = FRAME
	texture_pressed = FRAME
	texture_disabled = FRAME
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	var shader := Shader.new()
	shader.code = AMBER_SHADER
	var warm_material := ShaderMaterial.new()
	warm_material.shader = shader
	material = warm_material
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	caption = Label.new()
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font", UiFactory.home_serif(500))
	caption.add_theme_font_size_override("font_size", 31)
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
	call_deferred("_play_attention")


func set_caption(value: String, available: bool) -> void:
	caption.text = value
	disabled = not available
	_refresh_visual()


func _layout_caption() -> void:
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.offset_left = 34.0
	caption.offset_top = 12.0
	caption.offset_right = -34.0
	caption.offset_bottom = -12.0
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
	_stop_motion()
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.tween_property(self, "scale", target_scale, 0.09)
	_motion_tween.tween_property(self, "self_modulate", target_color, 0.09)


func _play_attention() -> void:
	if disabled or _hovered or _held or not is_inside_tree():
		return
	_stop_motion()
	scale = Vector2.ONE * 0.97
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", Vector2.ONE * 1.018, 0.22)
	_motion_tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func _stop_motion() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = null
