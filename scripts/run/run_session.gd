extends Node2D

signal state_changed
signal stage_banner_requested(title: String, subtitle: String, duration: float)
signal upgrade_requested(player_level: int, choices: Array, upgrade_system: RefCounted, build_state: RefCounted)
signal player_hit_feedback_requested(damage: float, source_direction: Vector2)
signal pickup_collected(pickup_id: String)
signal finished(presentation: Dictionary)

const RunState = preload("res://scripts/run/run_state.gd")
const StageDirector = preload("res://scripts/run/stage_director.gd")
const RunWorldBuilder = preload("res://scripts/run/run_world_builder.gd")
const RunResultService = preload("res://scripts/run/run_result_service.gd")
const PlayerDamageResolver = preload("res://scripts/combat/player_damage_resolver.gd")
const RunBuildState = preload("res://scripts/run/run_build_state.gd")
const RunContentResolver = preload("res://scripts/run/run_content_resolver.gd")
const UpgradeSystem = preload("res://scripts/systems/upgrade_system.gd")
const RunSafetyController = preload("res://scripts/run/run_safety_controller.gd")

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
var build_state: RefCounted
var skill_pool_ids := PackedStringArray()
var relic_pool_ids := PackedStringArray()
var skill_pool_weights: Dictionary = {}
var relic_pool_weights: Dictionary = {}
var elite_enemy: Node
var damage_resolver := PlayerDamageResolver.new()
var safety := RunSafetyController.new()
func configure(hero_id: String, level_config: LevelConfig, run_records: RefCounted, audio_manager: Node, combat_effects: Node2D, random_streams: Dictionary) -> void:
	level = level_config
	records = run_records
	records.clear_new_content_discoveries()
	audio = audio_manager
	effects = combat_effects
	state.reset(hero_id, level.level_id)
	build_state = RunBuildState.new(hero_id)
	var content_pool := RunContentResolver.resolve(level.level_id, hero_id, records, random_streams["upgrade"])
	skill_pool_ids = content_pool["skill_ids"]
	relic_pool_ids = content_pool["relic_ids"]
	skill_pool_weights = content_pool["skill_weights"]
	relic_pool_weights = content_pool["relic_weights"]
	stage_director.configure(level)
	var progression: Dictionary = records.progression_snapshot(hero_id)
	var nodes := RunWorldBuilder.new().build(self, state, build_state, level, stage_director, audio, effects, random_streams, progression)
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
	damage_resolver.configure(player, level, passives, effects, audio)
	safety.reset()
	damage_resolver.hit_feedback_requested.connect(player_hit_feedback_requested.emit)
	enemies.enemy_defeated.connect(_on_enemy_defeated)
	enemies.enemy_spawned.connect(func(enemy: Node) -> void: records.discover_content("enemies", enemy.kind))
	enemy_abilities.player_hit_requested.connect(_apply_player_hit)
	enemy_projectiles.player_hit_requested.connect(_apply_player_hit)
	pickups.experience_collected.connect(add_experience)
	pickups.heal_requested.connect(player.heal)
	pickups.pickup_collected.connect(func(pickup_id: String) -> void: records.discover_content("pickups", pickup_id))
	pickups.pickup_collected.connect(pickup_collected.emit)
	records.discover_content("skills", str(build_state.skill_slots[0]))
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
	if not safety.combat_ready(direction, state.elapsed, level):
		state_changed.emit()
		return
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
func select_upgrade(choice_key: String) -> bool:
	var result: Dictionary = upgrades.apply_structured_choice(choice_key, build_state)
	if not bool(result.get("success", false)):
		return false
	var choice: Dictionary = result["choice"]
	var content_id := str(choice["content_id"])
	if [UpgradeSystem.SKILL_UNLOCK, UpgradeSystem.SKILL_UPGRADE, UpgradeSystem.SKILL_BRANCH].has(str(choice["kind"])):
		skills.sync_after_upgrade(content_id)
		records.discover_content("skills", content_id)
		if str(choice["kind"]) == UpgradeSystem.SKILL_BRANCH:
			records.discover_content("skill_branches", str(choice["branch_id"]))
	elif str(choice["kind"]) == UpgradeSystem.RELIC_UPGRADE:
		records.discover_content("relics", content_id)
	player.apply_build_modifiers(build_state)
	player.apply_acquire_effects(result["effects"])
	state.pending_upgrades -= 1
	if state.pending_upgrades > 0:
		_request_upgrade()
	else:
		safety.prepare_upgrade_resume(state.elapsed, damage_resolver)
		state.paused = false
	state_changed.emit()
	return true

func reroll_upgrade() -> bool:
	if state.finished or state.pending_upgrades <= 0:
		return false
	var health_ratio: float = player.health / player.max_health
	var result: Dictionary = upgrades.reroll_structured_choices(build_state, skill_pool_weights, relic_pool_weights, health_ratio)
	if not bool(result.get("success", false)):
		return false
	upgrade_requested.emit(state.player_level, result["choices"], upgrades, build_state)
	state_changed.emit()
	return true


func add_experience(amount: int) -> void:
	if state.add_experience(amount) > 0 and not state.paused:
		_request_upgrade()
func _update_stage_events() -> void:
	var events := stage_director.advance(state.elapsed)
	var transitions: Array = events["transitions"]
	if not transitions.is_empty():
		var stage: StageConfig = transitions[-1]
		stage_banner_requested.emit(stage.display_name, stage.subtitle, 2.4)
		audio.play_sfx("stage_transition", -1.0)
	if events["elite_due"]:
		state.elite_spawned = true
		elite_enemy = enemies.spawn_elite(level.elite, state.elapsed)
		if is_instance_valid(elite_enemy):
			effects.add_effect(elite_enemy.position, elite_enemy.radius + 52.0, Color("f6c968"), 0.72, "elite_appear")
		audio.play_sfx("elite_appear", 0.0)
		stage_banner_requested.emit("%s · %s降临" % [stage_director.current_stage().display_name, level.elite.display_name], "击败可获得额外赐福与星引磁场", 2.8)


func _handle_enemy_contacts() -> void:
	damage_resolver.apply_contacts(enemies, state)
	if damage_resolver.player_defeated:
		_finish(false, RunState.END_DEFEATED)


func _apply_player_hit(hit: PlayerHit) -> bool:
	var applied := damage_resolver.apply(hit, state.elapsed, state.finished)
	if damage_resolver.player_defeated:
		_finish(false, RunState.END_DEFEATED)
	return applied


func _on_enemy_defeated(enemy: Node) -> void:
	state.kills += 1
	pickups.drop_for_enemy(enemy)
	if not enemy.is_elite:
		return
	effects.add_effect(enemy.position, enemy.radius + 62.0, Color("f6c968"), 0.76, "elite_defeat")
	audio.play_sfx("elite_defeat", 0.0)
	state.elite_defeated = true
	elite_enemy = null
	build_state.rerolls_remaining += 1
	pickups.activate_magnet(state.elapsed, level.elite.magnet_duration)
	state.pending_upgrades += level.elite.bonus_upgrade_count
	stage_banner_requested.emit("精英击破", "额外赐福 %d 次 · 重抽 +1 · 磁场 %d 秒" % [level.elite.bonus_upgrade_count, level.elite.magnet_duration], 2.6)
	if level.victory.mode == VictoryConfig.DEFEAT_ELITE:
		_finish(true, RunState.END_COMPLETED)
	elif state.pending_upgrades > 0:
		_request_upgrade()


func _request_upgrade() -> void:
	state.paused = true
	var health_ratio: float = player.health / player.max_health
	var choices: Array = upgrades.build_structured_choices(build_state, skill_pool_weights, relic_pool_weights, health_ratio)
	if choices.is_empty():
		state.pending_upgrades = maxi(0, state.pending_upgrades - 1)
		state.paused = state.pending_upgrades > 0
		if state.pending_upgrades > 0:
			call_deferred("_request_upgrade")
		return
	upgrade_requested.emit(state.player_level, choices, upgrades, build_state)


func _resolve_time_boundary() -> bool:
	if level.victory.is_victory(state.elapsed, level.duration, state.elite_defeated):
		_finish(true, RunState.END_COMPLETED)
		return true
	if level.victory.is_timeout_failure(state.elapsed, level.duration, state.elite_defeated):
		_finish(false, RunState.END_OBJECTIVE_TIMEOUT)
		return true
	return false


func _finish(won: bool, end_reason: String) -> void:
	if state.finished:
		return
	state.finished = true
	state.victory = won
	state.end_reason = end_reason
	if won and player.has_method("trigger_victory_animation"):
		player.trigger_victory_animation()
	state.paused = true
	enemy_abilities.clear_all()
	enemy_projectiles.clear_all()
	finished.emit(RunResultService.new().finalize(records, state, level, passives, build_state))
