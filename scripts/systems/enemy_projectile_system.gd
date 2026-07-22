extends Node2D

signal player_hit_requested(hit: PlayerHit)

const EnemyProjectile = preload("res://scripts/enemy_projectile.gd")
const PlayerHitData = preload("res://scripts/combat/player_hit.gd")

var player: Node2D
var max_projectiles := 2
var projectiles: Array[Node] = []


func configure(player_node: Node2D, projectile_limit: int) -> void:
	player = player_node
	max_projectiles = projectile_limit


func spawn_bolt(source: Node, origin: Vector2, direction: Vector2, config: Dictionary, damage_multiplier: float) -> Node:
	if projectiles.size() >= max_projectiles or direction.is_zero_approx():
		return null
	var projectile := EnemyProjectile.new()
	projectile.source = source
	projectile.position = origin
	projectile.velocity = direction.normalized() * float(config["projectile_speed"])
	projectile.damage = float(config["damage"]) * damage_multiplier
	projectile.radius = float(config["projectile_radius"])
	projectile.max_distance = float(config["projectile_distance"])
	add_child(projectile)
	projectiles.append(projectile)
	return projectile


func advance(delta: float) -> void:
	for projectile in projectiles.duplicate():
		if not projectiles.has(projectile):
			continue
		if not is_instance_valid(projectile):
			projectiles.erase(projectile)
			continue
		var expired: bool = projectile.advance(delta)
		if projectile.intersects_circle(player.position, projectile.radius + 21.0):
			var hit := PlayerHitData.create(projectile.damage, projectile.source, PlayerHitData.BAT_BOLT, projectile.position)
			player_hit_requested.emit(hit)
			_remove(projectile)
		elif expired:
			_remove(projectile)


func clear_all() -> void:
	for projectile in projectiles.duplicate():
		_remove(projectile)


func _remove(projectile: Node) -> void:
	projectiles.erase(projectile)
	if is_instance_valid(projectile):
		projectile.queue_free()
