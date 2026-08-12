extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")

var frame_count := 0


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count > 100:
		push_error("CAPTURE_FAILED: 阶段截图流程超时")
		quit(1)
		return
	var game := current_scene
	if game == null:
		return
	if frame_count == 2:
		CaptureSetup.isolate_records(game)
		game.run_records.unlocked_levels["level_05"] = true
		game.audio_manager.audio_output_available = false
	elif frame_count == 5:
		game.start_run("star_warden", "level_01")
		game.session.player.max_health = 999.0
		game.session.player.health = 999.0
	elif frame_count == 10:
		game.session.state.elapsed = game.session.level.stages[2].start_time - 0.01
		game.session.advance(0.02, Vector2.ZERO)
		game.session.pause()
	elif frame_count == 14:
		_capture("stage_banner.png")
	elif frame_count == 18:
		game.session.resume()
		game.session.state.elapsed = game.session.level.elite.spawn_time - 0.01
		game.session.advance(0.02, Vector2.ZERO)
		if not is_instance_valid(game.session.elite_enemy):
			push_error("CAPTURE_FAILED: 精英没有按时生成")
			quit(1)
			return
		game.session.elite_enemy.position = Vector2(135, 120)
		game.session.pause()
	elif frame_count == 24:
		_capture("elite_encounter.png")
	elif frame_count == 28:
		game.session.resume()
		game.session.state.elapsed = game.session.level.duration - 0.01
		game.session.advance(0.02, Vector2.ZERO)
	elif frame_count == 34:
		_capture("victory.png")
	elif frame_count == 36:
		_clear_run(game)
	elif frame_count == 39:
		game.start_run("star_warden", "level_05")
		game.session.player.max_health = 999.0
		game.session.player.health = 999.0
	elif frame_count == 44:
		game.session.state.elapsed = game.session.level.boss.spawn_time(game.session.level.duration) - 0.01
		game.session.advance(0.02, Vector2.ZERO)
		if not is_instance_valid(game.session.boss_enemy):
			push_error("CAPTURE_FAILED: 驺吾没有按时生成")
			quit(1)
			return
		game.session.boss_enemy.position = Vector2(-130, -105)
		game.session.boss_enemy.health = game.session.boss_enemy.max_health * 0.5
		game.session.state.elapsed += 0.79
		game.session.advance(0.02, Vector2.ZERO)
		game.session.pause()
		game.hud.tutorial_time = 0.0
		game.hud.stage_hud.banner_time = 0.0
		game.hud.advance(0.0)
		game.refresh_presentation()
	elif frame_count == 50:
		if _capture("boss_encounter.png"):
			print("CAPTURE_OK set=stages")
			quit()


func _clear_run(game: Node) -> void:
	if is_instance_valid(game.session):
		game.session.free()
	game.session = null
	game.hud.visible = false
	game.result_overlay.visible = false
	game.combat_effects.effects.clear()


func _capture(file_name: String) -> bool:
	var succeeded := CaptureSetup.capture(self, file_name)
	if not succeeded:
		quit(1)
	return succeeded
