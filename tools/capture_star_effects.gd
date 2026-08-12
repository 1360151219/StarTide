extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")

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
	elif frame_count == 11:
		game.session.skills.runtime.pulse_center = game.session.player.position
		game.session.skills.runtime.pulse_visual_time = game.session.skills.runtime.FROST_TRAVEL_TIME * 0.5
		game.session.skills.visuals.queue_redraw()
		game.refresh_presentation()
	elif frame_count == 12:
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
	session.build_state.skill_slots = ["star_lance", "sun_orbit", "frost_tide"]
	for skill_id in session.build_state.skill_slots:
		if SkillCatalog.has(str(skill_id)):
			session.skills.levels[skill_id] = int(SkillCatalog.skill(skill_id)["max_level"])
	var positions := [Vector2(-115, -155), Vector2(145, -115), Vector2(165, 135), Vector2(-145, 165), Vector2(-185, 20)]
	var kinds := ["slime", "bat", "brute", "slime", "bat"]
	while session.enemies.enemies.size() < 5:
		session.enemies.spawn_enemy(kinds[session.enemies.enemies.size()], null, session.state.elapsed)
	for index in range(5):
		var enemy = session.enemies.enemies[index]
		enemy.configure(kinds[index], {"health": 1.0, "speed": 1.0, "damage": 1.0})
		enemy.position = positions[index]
	session.skills.runtime.bolt_timer = 0.0
	session.skills.runtime.pulse_timer = 0.0
	session.skills.runtime.orbit_hit_timer = 0.0
	session.skills.advance(0.4, 0.1, session.state.elapsed)
	game.refresh_presentation()
