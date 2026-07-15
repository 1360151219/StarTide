extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")

var frame_count := 0


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count > 60:
		push_error("CAPTURE_FAILED: 星潮技能截图流程超时")
		quit(1)
		return
	var game := current_scene
	if game == null:
		return
	if frame_count == 2:
		CaptureSetup.isolate_records(game)
	elif frame_count == 5:
		game.start_run("star_warden", "level_01")
	elif frame_count == 8:
		_prepare_showcase(game)
	elif frame_count == 20:
		game.session.pause()
		if CaptureSetup.capture(self, "ultimate.png"):
			print("CAPTURE_OK set=star_effects")
			quit()
		else:
			quit(1)


func _prepare_showcase(game: Node) -> void:
	var session: Node = game.session
	session.player.max_health = 999.0
	session.player.health = 999.0
	for skill_id in session.skills.active_skill_ids:
		session.skills.levels[skill_id] = 3
	var positions := [Vector2(-115, -155), Vector2(145, -115), Vector2(165, 135), Vector2(-145, 165), Vector2(-185, 20)]
	var kinds := ["slime", "bat", "brute", "slime", "bat"]
	if session.enemies.enemies.size() < 5:
		push_error("CAPTURE_FAILED: 星潮技能预览至少需要 5 个初始敌人")
		quit(1)
		return
	for index in range(5):
		var enemy = session.enemies.enemies[index]
		enemy.configure(kinds[index], {"health": 1.0, "speed": 1.0, "damage": 1.0})
		enemy.position = positions[index]
	session.skills.runtime.bolt_timer = 0.0
	session.skills.runtime.pulse_timer = 0.0
	session.skills.runtime.orbit_hit_timer = 0.0
	session.skills.advance(0.4, 0.1, session.state.elapsed)
	game.refresh_presentation()
