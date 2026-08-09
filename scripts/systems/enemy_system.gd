extends Node2D

signal enemy_defeated(enemy: Node)
signal enemy_spawned(enemy: Node)
signal enemy_removed(enemy: Node)

const EnemyEntity = preload("res://scripts/enemy.gd")
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemySpawner = preload("res://scripts/systems/enemy_spawner.gd")

var level: LevelConfig
var run_state: RefCounted
var player: Node2D
var stage_director: RefCounted
var rng: RandomNumberGenerator
var effects: Node2D
var audio: Node
var spawner := EnemySpawner.new()
var enemies: Array[Node] = []
var next_spawn_serial := 0


func configure(level_config: LevelConfig, state: RefCounted, player_node: Node2D, director: RefCounted, random: RandomNumberGenerator, combat_effects: Node2D, audio_manager: Node) -> void:
	level = level_config
	run_state = state
	player = player_node
	stage_director = director
	rng = random
	effects = combat_effects
	audio = audio_manager
	spawner.configure(level, stage_director, rng)
	next_spawn_serial = 0


func spawn_initial() -> void:
	for _index in range(level.initial_enemy_count):
		_spawn_next_enemy(0.0)


func advance_spawning(delta: float, elapsed: float) -> void:
	for _index in range(spawner.next_spawn_count(delta, elapsed, enemies.size())):
		_spawn_next_enemy(elapsed)


func active_ranged_count() -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and EnemyCatalog.is_ranged(enemy.kind):
			count += 1
	return count


func active_counts_by_kind() -> Dictionary:
	var counts: Dictionary = {}
	for enemy in enemies:
		if is_instance_valid(enemy):
			counts[enemy.kind] = int(counts.get(enemy.kind, 0)) + 1
	return counts


func _spawn_next_enemy(elapsed: float) -> Node:
	var enemy_id := spawner.roll_enemy_id(active_counts_by_kind(), active_ranged_count())
	if enemy_id.is_empty():
		return null
	return spawn_enemy(enemy_id, null, elapsed)


func spawn_enemy(enemy_id: String, elite_config: EliteConfig = null, elapsed := 0.0) -> Node:
	var enemy := EnemyEntity.new()
	var scaling := level.difficulty.multipliers_at(elapsed, level.duration)
	var stage_entry: EnemySpawnEntryConfig = stage_director.current_stage().entry_for(enemy_id)
	var ability_id: String = stage_entry.ability_variant_id if stage_entry != null else ""
	var viewport := get_viewport()
	var viewport_size := viewport.get_visible_rect().size if viewport != null else Vector2.ZERO
	enemy.position = spawner.spawn_position(player.position, elite_config != null, viewport_size)
	enemy.configure(enemy_id, scaling, elite_config, ability_id)
	enemy.spawn_serial = next_spawn_serial
	next_spawn_serial += 1
	enemy.z_index = level.map.depth_index(enemy.position.y)
	add_child(enemy)
	enemies.append(enemy)
	enemy_spawned.emit(enemy)
	return enemy


func spawn_elite(config: EliteConfig, elapsed: float) -> Node:
	if EnemyCatalog.is_ranged(config.enemy_id):
		while active_ranged_count() >= level.max_ranged_enemies and _remove_non_elite_ranged():
			pass
	if enemies.size() >= level.max_enemies:
		for candidate in enemies.duplicate():
			if not candidate.is_elite:
				remove_enemy(candidate)
				break
	return spawn_enemy(config.enemy_id, config, elapsed)


func _remove_non_elite_ranged() -> bool:
	for candidate in enemies.duplicate():
		if is_instance_valid(candidate) and not candidate.is_elite and EnemyCatalog.is_ranged(candidate.kind):
			remove_enemy(candidate)
			return true
	return false


func advance_movement(delta: float, elapsed: float) -> void:
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.advance(player.position, delta, elapsed)
			enemy.z_index = level.map.depth_index(enemy.position.y)


func snapshot() -> Array[Node]:
	return enemies.duplicate()


func is_active(enemy: Node) -> bool:
	return is_instance_valid(enemy) and enemies.has(enemy)


func is_combat_active() -> bool:
	return not run_state.paused and not run_state.finished


func contact_candidates(elapsed: float) -> Array[Node]:
	var result: Array[Node] = []
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.contact_enabled or elapsed < enemy.next_contact_time:
			continue
		var contact_distance: float = enemy.radius + 21.0
		if enemy.position.distance_squared_to(player.position) <= contact_distance * contact_distance:
			result.append(enemy)
	return result


func mark_contact(enemy: Node, elapsed: float) -> void:
	enemy.next_contact_time = elapsed + 0.75


func nearest_enemy(from_position: Vector2) -> Node:
	var nearest: Node
	var nearest_distance := INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance: float = from_position.distance_squared_to(enemy.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest


func damage_area(center: Vector2, radius: float, damage: float, excluded: Node = null) -> void:
	if not is_combat_active():
		return
	for enemy in enemies.duplicate():
		if not is_combat_active():
			return
		if is_instance_valid(enemy) and enemy != excluded and enemy.position.distance_to(center) <= radius + enemy.radius:
			damage_enemy(enemy, damage, Color("ffb45c"))


func damage_enemy(enemy: Node, damage: float, number_color := Color("e6fbff")) -> void:
	if not is_combat_active() or not is_active(enemy):
		return
	effects.add_damage_number(enemy.position - Vector2(18, enemy.radius + 4.0), damage, number_color, false, enemy.get_instance_id())
	if enemy.take_damage(damage):
		audio.play_sfx("enemy_defeat", -2.0, rng.randf_range(0.9, 1.1))
		var defeat_kind := "grub_defeat" if enemy.kind == "green_grub" else "defeat"
		effects.add_effect(enemy.position, enemy.radius + 24.0, enemy.color, 0.42, defeat_kind)
		enemy_defeated.emit(enemy)
		remove_enemy(enemy)


func remove_enemy(enemy: Node) -> void:
	enemies.erase(enemy)
	if is_instance_valid(enemy):
		enemy_removed.emit(enemy)
		enemy.queue_free()
