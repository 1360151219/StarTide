extends Node2D

signal experience_collected(amount: int)
signal heal_requested(amount: float)

const PickupEntity = preload("res://scripts/pickup.gd")

var level: LevelConfig
var run_state: RefCounted
var player: Node2D
var rng: RandomNumberGenerator
var audio: Node
var pickups: Array[Node] = []
var magnet_until := 0.0
var heart_drops := 0


func configure(level_config: LevelConfig, state: RefCounted, player_node: Node2D, random: RandomNumberGenerator, audio_manager: Node) -> void:
	level = level_config
	run_state = state
	player = player_node
	rng = random
	audio = audio_manager
	magnet_until = 0.0
	heart_drops = 0


func drop_for_enemy(enemy: Node) -> void:
	spawn_pickup("xp", enemy.position, enemy.experience)
	if enemy.is_elite:
		return
	var roll := rng.randf()
	if roll < level.loot.heart_drop_chance and heart_drops < level.loot.max_heart_drops:
		heart_drops += 1
		spawn_pickup("heart", enemy.position + Vector2(12, 0), level.loot.heart_value)
	elif roll < level.loot.heart_drop_chance + level.loot.magnet_drop_chance:
		spawn_pickup("magnet", enemy.position + Vector2(-12, 0), 1)


func spawn_pickup(kind: String, spawn_position: Vector2, value: int) -> Node:
	var pickup := PickupEntity.new()
	pickup.kind = kind
	pickup.value = value
	pickup.position = spawn_position
	pickup.radius = 13.0 if kind != "xp" else 8.0
	pickup.z_index = level.map.depth_index(pickup.position.y)
	add_child(pickup)
	pickups.append(pickup)
	return pickup


func activate_magnet(elapsed: float, duration: float) -> void:
	magnet_until = maxf(magnet_until, elapsed + duration)


func advance(delta: float, elapsed: float) -> void:
	if run_state.paused or run_state.finished:
		return
	var active := elapsed < magnet_until
	var pickup_radius: float = level.loot.magnet_pickup_radius if active else level.loot.normal_pickup_radius
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup):
			continue
		var distance: float = pickup.position.distance_to(player.position)
		if distance < pickup_radius:
			var pull_speed := 760.0 if active else lerpf(140.0, 520.0, 1.0 - distance / pickup_radius)
			pickup.position = pickup.position.move_toward(player.position, pull_speed * delta)
			pickup.z_index = level.map.depth_index(pickup.position.y)
		if pickup.position.distance_to(player.position) <= 28.0:
			_collect(pickup, elapsed)
			if run_state.paused or run_state.finished:
				return


func remaining_magnet_seconds(elapsed: float) -> int:
	return maxi(0, ceili(magnet_until - elapsed))


func _collect(pickup: Node, elapsed: float) -> void:
	audio.play_sfx("pickup", -2.0, rng.randf_range(0.95, 1.08))
	if pickup.kind == "heart":
		heal_requested.emit(float(pickup.value))
	elif pickup.kind == "magnet":
		activate_magnet(elapsed, level.loot.magnet_duration)
	else:
		experience_collected.emit(pickup.value)
	pickups.erase(pickup)
	pickup.queue_free()
