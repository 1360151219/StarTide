extends Control

signal swipe_requested(direction: int)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SwipeGesture = preload("res://scripts/ui/swipe_gesture.gd")
const PreviewContent = preload("res://scripts/ui/level_preview_content.gd")
const PORTAL_FRAME := preload("res://assets/art/ui/home/portal_ring_frame.png")
const TITLE_PLATE := preload("res://assets/art/ui/home/level_title_plate.png")
const HeroRigScene = preload("res://scenes/presentation/hero_rig_2d.tscn")
const MASK_SHADER := "shader_type canvas_item; void fragment(){ vec2 p=(UV-vec2(0.5))/vec2(0.5,0.5); float a=1.0-smoothstep(0.73,0.77,dot(p,p)); COLOR=texture(TEXTURE,UV)*COLOR; COLOR.a*=a; }"

var animation_player: AnimationPlayer
var preview_hero: HeroRig2D
var title_label: Label
var detail_label: Label
var scene_texture: TextureRect
var portal_frame: TextureRect
var title_plate: TextureRect
var enemy_nodes: Array[TextureRect] = []
var lock_panel: Panel
var current_level_id := "level_01"
var current_presentation: LevelPresentationConfig
var requested_active := true
var unlocked := true
var built := false
var swipe_gesture := SwipeGesture.new()
var _reveal_tween: Tween
var phase := 0.0:
	set(value):
		phase = value
		if is_instance_valid(preview_hero):
			var travel := sin(phase * TAU)
			preview_hero.position = Vector2(244 + travel * 4.0, 356 + sin(phase * TAU * 2.0) * 1.2)
			preview_hero.set_facing(Vector2.RIGHT if cos(phase * TAU) >= 0.0 else Vector2.LEFT)
		for index in range(enemy_nodes.size()):
			var base_positions := [Vector2(91, 264), Vector2(342, 210), Vector2(341, 330)]
			enemy_nodes[index].position = base_positions[index] + Vector2(sin(phase * TAU + index * 1.8) * 3.0, cos(phase * TAU + index) * 2.0)
		if is_instance_valid(portal_frame):
			var pulse := 1.0 + sin(phase * TAU) * 0.006
			portal_frame.scale = Vector2.ONE * pulse


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


func show_level(level: LevelConfig, presentation: LevelPresentationConfig, _progress_text: String, is_unlocked: bool) -> void:
	_ensure_built()
	current_level_id = level.level_id
	current_presentation = presentation
	unlocked = is_unlocked
	scene_texture.texture = PreviewContent.texture_for(current_presentation)
	var preview_tint := current_presentation.preview_tint if current_presentation != null else Color.WHITE
	scene_texture.self_modulate = preview_tint.darkened(0.08) if not unlocked else preview_tint
	preview_hero.visible = true
	preview_hero.modulate = Color(1, 1, 1, 0.62) if not unlocked else Color.WHITE
	lock_panel.visible = not unlocked
	PreviewContent.apply_enemy_textures(enemy_nodes, current_presentation, unlocked)
	title_label.text = level.display_name
	detail_label.text = "%s  ·  %s" % ["◆".repeat(level.difficulty_rating), level.subtitle]
	phase = 0.0
	if is_instance_valid(animation_player) and requested_active:
		animation_player.play("preview_loop")
		preview_hero.play_state("menu_idle", true)
	_play_reveal()


func set_active(value: bool) -> void:
	requested_active = value
	if not is_instance_valid(animation_player):
		return
	if value:
		animation_player.play("preview_loop")
		preview_hero.set_active(true)
	else:
		animation_player.pause()
		preview_hero.set_active(false)


func set_preview_hero(hero_id: String) -> void:
	_ensure_built()
	preview_hero.configure(hero_id, 160.0)
	preview_hero.play_state("menu_idle", true)


func _build_portal_scene() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	scene_texture = TextureRect.new()
	scene_texture.position = Vector2(17, 11)
	scene_texture.size = Vector2(470, 470)
	scene_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = MASK_SHADER
	var mask := ShaderMaterial.new()
	mask.shader = shader
	scene_texture.material = mask
	add_child(scene_texture)
	var enemy_sizes := [Vector2(104, 104), Vector2(78, 90), Vector2(88, 88)]
	for index in range(3):
		var enemy := TextureRect.new()
		enemy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		enemy.stretch_mode = TextureRect.STRETCH_SCALE if index == 1 else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		enemy.size = enemy_sizes[index]
		enemy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enemy_nodes.append(enemy)
		add_child(enemy)
	portal_frame = TextureRect.new()
	portal_frame.position = Vector2(-4, 0)
	portal_frame.size = Vector2(512, 482)
	portal_frame.pivot_offset = portal_frame.size * 0.5
	portal_frame.texture = PORTAL_FRAME
	portal_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portal_frame.stretch_mode = TextureRect.STRETCH_SCALE
	portal_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portal_frame.z_index = 4
	add_child(portal_frame)
	lock_panel = Panel.new()
	lock_panel.position = Vector2(116, 170)
	lock_panel.size = Vector2(272, 96)
	lock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color(1.0, 0.98, 0.91, 0.96), 18.0, UiFactory.GOLD))
	lock_panel.z_index = 6
	add_child(lock_panel)
	var lock_label := UiFactory.label("◇  尚未解锁\n通关前序关卡后开放", 16, UiFactory.INK)
	lock_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_label.add_theme_constant_override("outline_size", 0)
	lock_panel.add_child(lock_label)


func _build_labels() -> void:
	title_plate = TextureRect.new()
	title_plate.position = Vector2(134, 57)
	title_plate.size = Vector2(236, 82)
	title_plate.texture = TITLE_PLATE
	title_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_plate.stretch_mode = TextureRect.STRETCH_SCALE
	title_plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_plate.z_index = 6
	add_child(title_plate)
	title_label = UiFactory.label("", 27, UiFactory.INK)
	title_label.position = Vector2(20, 8)
	title_label.size = Vector2(196, 36)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFactory.apply_level_title(title_label, 27)
	title_plate.add_child(title_label)
	detail_label = UiFactory.label("", 12, UiFactory.PRIMARY_DARK)
	detail_label.position = Vector2(20, 45)
	detail_label.size = Vector2(196, 22)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_label.clip_text = true
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_label.add_theme_constant_override("outline_size", 0)
	title_plate.add_child(detail_label)


func _build_animation() -> void:
	preview_hero = HeroRigScene.instantiate()
	preview_hero.position = Vector2(244, 356)
	preview_hero.z_index = 2
	add_child(preview_hero)
	preview_hero.configure("star_warden", 160.0)
	preview_hero.play_state("menu_idle", true)
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


func _play_reveal() -> void:
	if not is_inside_tree():
		return
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	scene_texture.modulate.a = 0.58
	title_plate.modulate.a = 0.55
	preview_hero.scale = Vector2.ONE * 0.94
	_reveal_tween = create_tween().set_parallel(true)
	_reveal_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(scene_texture, "modulate:a", 1.0, 0.24)
	_reveal_tween.tween_property(title_plate, "modulate:a", 1.0, 0.2)
	_reveal_tween.tween_property(preview_hero, "scale", Vector2.ONE, 0.28)


func _gui_input(event: InputEvent) -> void:
	var direction := swipe_gesture.handle(event)
	if direction == 0:
		return
	swipe_requested.emit(direction)
	accept_event()
