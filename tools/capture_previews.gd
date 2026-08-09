extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")

var frame_count := 0


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count > 320:
		push_error("CAPTURE_FAILED: 主场景加载或截图流程超时")
		quit(1)
		return
	var game := current_scene
	if game == null:
		return
	if frame_count == 2:
		CaptureSetup.isolate_records(game)
	elif frame_count == 12:
		_capture("start.png")
	elif frame_count == 16:
		game.start_screen.audio_settings.open_popup()
	elif frame_count == 26:
		_capture("audio_settings.png")
	elif frame_count == 30:
		game.start_screen.audio_settings.close_popup()
		game.start_screen.open_compendium("heroes")
	elif frame_count == 42:
		_capture("compendium_heroes.png")
	elif frame_count == 46:
		game.start_screen.compendium.show_category("enemies")
	elif frame_count == 58:
		_capture("compendium_enemies.png")
	elif frame_count == 62:
		game.start_screen.compendium.show_category("pickups")
	elif frame_count == 74:
		_capture("compendium_pickups.png")
	elif frame_count == 78:
		game.start_screen.compendium.show_category("skills")
	elif frame_count == 90:
		_capture("compendium_skills.png")
	elif frame_count == 94:
		game.start_screen.compendium.show_category("relics")
	elif frame_count == 106:
		_capture("compendium_relics.png")
	elif frame_count == 110:
		game.start_screen.compendium.close()
		game.start_screen.show_page("character")
	elif frame_count == 124:
		_settle_character_page(game)
		_capture("hero_selection.png")
	elif frame_count == 128:
		game.start_screen.character_page.select_hero("ember_ranger", false)
	elif frame_count == 140:
		_settle_character_page(game)
		_capture("hero_selection_ember.png")
	elif frame_count == 144:
		game.start_screen.character_page.show_section("equipment")
	elif frame_count == 156:
		_settle_character_page(game)
		_capture("hero_equipment.png")
	elif frame_count == 160:
		game.start_screen.character_page.show_section("skills")
	elif frame_count == 172:
		_settle_character_page(game)
		_capture("hero_training.png")
	elif frame_count == 176:
		game.start_screen.show_page("start")
		game.start_run("ember_ranger", "level_01")
	elif frame_count == 192:
		_prepare_ember_showcase(game)
	elif frame_count == 204:
		_capture("gameplay_ember.png")
	elif frame_count == 216:
		game.session.resume()
		game.hud.pause_requested.emit()
	elif frame_count == 228:
		_capture("pause.png")
	elif frame_count == 232:
		game.pause_overlay.resume_requested.emit()
		game.session.add_experience(40)
	elif frame_count == 244:
		_capture("upgrade_ember.png")
	elif frame_count == 252:
		_prepare_ember_ultimate(game)
	elif frame_count == 264:
		_capture("ultimate_ember.png")
	elif frame_count == 268:
		game.hud.visible = false
		game.result_overlay.show_result({
			"heading": "远征完成", "outcome_hint": "风铃草原 · 星门已守住", "won": true,
			"new_record": true, "duration_text": "01:30", "kills": 42, "player_level": 4,
			"hero_id": "ember_ranger", "first_clear": true, "first_clear_hint": "暮翼航标",
			"progression_reward": {"hero_xp_gained": 100, "level": 2},
			"equipment_reward": {"item_rows": [{"definition_id": "windstring_bow", "rarity": "rare", "level": 1}]},
			"random_equipment_reward": {"items": [
				{"definition_id": "windbell_charm", "rarity": "common", "level": 1},
				{"definition_id": "crystal_vest", "rarity": "rare", "level": 1},
				{"definition_id": "timeglass_charm", "rarity": "top", "level": 1},
			]},
			"discovery_count": 2,
			"build_snapshot": {
				"skill_slots": ["ember_volley", "meteor_rain", ""],
				"skill_levels": {"ember_volley": 3, "meteor_rain": 2},
				"skill_branches": {"ember_volley": "ember_volley_flock", "meteor_rain": "meteor_rain_focus"},
				"relic_levels": {"energy_prism": 2, "flow_feather": 1},
			},
		})
	elif frame_count == 282:
		game.result_overlay.finish_reveal()
	elif frame_count == 286:
		if _capture("result_victory.png"):
			print("CAPTURE_OK set=previews")
			quit()


func _prepare_ember_showcase(game: Node) -> void:
	var session: Node = game.session
	var kinds := ["slime", "bat", "brute", "slime", "bat"]
	while session.enemies.enemies.size() < 5:
		session.enemies.spawn_enemy(kinds[session.enemies.enemies.size()], null, session.state.elapsed)
	session.player.max_health = 999.0
	session.player.health = 999.0
	session.player.facing = Vector2.RIGHT
	session.player.movement_amount = 1.0
	session.skills.levels["meteor_rain"] = 2
	session.skills.levels["phoenix_heart"] = 1
	var positions := [Vector2(-145, -125), Vector2(138, -110), Vector2(135, 175), Vector2(-145, 185), Vector2(-170, 40)]
	for index in range(5):
		var enemy = session.enemies.enemies[index]
		enemy.configure(kinds[index], {"health": 1.0, "speed": 1.0, "damage": 1.0})
		enemy.position = positions[index]
		enemy.side_blend = 1.0
		enemy.horizontal_facing = -1 if index % 2 == 0 else 1
		enemy.turn_progress = 1.0
	session.pickups.spawn_pickup("xp", Vector2(-55, 110), 8)
	session.pickups.spawn_pickup("heart", Vector2(25, 130), 22)
	session.pickups.spawn_pickup("magnet", Vector2(78, 90), 1)
	session.skills.runtime.volley_timer = 0.0
	session.skills.advance(0.01, 0.01, session.state.elapsed)
	session.projectiles.advance(0.06)
	session.pause()
	game.hud.tutorial_step = 1
	game.hud.tutorial_time = 0.0
	game.hud.tutorial_panel.visible = false
	game.hud.stage_hud.banner_time = 0.0
	game.hud.stage_hud.advance(0.0)
	game.refresh_presentation()


func _prepare_ember_ultimate(game: Node) -> void:
	if game.upgrade_overlay.visible:
		game.upgrade_overlay.choice_selected.emit(str(game.upgrade_overlay.buttons[0].get_meta("choice_id")))
	var session: Node = game.session
	for skill_id in session.skills.active_skill_ids:
		session.skills.levels[skill_id] = 3
	session.skills.runtime.volley_timer = 0.0
	session.skills.runtime.meteor_timer = 0.0
	session.skills.runtime.phoenix_timer = 0.0
	session.skills.advance(0.1, 0.1, session.state.elapsed)
	session.pause()
	game.refresh_presentation()


func _settle_character_page(game: Node) -> void:
	var page: Control = game.start_screen.character_page
	var panel: Control = page.section_panels[page.current_section]
	panel.position.y = page.PANEL_Y
	panel.modulate = Color.WHITE


func _capture(file_name: String) -> bool:
	var succeeded := CaptureSetup.capture(self, file_name)
	if not succeeded:
		quit(1)
	return succeeded
