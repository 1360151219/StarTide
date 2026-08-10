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
var effects: Node2D
var pickups: Array[Node] = []
var magnet_until := 0.0
var haste_until := 0.0
var drop_counts: Dictionary = {}
var permanent_pickup_radius_multiplier := 1.0


func configure(level_config: LevelConfig, state: RefCounted, build: RefCounted, player_node: Node2D, enemy_system: Node2D, random: RandomNumberGenerator, audio_manager: Node, combat_effects: Node2D, progression: Dictionary = {}) -> void:
	level = level_config
	run_state = state
	build_state = build
	player = player_node
	enemies = enemy_system
	rng = random
	audio = audio_manager
	effects = combat_effects
	magnet_until = 0.0
	haste_until = 0.0
	drop_counts.clear()
	permanent_pickup_radius_multiplier = maxf(1.0, float(progression.get("pickup_radius_multiplier", 1.0)))


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
	var normal_radius: float = level.loot.normal_pickup_radius * permanent_pickup_radius_multiplier
	normal_radius *= build_state.modifier("pickup_radius_multiplier")
	var pickup_radius: float = level.loot.magnet_pickup_radius if active else normal_radius
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup):
			continue
		var distance: float = pickup.position.distance_to(player.position)
		if distance < pickup_radius and not pickup.is_pulling:
			_begin_pull(pickup, distance, pickup_radius)
		if pickup.is_pulling:
			_advance_pull(pickup, delta)
			pickup.z_index = level.map.depth_index(pickup.position.y)
		if pickup.position.distance_to(player.position) <= 28.0:
			_collect(pickup, elapsed)
			if run_state.paused or run_state.finished:
				return


func remaining_magnet_seconds(elapsed: float) -> int:
	return maxi(0, ceili(magnet_until - elapsed))


func _begin_pull(pickup: Node, distance: float, pickup_radius: float) -> void:
	pickup.is_pulling = true
	pickup.pull_origin = pickup.position
	pickup.pull_elapsed = 0.0
	pickup.pull_duration = lerpf(0.18, 0.22, clampf(distance / maxf(pickup_radius, 1.0), 0.0, 1.0))
	pickup.pull_arc_side = -1.0 if pickup.get_instance_id() % 2 == 0 else 1.0


func _advance_pull(pickup: Node, delta: float) -> void:
	pickup.pull_elapsed = minf(pickup.pull_duration, pickup.pull_elapsed + delta)
	var progress: float = pickup.pull_elapsed / maxf(pickup.pull_duration, 0.001)
	var eased := 1.0 - pow(1.0 - progress, 2.0)
	var to_player: Vector2 = player.position - pickup.pull_origin
	var normal := Vector2(-to_player.y, to_player.x).normalized()
	var arc_height: float = minf(28.0, to_player.length() * 0.18) * float(pickup.pull_arc_side)
	var control: Vector2 = Vector2(pickup.pull_origin) + to_player * 0.5 + normal * arc_height
	pickup.position = _quadratic_bezier(pickup.pull_origin, control, player.position, eased)


func _quadratic_bezier(start: Vector2, control: Vector2, finish: Vector2, weight: float) -> Vector2:
	var inverse := 1.0 - weight
	return inverse * inverse * start + 2.0 * inverse * weight * control + weight * weight * finish


func _collect(pickup: Node, elapsed: float) -> void:
	var data := PickupCatalog.pickup(pickup.kind)
	match data.get("effect", ""):
		"experience":
			audio.play_sfx("pickup_xp", -3.0, rng.randf_range(0.97, 1.07))
			effects.add_follow_effect(player, 30.0, data["accent"], 0.3, "pickup_xp")
			experience_collected.emit(pickup.value)
		"heal":
			audio.play_sfx("pickup_heal", -1.0, rng.randf_range(0.98, 1.04))
			effects.add_follow_effect(player, 42.0, data["accent"], 0.52, "pickup_heal")
			effects.add_heal_number(player.position - Vector2(18.0, 34.0), float(data["amount"]))
			heal_requested.emit(float(data["amount"]))
		"magnet":
			audio.play_sfx("pickup_magnet", -1.0)
			effects.add_follow_effect(player, 150.0, data["accent"], 0.62, "pickup_magnet")
			activate_magnet(elapsed, float(data["duration"]))
		"speed_boost":
			audio.play_sfx("pickup_haste", -1.0)
			effects.add_follow_effect(player, 48.0, data["accent"], float(data["duration"]), "pickup_haste")
			haste_until = maxf(haste_until, elapsed + float(data["duration"]))
			player.set_temporary_speed_multiplier(1.0 + float(data["amount"]))
		"area_damage":
			audio.play_sfx("pickup_bomb", 0.0, rng.randf_range(0.97, 1.03))
			effects.add_effect(pickup.position, float(data["effect_radius"]), data["accent"], 0.48, "pickup_bomb")
			enemies.damage_area(pickup.position, float(data["effect_radius"]), float(data["amount"]))
		_:
			audio.play_sfx("pickup", -2.0, rng.randf_range(0.95, 1.08))
	pickup_collected.emit(pickup.kind)
	pickups.erase(pickup)
	pickup.queue_free()
