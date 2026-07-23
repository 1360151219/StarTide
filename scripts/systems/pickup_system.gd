extends Node2D

signal experience_collected(amount: int)
signal heal_requested(amount: float)
signal pickup_collected(pickup_id: String)

const PickupEntity = preload("res://scripts/pickup.gd")
const PickupCatalog = preload("res://scripts/pickup_catalog.gd")

var level: LevelConfig
var run_state: RefCounted
var build_state: RefCounted
var player: Node2D
var enemies: Node2D
var rng: RandomNumberGenerator
var audio: Node
var pickups: Array[Node] = []
var magnet_until := 0.0
var haste_until := 0.0
var drop_counts: Dictionary = {}


func configure(level_config: LevelConfig, state: RefCounted, build: RefCounted, player_node: Node2D, enemy_system: Node2D, random: RandomNumberGenerator, audio_manager: Node) -> void:
	level = level_config
	run_state = state
	build_state = build
	player = player_node
	enemies = enemy_system
	rng = random
	audio = audio_manager
	magnet_until = 0.0
	haste_until = 0.0
	drop_counts.clear()


func drop_for_enemy(enemy: Node) -> void:
	var experience := maxi(1, roundi(enemy.experience * level.loot.experience_multiplier))
	spawn_pickup("xp", enemy.position, experience)
	if enemy.is_elite:
		return
	var roll := rng.randf()
	var cumulative := 0.0
	for entry in level.loot.bonus_entries:
		if int(drop_counts.get(entry.pickup_id, 0)) >= entry.max_per_run:
			continue
		cumulative += entry.chance
		if roll > cumulative:
			continue
		drop_counts[entry.pickup_id] = int(drop_counts.get(entry.pickup_id, 0)) + 1
		var offset := Vector2(12.0 if drop_counts.size() % 2 == 0 else -12.0, 0.0)
		spawn_pickup(entry.pickup_id, enemy.position + offset, 1)
		return


func spawn_pickup(kind: String, spawn_position: Vector2, value: int) -> Node:
	var pickup := PickupEntity.new()
	pickup.kind = kind
	pickup.value = value
	pickup.position = spawn_position
	pickup.radius = float(PickupCatalog.pickup(kind).get("radius", 13.0))
	pickup.z_index = level.map.depth_index(pickup.position.y)
	add_child(pickup)
	pickups.append(pickup)
	return pickup


func activate_magnet(elapsed: float, duration: float) -> void:
	magnet_until = maxf(magnet_until, elapsed + duration)


func advance(delta: float, elapsed: float) -> void:
	if run_state.paused or run_state.finished:
		return
	if haste_until > 0.0 and elapsed >= haste_until:
		haste_until = 0.0
		player.set_temporary_speed_multiplier(1.0)
	var active := elapsed < magnet_until
	var normal_radius: float = level.loot.normal_pickup_radius * build_state.modifier("pickup_radius_multiplier")
	var pickup_radius: float = level.loot.magnet_pickup_radius if active else normal_radius
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
	var data := PickupCatalog.pickup(pickup.kind)
	match data.get("effect", ""):
		"experience":
			experience_collected.emit(pickup.value)
		"heal":
			heal_requested.emit(float(data["amount"]))
		"magnet":
			activate_magnet(elapsed, float(data["duration"]))
		"speed_boost":
			haste_until = maxf(haste_until, elapsed + float(data["duration"]))
			player.set_temporary_speed_multiplier(1.0 + float(data["amount"]))
		"area_damage":
			enemies.damage_area(pickup.position, float(data["effect_radius"]), float(data["amount"]))
	pickup_collected.emit(pickup.kind)
	pickups.erase(pickup)
	pickup.queue_free()
