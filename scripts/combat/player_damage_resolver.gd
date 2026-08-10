extends RefCounted

signal hit_feedback_requested(damage: float, source_direction: Vector2)

const PlayerHitData = preload("res://scripts/combat/player_hit.gd")

var player: Node2D
var level: LevelConfig
var passives: RefCounted
var effects: Node2D
var audio: Node
var invulnerable_until := 0.0
var player_defeated := false


func configure(player_node: Node2D, level_config: LevelConfig, passive_controller: RefCounted, combat_effects: Node2D, audio_manager: Node) -> void:
	player = player_node
	level = level_config
	passives = passive_controller
	effects = combat_effects
	audio = audio_manager
	invulnerable_until = 0.0
	player_defeated = false


func apply_contacts(enemies: Node2D, state: RefCounted) -> void:
	for enemy in enemies.contact_candidates(state.elapsed):
		if state.elapsed < invulnerable_until or state.finished:
			break
		enemies.mark_contact(enemy, state.elapsed)
		apply(PlayerHitData.create(enemy.damage, enemy, PlayerHitData.CONTACT, enemy.position), state.elapsed, state.finished)
		if player_defeated:
			return


func apply(hit: PlayerHit, elapsed: float, finished: bool) -> bool:
	if finished or elapsed < invulnerable_until:
		return false
	if passives.try_absorb_hit(hit, elapsed):
		invulnerable_until = elapsed + 0.3
		return true
	invulnerable_until = elapsed + 0.46
	audio.play_sfx("hero_hurt", 0.0)
	effects.add_damage_number(player.position - Vector2(22, 14), hit.damage, Color("ff6c7f"), true)
	hit_feedback_requested.emit(hit.damage, player.position.direction_to(hit.origin))
	_apply_displacement(hit)
	player_defeated = player.take_damage(hit.damage)
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
