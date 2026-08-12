extends RefCounted

signal hit_feedback_requested(damage: float, source_direction: Vector2)
signal damage_applied(source_id: String, attempted: float, applied: float)
signal damage_absorbed(source_id: String, amount: float)
signal hit_rejected(source_id: String, reason: String)

const PlayerHitData = preload("res://scripts/combat/player_hit.gd")

var player: Node2D
var level: LevelConfig
var passives: RefCounted
var effects: Node2D
var audio: Node
var invulnerable_until := 0.0
var player_defeated := false
var rejected_contact_until: Dictionary = {}


func configure(player_node: Node2D, level_config: LevelConfig, passive_controller: RefCounted, combat_effects: Node2D, audio_manager: Node) -> void:
	player = player_node
	level = level_config
	passives = passive_controller
	effects = combat_effects
	audio = audio_manager
	invulnerable_until = 0.0
	player_defeated = false
	rejected_contact_until.clear()


func apply_contacts(enemies: Node2D, state: RefCounted) -> void:
	for enemy in enemies.contact_candidates(state.elapsed):
		if state.finished:
			break
		if state.elapsed < invulnerable_until:
			var enemy_id: int = enemy.get_instance_id()
			if state.elapsed >= float(rejected_contact_until.get(enemy_id, 0.0)):
				hit_rejected.emit("contact:%s" % str(enemy.kind), "invulnerable")
				rejected_contact_until[enemy_id] = state.elapsed + 0.75
			break
		enemies.mark_contact(enemy, state.elapsed)
		rejected_contact_until.erase(enemy.get_instance_id())
		apply(PlayerHitData.create(enemy.damage, enemy, PlayerHitData.CONTACT, enemy.position), state.elapsed, state.finished)
		if player_defeated:
			return


func apply(hit: PlayerHit, elapsed: float, finished: bool) -> bool:
	if finished:
		return false
	if elapsed < invulnerable_until:
		hit_rejected.emit(hit.telemetry_source_id(), "invulnerable")
		return false
	if passives.try_absorb_hit(hit, elapsed):
		damage_absorbed.emit(hit.telemetry_source_id(), maxf(0.0, hit.damage))
		invulnerable_until = elapsed + 0.3
		return true
	var applied_damage := minf(maxf(0.0, hit.damage), player.health)
	invulnerable_until = elapsed + 0.46
	audio.play_sfx("hero_hurt", 0.0)
	var source_direction := player.position.direction_to(hit.origin)
	effects.add_damage_number(_player_damage_position(source_direction), hit.damage, Color("ff6c7f"), true)
	hit_feedback_requested.emit(hit.damage, source_direction)
	_apply_displacement(hit)
	player_defeated = player.take_damage(hit.damage)
	damage_applied.emit(hit.telemetry_source_id(), maxf(0.0, hit.damage), applied_damage)
	return true


func grant_invulnerability(elapsed: float, duration: float) -> void:
	invulnerable_until = maxf(invulnerable_until, elapsed + maxf(0.0, duration))


func is_invulnerable(elapsed: float) -> bool:
	return elapsed < invulnerable_until


func _apply_displacement(hit: PlayerHit) -> void:
	if hit.can_knockback_source():
		var distance := 36.0 if hit.source.kind == "brute" else 25.0
		hit.source.position += player.position.direction_to(hit.source.position) * distance
	if hit.knockback <= 0.0:
		return
	player.position += hit.origin.direction_to(player.position) * hit.knockback
	var bounds := level.map.world_bounds.grow(-24.0)
	player.position.x = clampf(player.position.x, bounds.position.x, bounds.end.x)
	player.position.y = clampf(player.position.y, bounds.position.y, bounds.end.y)


func _player_damage_position(source_direction: Vector2) -> Vector2:
	var away := -source_direction.normalized() if source_direction.length_squared() > 0.0001 else Vector2.RIGHT
	return player.position + Vector2(away.x * 34.0 - 16.0, 48.0 + away.y * 10.0)
