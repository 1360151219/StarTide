extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")

var frame_count := 0
var video_mode := false


func _initialize() -> void:
	video_mode = OS.get_cmdline_user_args().has("--video")
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count > (200 if video_mode else 40):
		push_error("CAPTURE_FAILED: 星潮技能截图流程超时")
		quit(1)
		return
	var game := current_scene
	if game == null:
		return
	if video_mode:
		_capture_video_frame(game)
		return
	if frame_count == 2:
		CaptureSetup.isolate_records(game)
	elif frame_count == 5:
		game.start_run("star_warden", "level_01")
	elif frame_count == 8:
		_prepare_showcase(game)
		_show_tide(game, 4, "frost_tide_field", 0.36)
	elif frame_count == 9:
		if not CaptureSetup.capture(self, "frost_tide_lv4_field.png"):
			quit(1)
	elif frame_count == 11:
		_show_tide(game, 4, "frost_tide_shatter", 0.35)
	elif frame_count == 12:
		if not CaptureSetup.capture(self, "frost_tide_lv4_shatter.png"):
			quit(1)
	elif frame_count == 14:
		_show_tide(game, 5, "frost_tide_field", 0.375)
	elif frame_count == 15:
		if CaptureSetup.capture(self, "frost_tide_lv5_crown.png"):
			print("CAPTURE_OK set=frost_tide field_lv4=true shatter_lv4=true crown_lv5=true")
			quit()
		else:
			quit(1)


func _prepare_showcase(game: Node) -> void:
	var session: Node = game.session
	session.player.max_health = 999.0
	session.player.health = 999.0
	session.build_state.skill_slots = ["frost_tide", "", ""]
	var positions := [Vector2(-115, -155), Vector2(145, -115), Vector2(165, 135), Vector2(-145, 165), Vector2(-185, 20)]
	var kinds := ["slime", "bat", "brute", "slime", "bat"]
	while session.enemies.enemies.size() < 5:
		session.enemies.spawn_enemy(kinds[session.enemies.enemies.size()], null, session.state.elapsed)
	for index in range(5):
		var enemy = session.enemies.enemies[index]
		enemy.configure(kinds[index], {"health": 999.0, "speed": 1.0, "damage": 1.0})
		enemy.position = positions[index]
	session.skills.runtime.pulse_timer = 99.0
	session.pause()
	game.refresh_presentation()


func _show_tide(game: Node, level: int, branch_id: String, elapsed: float) -> void:
	var session: Node = game.session
	session.build_state.skill_levels["frost_tide"] = level
	session.build_state.skill_branches["frost_tide"] = branch_id
	var data: Dictionary = SkillCatalog.skill("frost_tide")["runtime"]
	var radius: float = data["radius"][level] * float(session.build_state.branch_overrides("frost_tide").get("radius_multiplier", 1.0))
	var duration := 0.62 if level == 5 else 0.54 if branch_id == "frost_tide_field" else 0.46
	session.skills.runtime.pulse_visual = {"origin": session.player.position, "radius": radius, "level": level, "branch_id": branch_id, "visual_id": frame_count, "time_left": duration - elapsed, "duration": duration}
	session.skills.visuals.refresh()
	game.refresh_presentation()


func _capture_video_frame(game: Node) -> void:
	if frame_count == 2:
		CaptureSetup.isolate_records(game)
	elif frame_count == 5:
		game.start_run("star_warden", "level_01")
	elif frame_count == 8:
		_prepare_showcase(game)
	elif frame_count == 20:
		_release_tide(game, 4, "frost_tide_field")
	elif frame_count == 70:
		_release_tide(game, 4, "frost_tide_shatter")
	elif frame_count == 120:
		_release_tide(game, 5, "frost_tide_field")
	if frame_count >= 9 and frame_count < 185:
		game.session.skills.advance(0.0, 1.0 / 60.0, float(frame_count) / 60.0)
		game.session.effects.advance(1.0 / 60.0)
		game.refresh_presentation()
	if frame_count == 185:
		print("CAPTURE_OK video=frost_tide fps=60 actual_runtime=true")
		quit()


func _release_tide(game: Node, level: int, branch_id: String) -> void:
	var session: Node = game.session
	session.build_state.skill_levels["frost_tide"] = level
	session.build_state.skill_branches["frost_tide"] = branch_id
	session.skills.runtime.pulse_timer = 0.0
	session.skills.advance(0.0, 0.0, float(frame_count) / 60.0)
