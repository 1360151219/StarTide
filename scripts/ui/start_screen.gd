extends CanvasLayer

signal start_requested(hero_id: String, level_id: String)

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const DesignFrame = preload("res://scripts/ui/design_frame.gd")
const AudioSettingsPanel = preload("res://scripts/ui/audio_settings_panel.gd")
const ExpeditionRouteMap = preload("res://scripts/ui/expedition_route_map.gd")
const HomePrimaryButton = preload("res://scripts/ui/home_primary_button.gd")
const CompendiumOverlay = preload("res://scripts/ui/compendium_overlay.gd")
const HOME_BACKGROUND := preload("res://assets/art/sunlit/backgrounds/expedition_route_map.png")
const BACKGROUND_SHADER := """
shader_type canvas_item;

uniform vec2 viewport_size = vec2(540.0, 960.0);
uniform vec2 design_origin = vec2(0.0);
uniform vec2 design_size = vec2(540.0, 960.0);

vec3 grade_home_map(vec3 color) {
	color = pow(max(color, vec3(0.0)), vec3(0.78));
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(luma), 0.14);
	return mix(color, vec3(0.867, 0.937, 0.906), 0.10);
}

void fragment() {
	vec2 pixel = UV * viewport_size;
	vec2 design_uv = (pixel - design_origin) / design_size;
	vec2 outside_uv = max(vec2(0.0), max(-design_uv, design_uv - vec2(1.0)));
	float outside_pixels = max(outside_uv.x * design_size.x, outside_uv.y * design_size.y);
	float wide_extension = step(design_size.x + 0.5, viewport_size.x);
	float tall_extension = step(design_size.y + 0.5, viewport_size.y);
	float horizontal_edge_distance = min(pixel.x - design_origin.x, design_origin.x + design_size.x - pixel.x);
	float horizontal_blend = wide_extension * (1.0 - smoothstep(0.0, 28.0, horizontal_edge_distance));
	float vertical_edge_distance = min(pixel.y - design_origin.y, design_origin.y + design_size.y - pixel.y);
	float vertical_blend = tall_extension * (1.0 - smoothstep(0.0, 28.0, vertical_edge_distance));
	vec2 extension_uv = clamp(design_uv, vec2(0.0), vec2(1.0));
	if (design_uv.x < 0.0) extension_uv.x = 0.26;
	else if (design_uv.x > 1.0) extension_uv.x = 0.74;
	if (design_uv.y < 0.0) extension_uv.y = 0.18;
	else if (design_uv.y > 1.0) extension_uv.y = 0.82;
	vec4 edge = texture(TEXTURE, clamp(design_uv, vec2(0.0), vec2(1.0))) * COLOR;
	edge.rgb = grade_home_map(edge.rgb);
	vec4 extension;
	if (wide_extension > 0.5 && (tall_extension < 0.5 || horizontal_blend >= vertical_blend)) {
		float anchor_x = 0.26;
		if (design_uv.x > 0.5) anchor_x = 0.74;
		vec4 top = (texture(TEXTURE, vec2(anchor_x - 0.12, 0.18)) + texture(TEXTURE, vec2(anchor_x, 0.18)) + texture(TEXTURE, vec2(anchor_x + 0.12, 0.18))) / 3.0;
		vec4 middle = (texture(TEXTURE, vec2(anchor_x - 0.12, 0.5)) + texture(TEXTURE, vec2(anchor_x, 0.5)) + texture(TEXTURE, vec2(anchor_x + 0.12, 0.5))) / 3.0;
		vec4 bottom = (texture(TEXTURE, vec2(anchor_x - 0.12, 0.82)) + texture(TEXTURE, vec2(anchor_x, 0.82)) + texture(TEXTURE, vec2(anchor_x + 0.12, 0.82))) / 3.0;
		float vertical = clamp(design_uv.y, 0.0, 1.0);
		vec4 upper = mix(top, middle, smoothstep(0.05, 0.55, vertical));
		vec4 lower = mix(middle, bottom, smoothstep(0.45, 0.95, vertical));
		extension = mix(upper, lower, smoothstep(0.35, 0.65, vertical));
	} else {
		float anchor_y = 0.18;
		if (design_uv.y > 0.5) anchor_y = 0.82;
		vec4 left = (texture(TEXTURE, vec2(0.18, anchor_y - 0.1)) + texture(TEXTURE, vec2(0.18, anchor_y)) + texture(TEXTURE, vec2(0.18, anchor_y + 0.1))) / 3.0;
		vec4 middle = (texture(TEXTURE, vec2(0.5, anchor_y - 0.1)) + texture(TEXTURE, vec2(0.5, anchor_y)) + texture(TEXTURE, vec2(0.5, anchor_y + 0.1))) / 3.0;
		vec4 right = (texture(TEXTURE, vec2(0.82, anchor_y - 0.1)) + texture(TEXTURE, vec2(0.82, anchor_y)) + texture(TEXTURE, vec2(0.82, anchor_y + 0.1))) / 3.0;
		float horizontal = clamp(design_uv.x, 0.0, 1.0);
		vec4 inner_left = mix(left, middle, smoothstep(0.05, 0.55, horizontal));
		vec4 inner_right = mix(middle, right, smoothstep(0.45, 0.95, horizontal));
		extension = mix(inner_left, inner_right, smoothstep(0.35, 0.65, horizontal));
	}
	extension *= COLOR;
	extension.rgb = grade_home_map(extension.rgb);
	float luma = dot(extension.rgb, vec3(0.299, 0.587, 0.114));
	extension.rgb = mix(extension.rgb, vec3(luma), 0.28);
	extension.rgb = mix(extension.rgb, vec3(0.867, 0.937, 0.906), 0.24);
	float extension_blend = max(smoothstep(0.0, 8.0, outside_pixels), max(horizontal_blend, vertical_blend));
	COLOR = mix(edge, extension, extension_blend);
}
"""

var records: RefCounted
var audio: Node
var selected_hero_id := "star_warden"
var selected_level_id := "level_01"
var start_button: HomePrimaryButton
var route_map: Control
var compendium: ColorRect
var audio_settings: Control
var screen_background: TextureRect
var background_material: ShaderMaterial
var design_frame: Control
var lobby_view: Control


func configure(run_records: RefCounted, audio_manager: Node) -> void:
	records = run_records
	audio = audio_manager
	selected_hero_id = records.last_hero_id
	selected_level_id = records.last_level_id
	layer = 20
	design_frame = _build_background()
	_build_header(design_frame)
	_build_lobby(design_frame)
	compendium = CompendiumOverlay.new()
	add_child(compendium)
	compendium.configure(records)
	_show_lobby()
	select_level(selected_level_id)
	select_hero(selected_hero_id)


func select_hero(hero_id: String) -> void:
	selected_hero_id = hero_id
	if is_instance_valid(route_map):
		route_map.set_preview_hero(hero_id)


func select_level(level_id: String) -> void:
	var level := LevelCatalog.by_id(level_id)
	if level == null:
		return
	selected_level_id = level_id
	if is_instance_valid(route_map) and route_map.selected_level_id != level_id:
		route_map.select_level(level_id, false)
	var unlocked: bool = records.is_level_unlocked(level_id)
	route_map.show_level(level, unlocked)
	start_button.set_caption("开始远征" if unlocked else "完成上一关后解锁", unlocked)


func refresh_progress() -> void:
	route_map.refresh()
	select_level(selected_level_id)


func open_compendium(category := "heroes") -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_confirm", -1.0)
	compendium.open(category)


func _build_background() -> Control:
	screen_background = TextureRect.new()
	screen_background.texture = HOME_BACKGROUND
	screen_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen_background.stretch_mode = TextureRect.STRETCH_SCALE
	screen_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background_shader := Shader.new()
	background_shader.code = BACKGROUND_SHADER
	background_material = ShaderMaterial.new()
	background_material.shader = background_shader
	screen_background.material = background_material
	add_child(screen_background)
	ScreenLayout.fill(screen_background)
	call_deferred("_connect_background_layout")
	var content := DesignFrame.new()
	add_child(content)
	return content


func _connect_background_layout() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	if not viewport.size_changed.is_connected(_layout_background):
		viewport.size_changed.connect(_layout_background)
	_layout_background()


func _layout_background() -> void:
	if not is_instance_valid(background_material):
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var visible_rect := viewport.get_visible_rect()
	var safe_rect := ScreenLayout.current_safe_rect(viewport)
	background_material.set_shader_parameter("viewport_size", visible_rect.size)
	background_material.set_shader_parameter("design_origin", ScreenLayout.design_position(safe_rect) - visible_rect.position)
	background_material.set_shader_parameter("design_size", ScreenLayout.DESIGN_SIZE)


func _build_header(parent: Control) -> void:
	audio_settings = AudioSettingsPanel.new()
	audio_settings.position = Vector2(462, 18)
	parent.add_child(audio_settings)
	audio_settings.configure(audio, true)


func _build_lobby(parent: Control) -> void:
	lobby_view = Control.new()
	parent.add_child(lobby_view)
	ScreenLayout.fill(lobby_view)
	route_map = ExpeditionRouteMap.new()
	lobby_view.add_child(route_map)
	route_map.configure(LevelCatalog.all(), records, selected_level_id)
	selected_level_id = route_map.selected_level_id
	route_map.level_selected.connect(_on_level_selected)
	start_button = HomePrimaryButton.new()
	start_button.position = Vector2(340, 744)
	start_button.size = Vector2(192, 192)
	start_button.z_index = 120
	lobby_view.add_child(start_button)
	start_button.set_caption("开始远征", true)
	start_button.pressed.connect(_show_hero_selection)


func _on_level_selected(level_id: String) -> void:
	if is_instance_valid(audio):
		audio.play_sfx("ui_select", -2.0)
	select_level(level_id)


func _show_lobby() -> void:
	lobby_view.visible = true
	route_map.set_active(true)


func _show_hero_selection() -> void:
	if not records.is_level_unlocked(selected_level_id):
		return
	audio_settings.close_popup()
	_request_start()


func _request_start() -> void:
	if records.is_level_unlocked(selected_level_id):
		start_requested.emit(selected_hero_id, selected_level_id)
