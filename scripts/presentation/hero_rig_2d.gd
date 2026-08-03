class_name HeroRig2D
extends Node2D

signal animation_state_changed(state_name: String)

const SpriteCatalog = preload("res://scripts/presentation/hero_sprite_catalog.gd")

@export var hero_id := SpriteCatalog.DEFAULT_HERO_ID
@export_range(24.0, 360.0, 1.0) var display_height := 120.0

var current_state := "idle"
var layered_skin := false
var facing_direction := Vector2.DOWN
var facing_scale := 1.0
var target_facing_scale := 1.0
var movement_amount := 0.0
var action_time_left := 0.0
var return_state := "idle"
var menu_mode := false
var runtime_built := false
var skin_configured := false
var animation_active := true
var animation_clock := 0.0
var turn_width := 1.0
var visual_root: Node2D
var sprite: AnimatedSprite2D


func _ready() -> void:
	_ensure_runtime()
	if not skin_configured:
		configure(hero_id, display_height)


func _process(delta: float) -> void:
	animation_clock += delta
	turn_width = move_toward(turn_width, 1.0, delta * 1.25)
	_apply_procedural_motion()
	if action_time_left <= 0.0:
		return
	action_time_left = maxf(0.0, action_time_left - delta)
	if action_time_left <= 0.0:
		play_state(return_state, true)


func configure(
	selected_hero_id: String,
	requested_height := -1.0,
	texture_overrides := {},
	allow_generated_assets := true
) -> void:
	_ensure_runtime()
	hero_id = SpriteCatalog.normalized_hero_id(selected_hero_id)
	if requested_height > 0.0:
		display_height = requested_height
	sprite.sprite_frames = SpriteCatalog.build_frames(
		hero_id,
		texture_overrides,
		allow_generated_assets
	)
	skin_configured = true
	layered_skin = false
	set_display_height(display_height)
	_apply_view()
	play_state("menu_idle" if menu_mode else "idle", true)


func set_display_height(height: float) -> void:
	display_height = maxf(24.0, height)
	_apply_procedural_motion()


func set_motion(direction: Vector2, amount: float) -> void:
	movement_amount = clampf(amount, 0.0, 1.0)
	if direction.length_squared() > 0.01:
		set_facing(direction)
	if action_time_left > 0.0 or menu_mode:
		return
	play_state("run" if movement_amount > 0.05 else "idle")


func set_facing(direction: Vector2) -> void:
	if direction.length_squared() <= 0.01:
		return
	facing_direction = direction.normalized()
	if absf(facing_direction.x) <= 0.28:
		return
	var requested_scale := -1.0 if facing_direction.x < 0.0 else 1.0
	if requested_scale != facing_scale:
		turn_width = 0.85
	facing_scale = requested_scale
	target_facing_scale = facing_scale
	_apply_view()
	_apply_procedural_motion()


func play_state(state_name: String, restart := false) -> bool:
	if not SpriteCatalog.STATES.has(state_name):
		return false
	if state_name == current_state and not restart:
		return true
	current_state = state_name
	if state_name == "menu_idle":
		menu_mode = true
		return_state = "menu_idle"
	elif state_name == "idle" or state_name == "run":
		menu_mode = false
		return_state = state_name
	if SpriteCatalog.ACTION_DURATIONS.has(state_name):
		action_time_left = float(SpriteCatalog.ACTION_DURATIONS[state_name])
		return_state = "menu_idle" if menu_mode else (
			"run" if movement_amount > 0.05 else "idle"
		)
	else:
		action_time_left = 0.0
	_play_animation(state_name, restart)
	animation_state_changed.emit(state_name)
	return true


func trigger_menu_react() -> void:
	menu_mode = true
	play_state("menu_react", true)


func trigger_cast() -> void:
	play_state("cast", true)


func trigger_hit() -> void:
	play_state("hit", true)


func trigger_victory() -> void:
	play_state("victory", true)


func set_hurt_active(active: bool) -> void:
	modulate = Color("ffd6dc") if active else Color.WHITE


func set_active(active: bool) -> void:
	animation_active = active
	set_process(active)
	if not is_instance_valid(sprite):
		return
	if active:
		sprite.play()
	else:
		sprite.pause()


func is_layered() -> bool:
	return layered_skin


func part_count() -> int:
	return 1 if is_instance_valid(sprite) else 0


func articulated_component_count() -> int:
	return part_count()


func available_states() -> PackedStringArray:
	return PackedStringArray(SpriteCatalog.STATES)


func preview_bind_pose() -> void:
	action_time_left = 0.0
	play_state("idle", true)
	set_active(false)


func set_debug_skeleton_visible(_value: bool) -> void:
	pass


func set_debug_selected_bone(_bone_id: String) -> void:
	pass


func _ensure_runtime() -> void:
	if runtime_built:
		return
	runtime_built = true
	visual_root = Node2D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	sprite = AnimatedSprite2D.new()
	sprite.name = "HeroSprite"
	sprite.centered = false
	sprite.position = Vector2(
		-SpriteCatalog.FRAME_SIZE.x * 0.5,
		-SpriteCatalog.FOOT_BASELINE
	)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual_root.add_child(sprite)


func _apply_view() -> void:
	if is_instance_valid(sprite):
		sprite.flip_h = facing_scale < 0.0


func _play_animation(state_name: String, restart: bool) -> void:
	if not is_instance_valid(sprite) or sprite.sprite_frames == null:
		return
	var animation_name := StringName(state_name)
	if not sprite.sprite_frames.has_animation(animation_name):
		return
	if restart:
		sprite.stop()
		sprite.animation = animation_name
		sprite.frame = 0
		sprite.frame_progress = 0.0
	if animation_active:
		sprite.play(animation_name)


func _apply_procedural_motion() -> void:
	if not is_instance_valid(visual_root):
		return
	var base_scale := display_height / SpriteCatalog.ART_HEIGHT
	var scale_offset := Vector2.ONE
	var vertical_offset := 0.0
	var rotation_offset := 0.0
	if current_state == "menu_idle":
		var phase := animation_clock * TAU / 3.0
		vertical_offset = -1.8 * (0.5 - 0.5 * cos(phase))
		scale_offset = Vector2(1.0 - sin(phase) * 0.004, 1.0 + sin(phase) * 0.008)
	elif current_state == "idle":
		var phase := animation_clock * TAU / 1.8
		vertical_offset = -0.8 * (0.5 - 0.5 * cos(phase))
		scale_offset = Vector2(1.0 - sin(phase) * 0.003, 1.0 + sin(phase) * 0.006)
	elif current_state == "run":
		var phase := animation_clock * TAU / 0.52
		vertical_offset = -2.2 * absf(sin(phase))
		rotation_offset = sin(phase) * 0.012
	scale_offset.x *= turn_width
	visual_root.position = Vector2(0.0, vertical_offset)
	visual_root.rotation = rotation_offset
	visual_root.scale = scale_offset * base_scale
