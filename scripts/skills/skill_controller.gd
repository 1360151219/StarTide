extends Node2D

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const StarRuntime = preload("res://scripts/skills/star_skill_runtime.gd")
const StarVisuals = preload("res://scripts/skills/star_skill_visuals.gd")
const EmberRuntime = preload("res://scripts/skills/ember_skill_runtime.gd")

var active_skill_ids: Array = []
var levels: Dictionary = {}
var runtime: Node
var visuals: Node2D
var flash_until: Dictionary = {}
var current_elapsed := 0.0


func configure(hero_id: String, player: Node2D, enemies: Node2D, projectiles: Node2D, effects: Node2D, audio: Node, rng: RandomNumberGenerator, progression: Dictionary = {}) -> void:
	active_skill_ids = HeroCatalog.hero(hero_id)["skills"].duplicate()
	levels.clear()
	for skill_id in active_skill_ids:
		levels[skill_id] = 0
	levels[active_skill_ids[0]] = 1
	runtime = StarRuntime.new() if hero_id == "star_warden" else EmberRuntime.new()
	add_child(runtime)
	runtime.configure(player, enemies, projectiles, effects, audio, rng, levels, progression.get("skill_modifiers", {}))
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


func upgrade(skill_id: String) -> void:
	levels[skill_id] += 1
	runtime.after_upgrade(skill_id)


func cooldown_progress(skill_id: String) -> float:
	return runtime.cooldown_progress(skill_id)


func is_flashing(skill_id: String, elapsed: float) -> bool:
	return elapsed < float(flash_until.get(skill_id, 0.0))


func _on_skill_released(skill_id: String) -> void:
	flash_until[skill_id] = current_elapsed + 0.16
