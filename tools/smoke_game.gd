extends SceneTree

var phase := 0
var frame_count := 0
var paused_elapsed := 0.0
var finishing := false


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	if finishing:
		return
	frame_count += 1
	var game := current_scene
	if game == null:
		return
	if phase == 0 and frame_count == 3:
		if not _require(game.audio_manager.STREAMS.size() == 14 and game.music_sliders.size() == 2 and game.sfx_sliders.size() == 2, "声音系统或音量控件没有完整初始化"):
			return
		var original_music_volume: float = game.audio_manager.music_volume
		var original_sfx_volume: float = game.audio_manager.sfx_volume
		game.audio_manager.set_music_volume(0.37, false)
		game.audio_manager.set_sfx_volume(0.42, false)
		game._sync_volume_controls()
		if not _require(is_equal_approx(game.audio_manager.music_volume, 0.37) and is_equal_approx(game.audio_manager.sfx_volume, 0.42) and is_equal_approx(game.music_sliders[0].value, 37.0) and is_equal_approx(game.sfx_sliders[1].value, 42.0), "音乐或音效音量没有正确同步"):
			return
		game.audio_manager.set_music_volume(original_music_volume, false)
		game.audio_manager.set_sfx_volume(original_sfx_volume, false)
		game._sync_volume_controls()
		game._open_compendium("skills")
		if not _require(game.compendium_overlay.visible and game.compendium_list.get_child_count() == 6, "技能图鉴条目不完整"):
			return
		if not _require(game.CompendiumCatalog.entries("heroes").size() == 2 and game.CompendiumCatalog.entries("enemies").size() == 3 and game.CompendiumCatalog.entries("pickups").size() == 3, "图鉴分类条目不完整"):
			return
		game._close_compendium()
	if phase == 0:
		_test_star_warden(game)
	else:
		_test_ember_ranger(game)


func _test_star_warden(game: Node) -> void:
	if frame_count == 5:
		game._select_hero("star_warden")
		game._start_run()
	if frame_count == 10:
		if not _require(game.player.hero_id == "star_warden", "星潮守望者没有正确创建"):
			return
		if not _require(game.skill_levels.keys().size() == 3 and game.skill_levels.has("star_lance") and not game.skill_levels.has("ember_volley"), "星潮守望者技能池错误"):
			return
		game.player.move(Vector2.LEFT, 0.016, game.WORLD_BOUNDS)
		game.player.move(Vector2.RIGHT, 0.016, game.WORLD_BOUNDS)
		if not _require(game.player.horizontal_facing == 1 and game.player.turn_progress == 0.0, "英雄左右转身状态未更新"):
			return
		paused_elapsed = game.elapsed
		game._pause_game()
	if frame_count == 18:
		if not _require(game.pause_overlay.visible and is_equal_approx(game.elapsed, paused_elapsed), "暂停期间游戏仍在推进"):
			return
		game._resume_game()
		game._add_experience(40)
		if not _require(game.upgrade_overlay.visible, "升级三选一没有出现"):
			return
		var allowed := ["star_lance", "sun_orbit", "frost_tide", "vitality", "swiftness", "recovery"]
		for button in game.upgrade_buttons:
			if not _require(allowed.has(button.get_meta("choice_id")), "星潮守望者出现了其他英雄的技能"):
				return
		game._on_upgrade_selected(game.upgrade_buttons[0])
		for skill_id in game.active_skill_ids:
			game.skill_levels[skill_id] = 3
		game.bolt_timer = 0.0
		game.pulse_timer = 0.0
		game._update_star_lance(0.1)
		game._update_sun_orbit(0.4)
		game._update_frost_tide(0.1)
		if not _require(game.projectiles.size() > 0 and game.projectiles[0].visual_kind == "star_lance" and game.pulse_visual_time > 0.0, "星潮守望者技能和特效没有生效"):
			return
	if frame_count == 26:
		phase = 1
		frame_count = 0
		change_scene_to_file("res://main.tscn")


func _test_ember_ranger(game: Node) -> void:
	if frame_count == 5:
		game._select_hero("ember_ranger")
		game._start_run()
	if frame_count == 10:
		if not _require(game.player.hero_id == "ember_ranger", "烬羽没有正确创建"):
			return
		if not _require(game.skill_levels.keys().size() == 3 and game.skill_levels.has("ember_volley") and not game.skill_levels.has("star_lance"), "烬羽技能池错误"):
			return
		game._add_experience(40)
		var allowed := ["ember_volley", "meteor_rain", "phoenix_heart", "vitality", "swiftness", "recovery"]
		for button in game.upgrade_buttons:
			if not _require(allowed.has(button.get_meta("choice_id")), "烬羽出现了其他英雄的技能"):
				return
		game._on_upgrade_selected(game.upgrade_buttons[0])
		for skill_id in game.active_skill_ids:
			game.skill_levels[skill_id] = 3
		game.player.max_health = 999.0
		game.player.health = 999.0
		game.bolt_timer = 0.0
		game.meteor_timer = 0.0
		game.phoenix_timer = 0.0
		game._update_ember_volley(0.1)
		game._update_meteor_rain(0.1)
		game._update_phoenix_heart(0.1)
		if not _require(game.projectiles.size() > 0 and game.projectiles[0].visual_kind == "ember_arrow" and game.burst_effects.size() > 0, "烬羽专属技能和特效没有生效"):
			return
		var enemy = game.enemies[0]
		enemy.position = Vector2.ZERO
		enemy.advance(Vector2(-100, 0), 0.016, game.elapsed)
		enemy.advance(Vector2(100, 0), 0.016, game.elapsed)
		if not _require(enemy.horizontal_facing == 1 and enemy.turn_progress < 0.2, "怪物左右转身状态未更新"):
			return
	if frame_count == 360:
		if not _require(game.kills > 0, "烬羽长时战斗没有产生击杀"):
			return
		print("SMOKE_OK heroes=2 pause=true turning=true audio=14 volume=true compendium=4 effects=6 ember_kills=%d" % game.kills)
		_finish_successfully(game)


func _finish_successfully(_game: Node) -> void:
	finishing = true
	unload_current_scene()
	await process_frame
	await process_frame
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SMOKE_FAILED: " + message)
	quit(1)
	return false
