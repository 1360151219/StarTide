extends Node2D

signal state_changed
signal stage_banner_requested(title: String, subtitle: String, duration: float)
signal upgrade_requested(player_level: int, choices: Array, upgrade_system: RefCounted, skill_levels: Dictionary)
signal player_hit_feedback_requested(damage: float)
signal finished(presentation: Dictionary)

const RunState = preload("res://scripts/run/run_state.gd")
const StageDirector = preload("res://scripts/run/stage_director.gd")
const RunWorldBuilder = preload("res://scripts/run/run_world_builder.gd")
const RunResultService = preload("res://scripts/run/run_result_service.gd")
const PlayerHitData = preload("res://scripts/combat/player_hit.gd")

var state := RunState.new()
var level: LevelConfig
var records: RefCounted
var audio: Node
var effects: Node2D
var stage_director := StageDirector.new()
var player: Node2D
var camera: Camera2D
var enemies: Node2D
var projectiles: Node2D
var enemy_projectiles: Node2D
var enemy_abilities: Node2D
var pickups: Node2D
var skills: Node2D
var passives: RefCounted
var upgrades: RefCounted
var elite_enemy: Node
var player_invulnerable_until := 0.0


func configure(hero_id: String, level_config: LevelConfig, run_records: RefCounted, audio_manager: Node, combat_effects: Node2D, random_streams: Dictionary) -> void:
	level = level_config
	records = run_records
	audio = audio_manager
	effects = combat_effects
	state.reset(hero_id, level.level_id)
	stage_director.configure(level)
	var progression: Dictionary = records.progression_snapshot(hero_id)
	var nodes := RunWorldBuilder.new().build(self, state, level, stage_director, audio, effects, random_streams, progression)
	player = nodes["player"]
	camera = nodes["camera"]
	enemies = nodes["enemies"]
	projectiles = nodes["projectiles"]
	enemy_projectiles = nodes["enemy_projectiles"]
	enemy_abilities = nodes["enemy_abilities"]
	pickups = nodes["pickups"]
	skills = nodes["skills"]
	passives = nodes["passives"]
	upgrades = nodes["upgrades"]
	enemies.enemy_defeated.connect(_on_enemy_defeated)
	enemy_abilities.player_hit_requested.connect(_apply_player_hit)
	enemy_projectiles.player_hit_requested.connect(_apply_player_hit)
	pickups.experience_collected.connect(add_experience)
	pickups.heal_requested.connect(player.heal)
	enemies.spawn_initial()
	var stage := stage_director.current_stage()
	stage_banner_requested.emit("%s · %s" % [level.display_name, stage.display_name], RunResultService.new().victory_hint(level), 2.6)
	state_changed.emit()


func advance(delta: float, direction: Vector2) -> void:
	if state.finished or state.paused:
		return
	state.elapsed = minf(level.duration, state.elapsed + delta)
	if _resolve_time_boundary():
		return
	_update_stage_events()
	effects.advance(delta)
	var movement: Vector2 = player.move(direction, delta)
	var skill_delta: float = passives.advance(movement, delta, state.elapsed)
	enemies.advance_spawning(delta, state.elapsed)
	enemy_abilities.advance(delta, state.elapsed)
	if state.finished:
		return
	_handle_enemy_contacts()
	if state.finished:
		return
	skills.advance(skill_delta, delta, state.elapsed)
	if state.finished or state.paused:
		return
	projectiles.advance(delta)
	if state.finished or state.paused:
		return
	enemy_projectiles.advance(delta)
	if state.finished or state.paused:
		return
	pickups.advance(delta, state.elapsed)
	state_changed.emit()


func pause() -> void:
	if not state.finished:
		state.paused = true


func resume() -> void:
	if not state.finished:
		state.paused = false


func select_upgrade(choice_id: String) -> void:
	upgrades.apply(choice_id, player, skills)
	state.pending_upgrades -= 1
	if state.pending_upgrades > 0:
		_request_upgrade()
	else:
		state.paused = false
	state_changed.emit()


func add_experience(amount: int) -> void:
	if state.add_experience(amount) > 0 and not state.paused:
		_request_upgrade()


func _update_stage_events() -> void:
	var events := stage_director.advance(state.elapsed)
	var transitions: Array = events["transitions"]
	if not transitions.is_empty():
		var stage: StageConfig = transitions[-1]
		stage_banner_requested.emit(stage.display_name, stage.subtitle, 2.4)
	if events["elite_due"]:
		state.elite_spawned = true
		elite_enemy = enemies.spawn_elite(level.elite, state.elapsed)
		stage_banner_requested.emit("%s · %s降临" % [stage_director.current_stage().display_name, level.elite.display_name], "击败可获得额外赐福与星引磁场", 2.8)


func _handle_enemy_contacts() -> void:
	for enemy in enemies.contact_candidates(state.elapsed):
		if state.elapsed < player_invulnerable_until or state.finished:
			break
		enemies.mark_contact(enemy, state.elapsed)
		var hit := PlayerHitData.create(enemy.damage, enemy, PlayerHitData.CONTACT, enemy.position)
		_apply_player_hit(hit)


func _apply_player_hit(hit: PlayerHit) -> bool:
	if state.finished or state.elapsed < player_invulnerable_until:
		return false
	if passives.try_absorb_hit(hit, state.elapsed):
		player_invulnerable_until = state.elapsed + 0.3
		return true
	player_invulnerable_until = state.elapsed + 0.46
	audio.play_sfx("hero_hurt", 0.0)
	effects.add_damage_number(player.position - Vector2(22, 14), hit.damage, Color("ff6c7f"), true)
	player_hit_feedback_requested.emit(hit.damage)
	_apply_hit_displacement(hit)
	if player.take_damage(hit.damage):
		_finish(false)
	return true


func _apply_hit_displacement(hit: PlayerHit) -> void:
	if hit.can_knockback_source():
		var distance := 36.0 if hit.source.kind == "brute" else 25.0
		hit.source.position += player.position.direction_to(hit.source.position) * distance
	if hit.knockback <= 0.0:
		return
	player.position += hit.origin.direction_to(player.position) * hit.knockback
	var bounds := level.map.world_bounds.grow(-24.0)
	player.position.x = clampf(player.position.x, bounds.position.x, bounds.end.x)
	player.position.y = clampf(player.position.y, bounds.position.y, bounds.end.y)


func _on_enemy_defeated(enemy: Node) -> void:
	state.kills += 1
	pickups.drop_for_enemy(enemy)
	if not enemy.is_elite:
		return
	state.elite_defeated = true
	elite_enemy = null
	pickups.activate_magnet(state.elapsed, level.elite.magnet_duration)
	state.pending_upgrades += level.elite.bonus_upgrade_count
	stage_banner_requested.emit("精英击破", "获得 %d 次额外赐福 · 磁场持续 %d 秒" % [level.elite.bonus_upgrade_count, level.elite.magnet_duration], 2.6)
	if level.victory.mode == VictoryConfig.DEFEAT_ELITE:
		_finish(true)
	elif state.pending_upgrades > 0:
		_request_upgrade()


func _request_upgrade() -> void:
	state.paused = true
	var health_ratio: float = player.health / player.max_health
	var choices: Array = upgrades.build_choices(skills.active_skill_ids, skills.levels, health_ratio)
	upgrade_requested.emit(state.player_level, choices, upgrades, skills.levels)


func _resolve_time_boundary() -> bool:
	if level.victory.is_victory(state.elapsed, level.duration, state.elite_defeated):
		_finish(true)
		return true
	if level.victory.is_timeout_failure(state.elapsed, level.duration, state.elite_defeated):
		_finish(false)
		return true
	return false


func _finish(won: bool) -> void:
	if state.finished:
		return
	state.finished = true
	state.victory = won
	state.paused = true
	enemy_abilities.clear_all()
	enemy_projectiles.clear_all()
	finished.emit(RunResultService.new().finalize(records, state, level, passives))
