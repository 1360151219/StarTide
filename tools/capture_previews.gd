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
	if frame_count == 10:
		_capture("start.png")
	if frame_count == 14:
		game._open_compendium("heroes")
	if frame_count == 20:
		_capture("compendium_heroes.png")
	if frame_count == 24:
		game._show_compendium_category("enemies")
	if frame_count == 30:
		_capture("compendium_enemies.png")
	if frame_count == 34:
		game._show_compendium_category("pickups")
	if frame_count == 40:
		_capture("compendium_pickups.png")
	if frame_count == 44:
		game._show_compendium_category("skills")
	if frame_count == 50:
		_capture("compendium_skills.png")
	if frame_count == 56:
		game._close_compendium()
		game._select_hero("ember_ranger")
		game._start_run()
	if frame_count == 64:
		_prepare_ember_showcase(game)
	if frame_count == 70:
		_capture("gameplay_ember.png")
	if frame_count == 76:
		game.gameplay_paused = false
		game._pause_game()
	if frame_count == 82:
		_capture("pause.png")
	if frame_count == 88:
		game._resume_game()
		game._add_experience(40)
	if frame_count == 94:
		_capture("upgrade_ember.png")
	if frame_count == 100:
		if game.upgrade_overlay.visible:
			game._on_upgrade_selected(game.upgrade_buttons[0])
		game.skill_levels["ember_volley"] = 3
		game.skill_levels["meteor_rain"] = 3
		game.skill_levels["phoenix_heart"] = 3
		game.gameplay_paused = false
		game.bolt_timer = 0.0
		game.meteor_timer = 0.0
		game.phoenix_timer = 0.0
		game._update_ember_volley(0.1)
		game._update_meteor_rain(0.1)
		game._update_phoenix_heart(0.1)
		game._update_hud()
		game.queue_redraw()
	if frame_count == 108:
		_capture("ultimate_ember.png")
		quit()


func _prepare_ember_showcase(game: Node) -> void:
	game.player.max_health = 999.0
	game.player.health = 999.0
	game.player.facing = Vector2.RIGHT
	game.player.movement_amount = 1.0
	game.player.side_blend = 1.0
	game.player.horizontal_facing = 1
	game.skill_levels["meteor_rain"] = 2
	game.skill_levels["phoenix_heart"] = 1
	var kinds := ["slime", "bat", "brute", "slime", "bat"]
	var positions := [Vector2(-145, -125), Vector2(138, -110), Vector2(135, 175), Vector2(-145, 185), Vector2(-170, 40)]
	var directions := [-1, 1, -1, 1, 1]
	for index in range(5):
		var enemy = game.enemies[index]
		enemy.configure(kinds[index], 1.0)
		enemy.position = positions[index]
		enemy.side_blend = 1.0
		enemy.horizontal_facing = directions[index]
		enemy.turn_progress = 1.0
		enemy.z_index = clampi(roundi(enemy.position.y + 1700.0), 1, 3800)
		enemy.queue_redraw()
	game._spawn_pickup("xp", Vector2(-55, 110), 8)
	game._spawn_pickup("heart", Vector2(25, 130), 22)
	game._spawn_pickup("magnet", Vector2(78, 90), 1)
	game.gameplay_paused = true
	game._update_hud()
	game.queue_redraw()


func _capture(file_name: String) -> void:
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://preview/" + file_name)
