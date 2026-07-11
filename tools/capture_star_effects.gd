extends SceneTree

var frame_count := 0


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	var game := current_scene
	if game == null:
		return
	if frame_count == 5:
		game._select_hero("star_warden")
		game._start_run()
	if frame_count == 8:
		_prepare_showcase(game)
	if frame_count == 20:
		game.gameplay_paused = true
		RenderingServer.force_draw(false)
		game.get_viewport().get_texture().get_image().save_png("res://preview/ultimate.png")
		quit()


func _prepare_showcase(game: Node) -> void:
	game.player.max_health = 999.0
	game.player.health = 999.0
	for skill_id in game.active_skill_ids:
		game.skill_levels[skill_id] = 3
	var positions := [Vector2(-115, -155), Vector2(145, -115), Vector2(165, 135), Vector2(-145, 165), Vector2(-185, 20)]
	var kinds := ["slime", "bat", "brute", "slime", "bat"]
	for index in range(game.enemies.size()):
		var enemy = game.enemies[index]
		enemy.configure(kinds[index], 1.0)
		enemy.position = positions[index]
	game.bolt_timer = 0.0
	game.pulse_timer = 0.0
	game.orbit_hit_timer = 0.0
	game._update_star_lance(0.1)
	game._update_sun_orbit(0.4)
	game._update_frost_tide(0.1)
	game._update_hud()
