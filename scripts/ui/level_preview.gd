extends Control

signal swipe_requested(direction: int)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const SwipeGesture = preload("res://scripts/ui/swipe_gesture.gd")
const PORTAL_FRAME := preload("res://assets/art/ui/home/portal_frame.png")
const HERO_PREVIEW_FRAMES := [
	preload("res://assets/art/characters/star_tide_warden.png"),
	preload("res://assets/art/characters/star_tide_warden_side.png"),
]
const MASK_SHADER := "shader_type canvas_item; void fragment(){ vec2 p=(UV-vec2(0.5))/vec2(0.5,0.5); float a=1.0-smoothstep(0.92,1.0,dot(p,p)); COLOR=texture(TEXTURE,UV)*COLOR; COLOR.a*=a; }"

var animation_player: AnimationPlayer
var preview_sprite: AnimatedSprite2D
var title_label: Label
var detail_label: Label
var objective_label: Label
var scene_texture: TextureRect
var enemy_nodes: Array[TextureRect] = []
var lock_panel: Panel
var current_level_id := "level_01"
var current_presentation: LevelPresentationConfig
var requested_active := true
var unlocked := true
var built := false
var swipe_gesture := SwipeGesture.new()
var phase := 0.0:
	set(value):
		phase = value
		if is_instance_valid(preview_sprite):
			preview_sprite.position = Vector2(252 + sin(phase * TAU) * 18.0, 230 + sin(phase * TAU * 2.0) * 3.0)
		for index in range(enemy_nodes.size()):
			var base_positions := [Vector2(122, 188), Vector2(330, 165), Vector2(331, 246)]
			enemy_nodes[index].position = base_positions[index] + Vector2(sin(phase * TAU + index * 1.8) * 7.0, cos(phase * TAU + index) * 4.0)


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if built:
		return
	built = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_portal_scene()
	_build_labels()
	_build_animation()


func show_level(level: LevelConfig, presentation: LevelPresentationConfig, progress_text: String, is_unlocked: bool) -> void:
	_ensure_built()
	current_level_id = level.level_id
	current_presentation = presentation
	unlocked = is_unlocked
	scene_texture.texture = _preview_texture()
	scene_texture.self_modulate = current_presentation.preview_tint.darkened(0.08) if not unlocked else current_presentation.preview_tint
	preview_sprite.visible = true
	preview_sprite.modulate = Color(1, 1, 1, 0.62) if not unlocked else Color.WHITE
	lock_panel.visible = not unlocked
	_set_enemy_textures()
	title_label.text = level.display_name
	detail_label.text = "%s  ·  %s" % ["◆".repeat(level.difficulty_rating), progress_text]
	objective_label.text = "%s  ·  奖励：%s" % [level.subtitle, level.reward.display_name]
	phase = 0.0
	if is_instance_valid(animation_player) and requested_active:
		animation_player.play("preview_loop")
		preview_sprite.play("travel")


func set_active(value: bool) -> void:
	requested_active = value
	if not is_instance_valid(animation_player):
		return
	if value:
		animation_player.play("preview_loop")
		preview_sprite.play("travel")
	else:
		animation_player.pause()
		preview_sprite.pause()


func _build_portal_scene() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	scene_texture = TextureRect.new()
	scene_texture.position = Vector2(100, 52)
	scene_texture.size = Vector2(304, 282)
	scene_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = MASK_SHADER
	var mask := ShaderMaterial.new()
	mask.shader = shader
	scene_texture.material = mask
	add_child(scene_texture)
	for index in range(3):
		var enemy := TextureRect.new()
		enemy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		enemy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		enemy.size = Vector2(58, 58) if index < 2 else Vector2(50, 50)
		enemy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enemy_nodes.append(enemy)
		add_child(enemy)
	var frame := TextureRect.new()
	frame.position = Vector2(46, -7)
	frame.size = Vector2(412, 412)
	frame.texture = PORTAL_FRAME
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.z_index = 4
	add_child(frame)
	lock_panel = Panel.new()
	lock_panel.position = Vector2(132, 136)
	lock_panel.size = Vector2(240, 92)
	lock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.025, 0.13, 0.19, 0.9), 18.0, Color("e8c46a")))
	lock_panel.z_index = 6
	add_child(lock_panel)
	var lock_label := UiFactory.label("◇  尚未解锁\n通关前序关卡后开放", 16, Color("fff0b4"))
	lock_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_panel.add_child(lock_label)


func _build_labels() -> void:
	var title_plate := Panel.new()
	title_plate.position = Vector2(135, 45)
	title_plate.size = Vector2(234, 58)
	title_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_plate.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.025, 0.16, 0.21, 0.82), 16.0, Color(0.91, 0.76, 0.38, 0.72)))
	title_plate.z_index = 6
	add_child(title_plate)
	title_label = UiFactory.label("", 23, Color("fff3bd"))
	title_label.position = Vector2(8, 3)
	title_label.size = Vector2(218, 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_plate.add_child(title_label)
	detail_label = UiFactory.label("", 12, Color("bdeee7"))
	detail_label.position = Vector2(8, 31)
	detail_label.size = Vector2(218, 20)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_plate.add_child(detail_label)
	var objective_plate := Panel.new()
	objective_plate.position = Vector2(91, 340)
	objective_plate.size = Vector2(322, 34)
	objective_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_plate.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.025, 0.14, 0.18, 0.84), 12.0, Color(0.88, 0.71, 0.33, 0.68)))
	objective_plate.z_index = 6
	add_child(objective_plate)
	objective_label = UiFactory.label("", 12, Color("f4efcf"))
	objective_label.position = Vector2(8, 3)
	objective_label.size = Vector2(306, 28)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.clip_text = true
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_plate.add_child(objective_label)


func _build_animation() -> void:
	preview_sprite = AnimatedSprite2D.new()
	preview_sprite.position = Vector2(252, 230)
	preview_sprite.scale = Vector2.ONE * 0.17
	preview_sprite.z_index = 2
	var frames := SpriteFrames.new()
	frames.add_animation("travel")
	frames.set_animation_loop("travel", true)
	frames.set_animation_speed("travel", 2.0)
	for texture in HERO_PREVIEW_FRAMES:
		frames.add_frame("travel", texture)
	preview_sprite.sprite_frames = frames
	preview_sprite.animation = "travel"
	add_child(preview_sprite)
	preview_sprite.play()
	animation_player = AnimationPlayer.new()
	add_child(animation_player)
	var animation := Animation.new()
	animation.length = 3.2
	animation.loop_mode = Animation.LOOP_LINEAR
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(".:phase"))
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	animation.track_insert_key(track, 0.0, 0.0)
	animation.track_insert_key(track, animation.length, 1.0)
	var library := AnimationLibrary.new()
	library.add_animation("preview_loop", animation)
	animation_player.add_animation_library("", library)
	animation_player.play("preview_loop")


func _set_enemy_textures() -> void:
	if current_presentation == null or current_presentation.featured_enemy_ids.is_empty():
		for enemy in enemy_nodes:
			enemy.visible = false
		return
	for index in range(enemy_nodes.size()):
		var enemy_id: String = current_presentation.featured_enemy_ids[index % current_presentation.featured_enemy_ids.size()]
		enemy_nodes[index].texture = EnemyCatalog.enemy(enemy_id)["front"]
		enemy_nodes[index].modulate = Color(1, 1, 1, 0.55) if not unlocked else Color.WHITE
		enemy_nodes[index].visible = true


func _preview_texture() -> Texture2D:
	if current_presentation == null:
		return null
	if not current_presentation.preview_region.has_area():
		return current_presentation.preview_texture
	var atlas := AtlasTexture.new()
	atlas.atlas = current_presentation.preview_texture
	atlas.region = current_presentation.preview_region
	return atlas


func _gui_input(event: InputEvent) -> void:
	var direction := swipe_gesture.handle(event)
	if direction == 0:
		return
	swipe_requested.emit(direction)
	accept_event()
