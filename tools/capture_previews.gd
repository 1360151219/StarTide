extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")

var frame_count := 0


func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count > 160:
		push_error("CAPTURE_FAILED: 主场景加载或截图流程超时")
		quit(1)
		return
	var game := current_scene
	if game == null:
		return
	if frame_count == 2:
		CaptureSetup.isolate_records(game)
	elif frame_count == 10:
		_capture("start.png")
	elif frame_count == 12:
		game.start_screen.audio_settings.open_popup()
	elif frame_count == 18:
		_capture("audio_settings.png")
	elif frame_count == 20:
		game.start_screen.audio_settings.close_popup()
		game.start_screen.open_compendium("heroes")
	elif frame_count == 26:
		_capture("compendium_heroes.png")
	elif frame_count == 30:
		game.start_screen.compendium.show_category("enemies")
	elif frame_count == 36:
		_capture("compendium_enemies.png")
	elif frame_count == 40:
		game.start_screen.compendium.show_category("pickups")
	elif frame_count == 46:
		_capture("compendium_pickups.png")
	elif frame_count == 50:
		game.start_screen.compendium.show_category("skills")
	elif frame_count == 56:
		_capture("compendium_skills.png")
	elif frame_count == 58:
		game.start_screen.compendium.show_category("relics")
	elif frame_count == 62:
		_capture("compendium_relics.png")
	elif frame_count == 64:
		game.start_screen.compendium.close()
		game.start_screen._show_hero_selection()
	elif frame_count == 68:
		_capture("hero_selection.png")
	elif frame_count == 70:
		game.start_screen.training_panel.show_for("star_warden")
	elif frame_count == 76:
		_capture("hero_training.png")
	elif frame_count == 78:
		game.start_screen.training_panel._close()
		game.start_run("ember_ranger", "level_01")
	elif frame_count == 86:
		_prepare_ember_showcase(game)
	elif frame_count == 92:
		_capture("gameplay_ember.png")
	elif frame_count == 98:
		game.session.resume()
		game.hud.pause_requested.emit()
	elif frame_count == 104:
		_capture("pause.png")
	elif frame_count == 110:
		game.pause_overlay.resume_requested.emit()
		game.session.add_experience(40)
	elif frame_count == 116:
		_capture("upgrade_ember.png")
	elif frame_count == 122:
		_prepare_ember_ultimate(game)
	elif frame_count == 130:
		_capture("ultimate_ember.png")
	elif frame_count == 134:
		game.result_overlay.show_result(
			"远征完成",
			"坚持 90 秒\n击败 42\n英雄等级 4",
			"首次通关 · 星潮徽记\n英雄熟练度 +120",
			true,
			"技能：烬羽连矢 III·群羽纷飞 / 陨星雨 II·天罚坠击\n遗物：聚能棱晶 II / 流光羽 I · 重抽 0"
		)
	elif frame_count == 140:
		if _capture("result_victory.png"):
			print("CAPTURE_OK set=previews")
			quit()


func _prepare_ember_showcase(game: Node) -> void:
	var session: Node = game.session
	if session.enemies.enemies.size() < 5:
		push_error("CAPTURE_FAILED: 英雄预览至少需要 5 个初始敌人")
		quit(1)
		return
	session.player.max_health = 999.0
	session.player.health = 999.0
	session.player.facing = Vector2.RIGHT
	session.player.movement_amount = 1.0
	session.player.side_blend = 1.0
	session.player.horizontal_facing = 1
	session.skills.levels["meteor_rain"] = 2
	session.skills.levels["phoenix_heart"] = 1
	var kinds := ["slime", "bat", "brute", "slime", "bat"]
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
	session.pause()
	game.refresh_presentation()


func _prepare_ember_ultimate(game: Node) -> void:
	if game.upgrade_overlay.visible:
		game.upgrade_overlay.buttons[0].pressed.emit()
	var session: Node = game.session
	for skill_id in session.skills.active_skill_ids:
		session.skills.levels[skill_id] = 3
	session.skills.runtime.volley_timer = 0.0
	session.skills.runtime.meteor_timer = 0.0
	session.skills.runtime.phoenix_timer = 0.0
	session.skills.advance(0.1, 0.1, session.state.elapsed)
	session.pause()
	game.refresh_presentation()


func _capture(file_name: String) -> bool:
	var succeeded := CaptureSetup.capture(self, file_name)
	if not succeeded:
		quit(1)
	return succeeded
