extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")

var frame_count := 0


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count > 70:
		push_error("CAPTURE_FAILED: 生态截图流程超时")
		quit(1)
		return
	var game := current_scene
	if game == null:
		return
	match frame_count:
		2:
			CaptureSetup.isolate_records(game)
			_silence_audio(game)
			for level_id in ["level_01", "level_02", "level_03"]:
				game.run_records.unlocked_levels[level_id] = true
		5:
			game.start_run("star_warden", "level_01")
		10:
			_prepare_scene(game)
		14:
			_capture("biome_meadow.png")
		16:
			_clear_run(game)
		19:
			game.start_run("star_warden", "level_02")
		24:
			_prepare_scene(game)
		28:
			_capture("biome_oasis.png")
		30:
			_clear_run(game)
		33:
			game.start_run("star_warden", "level_03")
		38:
			_prepare_scene(game)
		42:
			if _capture("biome_volcano.png"):
				_clear_run(game)
				_silence_audio(game)
				print("CAPTURE_OK set=biomes")
				quit()


func _prepare_scene(game: Node) -> void:
	var session: Node = game.session
	session.player.max_health = 999.0
	session.player.health = 999.0
	var kinds := ["green_grub", "slime", "bat", "brute"]
	var positions := [Vector2(-135, -95), Vector2(135, -105), Vector2(-145, 155), Vector2(135, 155)]
	while session.enemies.enemies.size() < kinds.size():
		session.enemies.spawn_enemy(kinds[session.enemies.enemies.size()], null, session.state.elapsed)
	for index in range(kinds.size()):
		var enemy: Node = session.enemies.enemies[index]
		enemy.configure(kinds[index], {"health": 1.0, "speed": 1.0, "damage": 1.0})
		enemy.position = positions[index]
		enemy.side_blend = 1.0 if index % 2 == 0 else 0.0
		enemy.horizontal_facing = -1 if index % 2 == 0 else 1
		enemy.turn_progress = 1.0
	session.pause()
	game.refresh_presentation()


func _clear_run(game: Node) -> void:
	if is_instance_valid(game.session):
		game.session.free()
	game.session = null
	game.hud.visible = false
	game.combat_effects.effects.clear()


func _silence_audio(game: Node) -> void:
	game.audio_manager.audio_output_available = false
	game.audio_manager.music_player.stop()
	game.audio_manager.music_player.stream = null
	for player in game.audio_manager.sfx_players:
		player.stop()
		player.stream = null


func _capture(file_name: String) -> bool:
	var succeeded := CaptureSetup.capture(self, file_name)
	if not succeeded:
		quit(1)
	return succeeded
