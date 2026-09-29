extends SceneTree

const Main = preload("res://main.tscn")
const Setup = preload("res://tools/support/capture_setup.gd")
const Streams = preload("res://tools/support/test_random_streams.gd")
const Abilities = preload("res://scripts/enemy_ability_catalog.gd")
const PROFILES := [Vector2i(540, 960), Vector2i(540, 1170), Vector2i(540, 1200), Vector2i(720, 960)]
const HERO_CASES := [
	["star_lance", "star_lance_pierce", "bolt_timer"], ["star_lance", "star_lance_fan", "bolt_timer"],
	["frost_tide", "frost_tide_field", "pulse_timer"], ["frost_tide", "frost_tide_shatter", "pulse_timer"],
	["ember_volley", "ember_volley_blast", "volley_timer"], ["ember_volley", "ember_volley_flock", "volley_timer"],
	["meteor_rain", "meteor_rain_focus", "meteor_timer"], ["meteor_rain", "meteor_rain_scatter", "meteor_timer"],
	["phoenix_heart", "phoenix_heart_inferno", "phoenix_timer"], ["phoenix_heart", "phoenix_heart_rebirth", "phoenix_timer"],
]

var output := "res://preview/skill_motion"
var sequence := false
var all_sizes := false
var moving := false
var enemy_only := false
var hero_only := false
var overlap := false
var level := 5
var subject := ""
var cycles := 1
var stacked := false
var map_id := "level_01"
var target_distance := 160.0
var failed := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--subject="): subject = arg.trim_prefix("--subject=")
		if arg.begins_with("--level="): level = clampi(int(arg.trim_prefix("--level=")), 1, 5)
		if arg.begins_with("--cycles="): cycles = clampi(int(arg.trim_prefix("--cycles=")), 1, 5)
		if arg.begins_with("--map="): map_id = arg.trim_prefix("--map=")
		if arg.begins_with("--target-distance="): target_distance = clampf(float(arg.trim_prefix("--target-distance=")), 20.0, 240.0)
		if arg == "--stacked": stacked = true
		if arg == "--sequence": sequence = true
		if arg == "--all-sizes": all_sizes = true
		if arg == "--moving": moving = true
		if arg == "--enemy-only": enemy_only = true
		if arg == "--hero-only": hero_only = true
		if arg == "--overlap": overlap = true
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for canvas in PROFILES if all_sizes else [PROFILES[0]]:
		for entry in HERO_CASES:
			if not enemy_only and (subject.is_empty() or subject in str(entry[1])):
				await _capture(canvas, entry)
		for id in Abilities.ids():
			if not hero_only and (subject.is_empty() or subject in id):
				await _capture(canvas, [id])
	if not failed:
		print("SKILL_MOTION_CAPTURE_OK profiles=%d level=%d actual_runtime=true safe_area=true output=%s" % [4 if all_sizes else 1, level, output])
	quit(1 if failed else 0)

func _capture(canvas: Vector2i, entry: Array) -> void:
	var id := str(entry[0])
	var hostile := entry.size() == 1
	var hero := "star_warden" if hostile or id in ["star_lance", "frost_tide"] else "ember_ranger"
	var viewport := SubViewport.new()
	viewport.size = canvas
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game := Main.instantiate()
	viewport.add_child(game)
	await process_frame
	Setup.isolate_records(game)
	game.run_records.unlocked_levels["level_05"] = true
	game.audio_manager.audio_output_available = false
	game.random_streams = Streams.create(921)
	game.balance_sample_store = null
	game.run_records.unlocked_levels[map_id] = true
	game.start_run(hero, "level_05" if hostile else map_id)
	game.set_process(false)
	game.hud.safe_area.layout_in_rect(Rect2(Vector2(0, 44), Vector2(canvas) - Vector2(0, 78)))
	game.hud.tutorial_time = 0.0
	game.hud.tutorial_step = 1
	game.hud.stage_hud.banner_time = 0.0
	game.hud.advance(0.0)
	var session: Node = game.session
	if session == null:
		failed = true
		push_error("SKILL_MOTION_CAPTURE_FAILED: 无法进入测试关卡")
		viewport.free()
		return
	session.camera.position_smoothing_enabled = false
	session.player.max_health = 9999.0
	session.player.health = 9900.0
	session.state.elapsed = 20.0
	for enemy in session.enemies.snapshot(): session.enemies.remove_enemy(enemy)
	session.effects.clear_all()
	session.build_state.skill_levels.clear()
	if hostile:
		_prepare_enemy(session, id)
	else:
		_prepare_hero(session, entry)
	var config := Abilities.ability(id) if hostile else {}
	var hit_frame := ceili(float(config.get("warning", 0.18)) * 60.0)
	var frame_count := hit_frame + 72 if hostile else 55
	if id == "meteor_rain": frame_count = 90 + (cycles - 1) * 150
	var key_frames := [0, 3, 6, 10, 11, 14, 20, 22, 26, 32, 42, hit_frame - 12, hit_frame - 1, hit_frame, hit_frame + 2, hit_frame + 5, hit_frame + 12, hit_frame + 25, frame_count - 1]
	for frame in range(frame_count):
		if frame > 0:
			_step(session, id, hostile, frame)
		game.refresh_presentation()
		await process_frame
		if (sequence and frame % 3 == 0) or (not sequence and frame in key_frames):
			RenderingServer.force_draw(false)
			var name := "%s/%dx%d_%s_lv%d_%03d.png" % [output, canvas.x, canvas.y, id if hostile else entry[1], level, frame]
			if viewport.get_texture().get_image().save_png(name) != OK:
				failed = true
				push_error("SKILL_MOTION_CAPTURE_FAILED: " + name)
	viewport.free()
	await process_frame
	print("CAPTURED %s %s" % [entry, canvas])

func _prepare_hero(session: Node, entry: Array) -> void:
	var id := str(entry[0])
	session.build_state.skill_slots = [id, "", ""]
	session.build_state.skill_levels[id] = level
	if stacked and id == "meteor_rain":
		session.build_state.skill_slots = ["ember_volley", "meteor_rain", "phoenix_heart"]
		for skill in session.build_state.skill_slots: session.build_state.skill_levels[skill] = level
		session.build_state.skill_branches["ember_volley"] = "ember_volley_flock"
		session.build_state.skill_branches["phoenix_heart"] = "phoenix_heart_inferno"
	if level > 1: session.build_state.skill_branches[id] = str(entry[1])
	session.skills.sync_after_upgrade(id)
	for index in range(6):
		var enemy: Node = session.enemies.spawn_enemy("green_grub" if index % 2 else "slime", null, 0.0)
		enemy.position = session.player.position + Vector2.from_angle(-0.9 + index * TAU / 6.0) * target_distance
		enemy.health = 9999.0
		enemy.max_health = 9999.0
		enemy.z_index = session.level.map.depth_index(enemy.position.y)
	session.skills.runtime.set(entry[2], 0.0)
	if stacked and id == "meteor_rain":
		session.skills.runtime.volley_timer = 0.0
		session.skills.runtime.phoenix_timer = 0.16
	session.skills.advance(0.0, 0.0, 20.0)
	if overlap:
		var enemy: Node = session.enemies.spawn_enemy("cloud_hart", null, 20.0)
		enemy.ability_id = "cloud_hart_sector"
		enemy.position = session.player.position + Vector2(-90, -80)
		enemy.health = 9999.0
		enemy.max_health = 9999.0
		enemy.z_index = session.level.map.depth_index(enemy.position.y)
		var state: Dictionary = session.enemy_abilities._state_for(enemy)
		state["visible_since"] = 0.0
		session.enemy_abilities._begin_warning(state, enemy, 20.0)
		session.enemy_abilities.telegraphs.set_states(session.enemy_abilities.states)

func _prepare_enemy(session: Node, id: String) -> void:
	var config := Abilities.ability(id)
	var is_boss := id.begins_with("zouwu")
	var enemy: Node = session.enemies.spawn_boss(session.level.boss) if is_boss else session.enemies.spawn_enemy(config["enemy_id"], null, 20.0)
	enemy.ability_id = id
	enemy.position = session.player.position + Vector2(-100, -100)
	if id == "zouwu_tail": enemy.position = session.player.position + Vector2(0, -150)
	enemy.z_index = session.level.map.depth_index(enemy.position.y)
	if is_boss:
		session.boss_abilities.activate(enemy, 20.0)
		session.boss_abilities.state["ability_id"] = id
		session.boss_abilities.state["sequence_remaining"] = 1
		session.boss_abilities.state["combat_phase"] = 1
		session.boss_abilities._begin_warning(config)
		session.boss_abilities._refresh_telegraph()
	else:
		var state: Dictionary = session.enemy_abilities._state_for(enemy)
		state["visible_since"] = 0.0
		session.enemy_abilities._begin_warning(state, enemy, 20.0)
		session.enemy_abilities.telegraphs.set_states(session.enemy_abilities.states)

func _step(session: Node, id: String, hostile: bool, frame: int) -> void:
	var delta := 1.0 / 60.0
	var elapsed := 20.0 + frame * delta
	session.effects.advance(delta)
	if moving: session.player.move(Vector2.RIGHT * cos(frame * 0.06) * 0.85, delta)
	if hostile:
		if id.begins_with("zouwu"):
			if session.boss_abilities.state["phase"] != "idle": session.boss_abilities.advance(delta, elapsed)
		else:
			session.enemy_abilities.advance(delta, elapsed)
		session.enemy_projectiles.advance(delta)
	else:
		session.skills.advance(delta if cycles > 1 or stacked else 0.0, delta, elapsed)
		session.projectiles.advance(delta)
		if overlap: session.enemy_abilities.advance(delta, elapsed)
