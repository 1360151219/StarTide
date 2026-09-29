extends SceneTree

const Main = preload("res://main.tscn")
const Setup = preload("res://tools/support/capture_setup.gd")
const Streams = preload("res://tools/support/test_random_streams.gd")
const OUTPUT := "res://preview/combat_experience"
const PROFILES := [Vector2i(540, 960), Vector2i(540, 1170), Vector2i(540, 1200), Vector2i(720, 960)]

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for canvas in PROFILES:
		for hero in ["star_warden", "ember_ranger"]:
			await _capture_hero(canvas, hero)
	if not failed:
		print("CAPTURE_OK set=combat_experience profiles=4 heroes=2 safe_area=true actual_casts=true output=%s" % OUTPUT)
	quit(1 if failed else 0)

func _capture_hero(canvas: Vector2i, hero: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = canvas
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game := Main.instantiate()
	viewport.add_child(game)
	await process_frame
	Setup.isolate_records(game)
	game.random_streams = Streams.create(912)
	game.balance_sample_store = null
	game.start_run(hero, "level_01")
	game.set_process(false)
	game.hud.safe_area.layout_in_rect(Rect2(Vector2(0, 44), Vector2(canvas) - Vector2(0, 78)))
	game.hud.tutorial_time = 0.0
	game.hud.tutorial_step = 1
	game.hud.stage_hud.banner_time = 0.0
	game.hud.advance(0.0)
	var session: Node = game.session
	var origin: Vector2 = session.player.position
	var skills := ["star_lance", "sun_orbit", "frost_tide"] if hero == "star_warden" else ["ember_volley", "meteor_rain", "phoenix_heart"]
	session.build_state.skill_slots = skills
	for skill in skills:
		session.build_state.skill_levels[skill] = 5
	session.build_state.skill_branches = {"star_lance": "star_lance_fan", "frost_tide": "frost_tide_field"} if hero == "star_warden" else {"ember_volley": "ember_volley_flock", "meteor_rain": "meteor_rain_scatter", "phoenix_heart": "phoenix_heart_inferno"}
	session.skills.sync_after_upgrade(skills[0])
	for enemy in session.enemies.snapshot():
		session.enemies.remove_enemy(enemy)
	for index in range(7):
		var enemy: Node = session.enemies.spawn_enemy("slime" if index % 2 == 0 else "green_grub", null, 0.0)
		enemy.position = origin + Vector2.from_angle(-PI * 0.5 + index * TAU / 7.0) * (155.0 + index * 8.0)
		enemy.max_health = 9999.0
		enemy.health = 9999.0
		enemy.z_index = session.level.map.depth_index(enemy.position.y)
	session.state.elapsed = 60.0
	var prefix := "%s_%dx%d" % [hero, canvas.x, canvas.y]
	_set_timers(session, hero, 0.08)
	session.skills.visuals.refresh()
	await _save(viewport, game, prefix + "_ready")
	_set_timers(session, hero, 0.0)
	session.skills.advance(0.0, 0.0, 60.0)
	_advance(session, 0.08)
	await _save(viewport, game, prefix + "_release")
	_advance(session, 0.1)
	await _save(viewport, game, prefix + "_peak")
	_advance(session, 0.22)
	await _save(viewport, game, prefix + "_impact")
	if hero == "star_warden":
		session.build_state.skill_branches["star_lance"] = "star_lance_pierce"
		session.skills.runtime.bolt_timer = 0.0
		session.skills.advance(0.0, 0.0, 60.0)
		session.projectiles.advance(0.15)
		await _save(viewport, game, prefix + "_pierce")
	var elite: Node = session.enemies.spawn_elite(session.level.elite, 60.0)
	session.elite_enemy = elite
	elite.position = origin + Vector2(1400, -1000)
	await _save(viewport, game, prefix + "_elite")
	if not game.hud.stage_hud.elite_marker_visible:
		failed = true
		push_error("CAPTURE_FAILED: 离屏精英方向标没有显示")
	game.hud.set_upgrade_obscured(true)
	if game.hud.stage_hud.is_visible_in_tree():
		failed = true
		push_error("CAPTURE_FAILED: 升级覆盖层没有隐藏强敌方向标")
	viewport.free()
	await process_frame

func _set_timers(session: Node, hero: String, value: float) -> void:
	if hero == "star_warden":
		session.skills.runtime.bolt_timer = value
		session.skills.runtime.slash_timer = value
		session.skills.runtime.pulse_timer = value
	else:
		session.skills.runtime.volley_timer = value
		session.skills.runtime.meteor_timer = value
		session.skills.runtime.phoenix_timer = value

func _advance(session: Node, delta: float) -> void:
	session.effects.advance(delta)
	session.skills.advance(0.0, delta, 60.0 + delta)
	session.projectiles.advance(delta)

func _save(viewport: SubViewport, game: Node, name: String) -> void:
	game.refresh_presentation()
	await process_frame
	RenderingServer.force_draw(false)
	var error := viewport.get_texture().get_image().save_png(OUTPUT + "/" + name + ".png")
	if error != OK:
		failed = true
		push_error("CAPTURE_FAILED: 无法保存 %s" % name)
