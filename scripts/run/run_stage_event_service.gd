extends RefCounted


static func apply(session: Node, events: Dictionary) -> void:
	var transitions: Array = events["transitions"]
	if not transitions.is_empty():
		var stage: StageConfig = transitions[-1]
		session.stage_banner_requested.emit(stage.display_name, stage.subtitle, 2.4)
		session.audio.play_sfx("stage_transition", -1.0)
	if events["elite_due"]:
		_spawn_elite(session)
	if events["boss_due"]:
		_spawn_boss(session)


static func _spawn_elite(session: Node) -> void:
	session.state.elite_spawned = true
	session.elite_enemy = session.enemies.spawn_elite(session.level.elite, session.state.elapsed)
	if is_instance_valid(session.elite_enemy):
		session.state.elite_spawned_at = session.state.elapsed
		session.effects.add_effect(session.elite_enemy.position, session.elite_enemy.radius + 52.0, Color("f6c968"), 0.72, "elite_appear")
	session.audio.play_sfx("elite_appear", 0.0)
	var stage: StageConfig = session.stage_director.current_stage()
	session.stage_banner_requested.emit("%s · %s降临" % [stage.display_name, session.level.elite.display_name], "击败可获得额外赐福与星引磁场", 2.8)


static func _spawn_boss(session: Node) -> void:
	session.state.boss_spawned = true
	session.enemies.trim_normal_enemies(session.level.boss.initial_minion_limit)
	session.boss_enemy = session.enemies.spawn_boss(session.level.boss)
	if not is_instance_valid(session.boss_enemy):
		return
	session.boss_abilities.activate(session.boss_enemy, session.state.elapsed)
	session.effects.add_effect(session.boss_enemy.position, session.boss_enemy.radius + 78.0, Color("8ed7ca"), 0.9, "boss_appear")
	session.audio.play_sfx("zouwu_appear", 0.0)
	if session.audio.has_method("crossfade_music"):
		session.audio.crossfade_music(session.level.boss.music_profile_id, session.level.boss.music_crossfade_duration)
	session.stage_banner_requested.emit("千里试炼开启", "%s踏云而至" % session.level.boss.display_name, 2.8)
