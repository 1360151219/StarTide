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
	projectile.source_id = str(config.get("source_id", "unknown"))
	projectile.skill_level = int(config.get("skill_level", 1))
	projectile.branch_id = str(config.get("branch_id", ""))
	projectile.volley_index = int(config.get("volley_index", 0))
	projectile.volley_count = int(config.get("volley_count", 1))
	projectile.visual_player = config.get("player")
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
	var hits: Array[Dictionary] = []
	for enemy in enemy_system.snapshot():
		if not enemy_system.is_active(enemy) or not projectile.can_hit(enemy):
			continue
		var hit_distance: float = enemy.radius + projectile.radius
		var fraction: float = projectile.collision_fraction(enemy.position, hit_distance)
		if fraction != INF:
			hits.append({"enemy": enemy, "fraction": fraction})
	hits.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return left["fraction"] < right["fraction"])
	for hit in hits:
		if not enemy_system.is_combat_active():
			return
		var enemy: Node = hit["enemy"]
		if not enemy_system.is_active(enemy):
			continue
		var impact: Vector2 = projectile.previous_position.lerp(projectile.position, hit["fraction"])
		var cue_id := "ember_volley_hit" if projectile.visual_kind == "ember_arrow" else "impact"
		audio.play_sfx(cue_id, -3.0, rng.randf_range(0.92, 1.08))
		var color := Color("ffbd62") if projectile.visual_kind == "ember_arrow" else Color("a9f6ff")
		enemy_system.damage_enemy(enemy, projectile.damage, color, projectile.previous_position, projectile.source_id)
		_add_impact_effect(projectile, enemy, impact)
		if projectile.register_hit(enemy):
			_remove(projectile)
			return


func _add_impact_effect(projectile: Node, enemy: Node, impact: Vector2) -> void:
	var direction: Vector2 = projectile.velocity.normalized()
	var visual_data := {
		"direction": direction, "level": projectile.skill_level,
		"branch_id": projectile.branch_id,
	}
	if projectile.visual_kind == "ember_arrow":
		effects.add_effect(impact, 34.0, Color("ff9b3d"), 0.22, "ember_volley_hit", visual_data)
	if projectile.blast_radius > 0.0:
		enemy_system.damage_area(impact, projectile.blast_radius, projectile.damage * 0.55, enemy, projectile.source_id)
		if projectile.volley_count <= 3 or projectile.volley_index < 3:
			effects.add_effect(impact, projectile.blast_radius, Color("ff7a35"), 0.28, "ember_volley_blast", visual_data)
	elif projectile.visual_kind == "star_lance":
		effects.add_effect(impact, 38.0, Color("75eaff"), 0.26, "star_hit", visual_data)


func _remove(projectile: Node) -> void:
	projectiles.erase(projectile)
	if is_instance_valid(projectile):
		projectile.queue_free()
