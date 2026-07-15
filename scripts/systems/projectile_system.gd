extends Node2D

const ProjectileEntity = preload("res://scripts/projectile.gd")

var enemy_system: Node2D
var effects: Node2D
var audio: Node
var rng: RandomNumberGenerator
var projectiles: Array[Node] = []


func configure(enemies: Node2D, combat_effects: Node2D, audio_manager: Node, random: RandomNumberGenerator) -> void:
	enemy_system = enemies
	effects = combat_effects
	audio = audio_manager
	rng = random


func spawn_projectile(config: Dictionary) -> Node:
	var projectile := ProjectileEntity.new()
	projectile.position = config["position"]
	projectile.velocity = Vector2.from_angle(float(config["angle"])) * float(config["speed"])
	projectile.damage = config["damage"]
	projectile.radius = config["radius"]
	projectile.pierce = config["pierce"]
	projectile.blast_radius = config.get("blast_radius", 0.0)
	projectile.visual_kind = config["visual_kind"]
	if projectile.visual_kind == "ember_arrow":
		projectile.trail_color = Color("ff743c")
		projectile.core_color = Color("fff0b0")
		projectile.outline_color = Color("f29a3c")
	add_child(projectile)
	projectiles.append(projectile)
	return projectile


func advance(delta: float) -> void:
	for projectile in projectiles.duplicate():
		if not enemy_system.is_combat_active():
			return
		if not is_instance_valid(projectile):
			continue
		var expired: bool = projectile.advance(delta)
		_resolve_collisions(projectile)
		if expired and projectiles.has(projectile):
			_remove(projectile)


func _resolve_collisions(projectile: Node) -> void:
	for enemy in enemy_system.snapshot():
		if not enemy_system.is_combat_active():
			return
		if not enemy_system.is_active(enemy) or not projectile.can_hit(enemy):
			continue
		var hit_distance: float = enemy.radius + projectile.radius
		if not projectile.intersects_circle(enemy.position, hit_distance):
			continue
		audio.play_sfx("impact", -3.0, rng.randf_range(0.92, 1.08))
		var color := Color("ffbd62") if projectile.visual_kind == "ember_arrow" else Color("a9f6ff")
		enemy_system.damage_enemy(enemy, projectile.damage, color)
		_add_impact_effect(projectile, enemy)
		if projectile.register_hit(enemy):
			_remove(projectile)
			return


func _add_impact_effect(projectile: Node, enemy: Node) -> void:
	if projectile.blast_radius > 0.0:
		enemy_system.damage_area(projectile.position, projectile.blast_radius, projectile.damage * 0.55, enemy)
		effects.add_effect(projectile.position, projectile.blast_radius, Color("ff7a35"), 0.32, "ember")
	elif projectile.visual_kind == "star_lance":
		effects.add_effect(projectile.position, 38.0, Color("75eaff"), 0.26, "star_hit")


func _remove(projectile: Node) -> void:
	projectiles.erase(projectile)
	if is_instance_valid(projectile):
		projectile.queue_free()
