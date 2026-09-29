extends SceneTree

const Main = preload("res://main.tscn")
const Setup = preload("res://tools/support/capture_setup.gd")
const Streams = preload("res://tools/support/test_random_streams.gd")
const PROFILES := [Vector2i(540, 960), Vector2i(540, 1170), Vector2i(540, 1200), Vector2i(720, 960)]
const KEY_FRAMES := [0, 1, 2, 3, 4, 5, 7, 10, 12, 14, 16, 19, 22, 27, 30, 36]

var output := "res://preview/frost_slash"
var sequence := false
var all_sizes := false
var moving := false
var failed := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg == "--sequence": sequence = true
		if arg == "--all-sizes": all_sizes = true
		if arg == "--moving": moving = true
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for canvas in PROFILES if all_sizes else [PROFILES[0]]:
		await _capture_profile(canvas)
	if not failed:
		print("FROST_SLASH_CAPTURE_OK levels=5 profiles=%d fps=60 actual_casts=true safe_area=true output=%s" % [4 if all_sizes else 1, output])
	quit(1 if failed else 0)

func _capture_profile(canvas: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = canvas
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game := Main.instantiate()
	viewport.add_child(game)
	await process_frame
	Setup.isolate_records(game)
	game.random_streams = Streams.create(512)
	game.balance_sample_store = null
	game.start_run("star_warden", "level_01")
	game.set_process(false)
	game.hud.safe_area.layout_in_rect(Rect2(Vector2(0, 44), Vector2(canvas) - Vector2(0, 78)))
	game.hud.tutorial_time = 0.0
	game.hud.tutorial_step = 1
	game.hud.stage_hud.banner_time = 0.0
	game.hud.advance(0.0)
	var session: Node = game.session
	for enemy in session.enemies.snapshot():
		session.enemies.remove_enemy(enemy)
	for index in range(5):
		var enemy: Node = session.enemies.spawn_enemy("slime" if index % 2 == 0 else "green_grub", null, 0.0)
		enemy.position = session.player.position + Vector2.from_angle(index * TAU / 5.0) * 135.0
		enemy.health = 9999.0
		enemy.max_health = 9999.0
		enemy.z_index = session.level.map.depth_index(enemy.position.y)
	session.build_state.skill_slots = ["sun_orbit", "", ""]
	session.build_state.skill_levels.clear()
	session.build_state.skill_levels["sun_orbit"] = 1
	session.skills.sync_after_upgrade("sun_orbit")
	for level in range(1, 6):
		session.build_state.skill_levels["sun_orbit"] = level
		session.state.player_level = level
		session.effects.clear_all()
		session.skills.runtime.rng.seed = 512
		session.skills.runtime.slash_timer = 0.0
		session.skills.advance(0.0, 0.0, 10.0)
		if session.skills.runtime.slash_visuals.is_empty():
			failed = true
			push_error("FROST_SLASH_CAPTURE_FAILED: 技能没有实际施放")
		for frame in range(43):
			if frame > 0:
				if moving:
					session.player.move(Vector2.RIGHT * cos(frame * 0.15) * 0.9, 1.0 / 60.0)
				session.skills.advance(0.0, 1.0 / 60.0, 10.0 + frame / 60.0)
				session.effects.advance(1.0 / 60.0)
			game.refresh_presentation()
			await process_frame
			RenderingServer.force_draw(false)
			if sequence or frame in KEY_FRAMES:
				var name := "%s/%dx%d_lv%d_%03d.png" % [output, canvas.x, canvas.y, level, frame]
				if viewport.get_texture().get_image().save_png(name) != OK:
					failed = true
					push_error("FROST_SLASH_CAPTURE_FAILED: " + name)
	viewport.free()
	await process_frame
