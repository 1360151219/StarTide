extends Node2D

const AudioManager = preload("res://scripts/audio_manager.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const RunSession = preload("res://scripts/run/run_session.gd")
const BalanceSampleStore = preload("res://scripts/run/balance_sample_store.gd")
const CombatFeedback = preload("res://scripts/presentation/combat_feedback.gd")
const FrontendShell = preload("res://scripts/ui/frontend_shell.gd")
const GameHud = preload("res://scripts/ui/game_hud.gd")
const PauseOverlay = preload("res://scripts/ui/pause_overlay.gd")
const UpgradeOverlay = preload("res://scripts/ui/upgrade_overlay.gd")
const ResultOverlay = preload("res://scripts/ui/result_overlay.gd")

var audio_manager: Node
var combat_effects: Node2D
var run_records: RefCounted
var session: Node2D
var feedback := CombatFeedback.new()
var start_screen: CanvasLayer
var hud: CanvasLayer
var pause_overlay: CanvasLayer
var upgrade_overlay: CanvasLayer
var result_overlay: CanvasLayer
var random_streams: Dictionary
var balance_sample_store := BalanceSampleStore.new()


func _ready() -> void:
	random_streams = _create_random_streams()
	run_records = RunRecords.new("" if DisplayServer.get_name() == "headless" else RunRecords.DEFAULT_PATH)
	audio_manager = AudioManager.new()
	add_child(audio_manager)
	combat_effects = CombatEffects.new()
	combat_effects.z_index = 3950
	add_child(combat_effects)
	_build_ui()
	if not RunRecords.pending_replay_hero_id.is_empty():
		var hero_id := RunRecords.pending_replay_hero_id
		var level_id := RunRecords.pending_replay_level_id
		RunRecords.pending_replay_hero_id = ""
		RunRecords.pending_replay_level_id = ""
		call_deferred("start_run", hero_id, level_id)


func _process(delta: float) -> void:
	if not is_instance_valid(session) or session.state.finished or session.state.paused:
		return
	hud.advance(delta)
	feedback.advance(delta, session.state.elapsed)
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector2 = (keyboard + hud.movement_vector()).limit_length(1.0)
	hud.observe_movement(direction)
	session.advance(delta, direction)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or not is_instance_valid(session) or session.state.finished or upgrade_overlay.visible:
		return
	if pause_overlay.visible:
		_resume_game()
	else:
		_pause_game()
	get_viewport().set_input_as_handled()


func start_run(hero_id: String, level_id: String) -> void:
	var level := LevelCatalog.by_id(level_id)
	if level == null or not run_records.is_level_unlocked(level_id):
		return
	session = RunSession.new()
	add_child(session)
	_connect_session()
	session.configure(hero_id, level, run_records, audio_manager, combat_effects, random_streams, balance_sample_store)
	hud.configure(session.build_state.skill_slots, level.opening_tutorial_grace)
	hud.visible = true
	start_screen.visible = false
	feedback.configure(session.camera, hud.damage_flash)
	audio_manager.set_music_ducked(false)
	audio_manager.play_music(level_id)
	audio_manager.play_sfx("ui_confirm", 2.0)
	refresh_presentation()


func _connect_session() -> void:
	session.state_changed.connect(refresh_presentation)
	session.stage_banner_requested.connect(hud.show_banner)
	session.upgrade_requested.connect(_show_upgrade)
	session.player_hit_feedback_requested.connect(feedback.trigger_player_hit)
	session.finished.connect(_show_result)


func refresh_presentation() -> void:
	if not is_instance_valid(session):
		return
	var strong_enemy: Node = session.boss_enemy if is_instance_valid(session.boss_enemy) else session.elite_enemy
	hud.refresh(session.state, session.level, session.player, session.skills, session.pickups, session.passives, session.stage_director.current_stage(), strong_enemy)


func _show_upgrade(player_level: int, choices: Array, upgrade_system: RefCounted, build_state: RefCounted) -> void:
	hud.cancel_input()
	upgrade_overlay.show_choices(player_level, choices, upgrade_system, build_state)
	audio_manager.set_music_ducked(true)
	audio_manager.play_sfx("upgrade", -1.0)


func _on_upgrade_selected(choice_id: String) -> void:
	upgrade_overlay.visible = false
	if not session.select_upgrade(choice_id):
		upgrade_overlay.visible = true
		upgrade_overlay.restore_selection()
		return
	audio_manager.play_sfx("ui_confirm", 0.0)
	if not upgrade_overlay.visible:
		audio_manager.set_music_ducked(false)


func _on_upgrade_reroll() -> void:
	if session.reroll_upgrade():
		audio_manager.play_sfx("ui_select", -1.0)


func _show_result(presentation: Dictionary) -> void:
	hud.cancel_input()
	hud.visible = false
	pause_overlay.visible = false
	upgrade_overlay.visible = false
	audio_manager.set_music_ducked(true)
	audio_manager.play_sfx("result_victory" if bool(presentation.get("won", false)) else "result_failure", 0.0)
	result_overlay.show_result(presentation)


func _pause_game() -> void:
	if not is_instance_valid(session) or session.state.finished or upgrade_overlay.visible:
		return
	session.pause()
	hud.cancel_input()
	pause_overlay.show_build(session.build_state)
	pause_overlay.visible = true
	audio_manager.set_music_ducked(true)
	audio_manager.play_sfx("ui_select", -1.0)


func _resume_game() -> void:
	audio_manager.play_sfx("ui_confirm", -1.0)
	audio_manager.set_music_ducked(false)
	pause_overlay.visible = false
	session.resume()


func _replay_same_run() -> void:
	RunRecords.pending_replay_hero_id = session.state.hero_id
	RunRecords.pending_replay_level_id = session.state.level_id
	_reload_scene()


func _build_ui() -> void:
	start_screen = FrontendShell.new()
	add_child(start_screen)
	start_screen.configure(run_records, audio_manager)
	start_screen.start_requested.connect(start_run)
	hud = GameHud.new()
	add_child(hud)
	hud.pause_requested.connect(_pause_game)
	pause_overlay = PauseOverlay.new()
	add_child(pause_overlay)
	pause_overlay.configure(audio_manager)
	pause_overlay.resume_requested.connect(_resume_game)
	pause_overlay.home_requested.connect(_reload_scene)
	upgrade_overlay = UpgradeOverlay.new()
	add_child(upgrade_overlay)
	upgrade_overlay.choice_selected.connect(_on_upgrade_selected)
	upgrade_overlay.reroll_requested.connect(_on_upgrade_reroll)
	result_overlay = ResultOverlay.new()
	add_child(result_overlay)
	result_overlay.replay_requested.connect(_replay_same_run)
	result_overlay.home_requested.connect(_reload_scene)


func _create_random_streams() -> Dictionary:
	var source := RandomNumberGenerator.new()
	source.randomize()
	var streams := {}
	for stream_id in ["spawn", "loot", "skill", "upgrade", "enemy_ability"]:
		var stream := RandomNumberGenerator.new()
		stream.seed = source.randi()
		streams[stream_id] = stream
	return streams


func _reload_scene() -> void:
	get_tree().reload_current_scene()
