extends Node2D

const StarRuntime = preload("res://scripts/skills/star_skill_runtime.gd")
const StarVisuals = preload("res://scripts/skills/star_skill_visuals.gd")
const EmberRuntime = preload("res://scripts/skills/ember_skill_runtime.gd")

var active_skill_ids: Array = []
var levels: Dictionary = {}
var build_state: RefCounted
var runtime: Node
var visuals: Node2D
var flash_until: Dictionary = {}
var current_elapsed := 0.0


func configure(hero_id: String, build: RefCounted, player: Node2D, enemies: Node2D, projectiles: Node2D, effects: Node2D, audio: Node, rng: RandomNumberGenerator, progression: Dictionary = {}) -> void:
	build_state = build
	_sync_state()
	runtime = StarRuntime.new() if hero_id == "star_warden" else EmberRuntime.new()
	add_child(runtime)
	runtime.configure(player, enemies, projectiles, effects, audio, rng, levels, progression.get("skill_modifiers", {}), build_state)
	runtime.skill_released.connect(_on_skill_released)
	if hero_id == "star_warden":
		visuals = StarVisuals.new()
		visuals.configure(runtime, player, levels)
		add_child(visuals)


func advance(skill_delta: float, real_delta: float, elapsed: float) -> void:
	current_elapsed = elapsed
	runtime.advance(skill_delta, real_delta, elapsed)
	if is_instance_valid(visuals):
		visuals.refresh()


func sync_after_upgrade(skill_id: String) -> void:
	_sync_state()
	runtime.after_upgrade(skill_id)
	if is_instance_valid(visuals):
		visuals.refresh()


func upgrade(skill_id: String) -> void:
	if levels.has(skill_id):
		levels[skill_id] += 1
		sync_after_upgrade(skill_id)


func cooldown_progress(skill_id: String) -> float:
	return runtime.cooldown_progress(skill_id)


func is_flashing(skill_id: String, elapsed: float) -> bool:
	return elapsed < float(flash_until.get(skill_id, 0.0))


func _sync_state() -> void:
	active_skill_ids = build_state.skill_slots.duplicate()
	levels = build_state.skill_levels


func _on_skill_released(skill_id: String) -> void:
	flash_until[skill_id] = current_elapsed + 0.16
