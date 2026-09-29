extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")

var frame_count := 0


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count > 30:
		push_error("CAPTURE_FAILED: 烬羽技能截图流程超时")
		quit(1)
		return
	var game := current_scene
	if game == null:
		return
	if frame_count == 2:
		CaptureSetup.isolate_records(game)
	elif frame_count == 5:
		game.start_run("ember_ranger", "level_01")
	elif frame_count == 8:
		_prepare_showcase(game)
	elif frame_count == 9:
		if not CaptureSetup.capture(self, "ember_effects_lv5_reveal.png"):
			quit(1)
	elif frame_count == 11:
		_advance_to_phoenix_peak(game)
	elif frame_count == 12:
		if not CaptureSetup.capture(self, "ember_effects_lv5_peak.png"):
			quit(1)
	elif frame_count == 14:
		_advance_to_meteor_impact(game)
	elif frame_count == 15:
		if CaptureSetup.capture(self, "ember_effects_lv5_impact.png"):
			print("CAPTURE_OK set=ember_effects reveal_100ms=true phoenix_180ms=true meteor_impact=true")
			quit()
		else:
			quit(1)


func _prepare_showcase(game: Node) -> void:
	var session: Node = game.session
	session.player.max_health = 999.0
	session.player.health = 940.0
	session.build_state.skill_slots = ["ember_volley", "meteor_rain", "phoenix_heart"]
	session.build_state.skill_levels.clear()
	for skill_id in session.build_state.skill_slots:
		session.build_state.skill_levels[skill_id] = 5
	session.build_state.skill_branches = {
		"ember_volley": "ember_volley_flock",
		"meteor_rain": "meteor_rain_focus",
		"phoenix_heart": "phoenix_heart_inferno",
	}
	session.skills.sync_after_upgrade("phoenix_heart")
	var positions := [Vector2(-150, -150), Vector2(150, -125), Vector2(175, 135), Vector2(-155, 155), Vector2(-190, 10)]
	var kinds := ["slime", "bat", "brute", "slime", "bat"]
	while session.enemies.enemies.size() < positions.size():
		session.enemies.spawn_enemy(kinds[session.enemies.enemies.size()], null, session.state.elapsed)
	for index in range(positions.size()):
		var enemy = session.enemies.enemies[index]
		enemy.configure(kinds[index], {"health": 999.0, "speed": 1.0, "damage": 1.0})
		enemy.position = positions[index]
	session.skills.runtime.volley_timer = 0.0
	session.skills.runtime.meteor_timer = 0.0
	session.skills.runtime.phoenix_timer = 0.0
	session.skills.advance(0.0, 0.0, session.state.elapsed)
	session.effects.advance(0.1)
	session.skills.advance(0.0, 0.1, session.state.elapsed + 0.1)
	session.projectiles.advance(0.06)
	session.pause()
	game.hud.tutorial_panel.visible = false
	game.hud.stage_hud.banner_time = 0.0
	game.hud.stage_hud.advance(0.0)
	game.refresh_presentation()


func _advance_to_phoenix_peak(game: Node) -> void:
	var session: Node = game.session
	session.effects.advance(0.08)
	session.skills.advance(0.0, 0.08, session.state.elapsed + 0.18)
	session.projectiles.advance(0.03)
	game.refresh_presentation()


func _advance_to_meteor_impact(game: Node) -> void:
	var session: Node = game.session
	session.effects.advance(0.16)
	session.skills.advance(0.0, 0.16, session.state.elapsed + 0.34)
	session.effects.advance(0.06)
	session.skills.advance(0.0, 0.06, session.state.elapsed + 0.4)
	game.refresh_presentation()
