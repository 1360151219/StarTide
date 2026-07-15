extends Node

signal skill_released(skill_id: String)

const HeroCatalog = preload("res://scripts/hero_catalog.gd")

var player: Node2D
var enemies: Node2D
var projectiles: Node2D
var effects: Node2D
var audio: Node
var rng: RandomNumberGenerator
var levels: Dictionary
var volley_timer := 0.25
var meteor_timer := 1.0
var phoenix_timer := 1.0


func configure(player_node: Node2D, enemy_system: Node2D, projectile_system: Node2D, combat_effects: Node2D, audio_manager: Node, random: RandomNumberGenerator, skill_levels: Dictionary) -> void:
	player = player_node
	enemies = enemy_system
	projectiles = projectile_system
	effects = combat_effects
	audio = audio_manager
	rng = random
	levels = skill_levels


func advance(skill_delta: float, _real_delta: float, _elapsed: float) -> void:
	_update_ember_volley(skill_delta)
	_update_meteor_rain(skill_delta)
	_update_phoenix_heart(skill_delta)


func after_upgrade(skill_id: String) -> void:
	if skill_id == "meteor_rain":
		meteor_timer = minf(meteor_timer, 0.3)
	elif skill_id == "phoenix_heart":
		phoenix_timer = minf(phoenix_timer, 0.3)


func cooldown_progress(skill_id: String) -> float:
	var skill_level: int = levels.get(skill_id, 0)
	if skill_level <= 0:
		return 0.0
	var data: Dictionary = HeroCatalog.skill(skill_id)["runtime"]
	var timer := volley_timer
	if skill_id == "meteor_rain":
		timer = meteor_timer
	elif skill_id == "phoenix_heart":
		timer = phoenix_timer
	return clampf(1.0 - maxf(timer, 0.0) / float(data["cooldown"][skill_level]), 0.0, 1.0)


func _update_ember_volley(delta: float) -> void:
	var skill_level: int = levels.get("ember_volley", 0)
	if skill_level <= 0:
		return
	volley_timer -= delta
	if volley_timer > 0.0:
		return
	var data: Dictionary = HeroCatalog.skill("ember_volley")["runtime"]
	volley_timer = data["cooldown"][skill_level]
	var target: Node = enemies.nearest_enemy(player.position)
	if target == null:
		return
	var base_angle: float = player.position.direction_to(target.position).angle()
	for index in range(data["count"][skill_level]):
		var spread: float = (index - (data["count"][skill_level] - 1) * 0.5) * data["spread"][skill_level]
		projectiles.spawn_projectile({
			"position": player.position, "angle": base_angle + spread, "speed": data["speed"][skill_level],
			"damage": data["damage"][skill_level], "radius": data["radius"][skill_level],
			"pierce": data["pierce"][skill_level], "blast_radius": data["blast_radius"][skill_level],
			"visual_kind": "ember_arrow",
		})
	skill_released.emit("ember_volley")
	audio.play_sfx("skill_ember_volley", -1.0, rng.randf_range(0.95, 1.05))


func _update_meteor_rain(delta: float) -> void:
	var skill_level: int = levels.get("meteor_rain", 0)
	if skill_level <= 0:
		return
	meteor_timer -= delta
	if meteor_timer > 0.0:
		return
	var data: Dictionary = HeroCatalog.skill("meteor_rain")["runtime"]
	meteor_timer = data["cooldown"][skill_level]
	skill_released.emit("meteor_rain")
	audio.play_sfx("skill_meteor_rain", 1.0, rng.randf_range(0.96, 1.03))
	var candidates: Array[Vector2] = []
	for enemy in enemies.snapshot():
		if is_instance_valid(enemy):
			candidates.append(enemy.position)
	_shuffle(candidates)
	for index in range(mini(data["count"][skill_level], candidates.size())):
		enemies.damage_area(candidates[index], data["radius"][skill_level], data["damage"][skill_level])
		effects.add_effect(candidates[index], data["radius"][skill_level], Color("ff7a35"), 0.72, "meteor")


func _update_phoenix_heart(delta: float) -> void:
	var skill_level: int = levels.get("phoenix_heart", 0)
	if skill_level <= 0:
		return
	phoenix_timer -= delta
	if phoenix_timer > 0.0:
		return
	var data: Dictionary = HeroCatalog.skill("phoenix_heart")["runtime"]
	phoenix_timer = data["cooldown"][skill_level]
	skill_released.emit("phoenix_heart")
	audio.play_sfx("skill_phoenix_heart", 0.0, rng.randf_range(0.97, 1.03))
	player.heal(data["healing"][skill_level])
	enemies.damage_area(player.position, data["radius"][skill_level], data["damage"][skill_level])
	effects.add_effect(player.position, data["radius"][skill_level], Color("ff9b3d"), 0.55, "phoenix")


func _shuffle(values: Array[Vector2]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
