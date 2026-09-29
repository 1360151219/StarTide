extends SceneTree

const Tide = preload("res://scripts/skills/frost_tide_visual.gd")
const Phoenix = preload("res://scripts/skills/phoenix_heart_visual.gd")
const Meteor = preload("res://scripts/skills/meteor_rain_visual.gd")
const Telegraph = preload("res://scripts/presentation/enemy_telegraph_renderer.gd")
const Abilities = preload("res://scripts/enemy_ability_catalog.gd")
const Shield = preload("res://scripts/passives/star_shield_passive.gd")
const Player = preload("res://scripts/player.gd")
const Effects = preload("res://scripts/combat_effects.gd")
const AudioStub = preload("res://tools/support/audio_stub.gd")
const PlayerHitData = preload("res://scripts/combat/player_hit.gd")

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := Node2D.new()
	player.position = Vector2(160, 120)
	player.z_index = 100
	root.add_child(player)
	for level in range(1, 6):
		for branch in ["frost_tide_field", "frost_tide_shatter"]:
			_test_tide(player, level, branch if level > 1 else "")
		for branch in ["phoenix_heart_inferno", "phoenix_heart_rebirth"]:
			_test_phoenix(player, level, branch if level > 1 else "")
	player.free()
	_test_warning_geometry()
	_test_shield_identity()
	_test_meteor_lifecycle()
	var first := Meteor.fall_progress(0.5) - Meteor.fall_progress(0.25)
	var last := Meteor.fall_progress(1.0) - Meteor.fall_progress(0.75)
	_require(last > first * 2.0 and Meteor.fall_progress(1.0) == 1.0, "陨星末段没有加速或错过落地时点")
	if not failed:
		print("SKILL_MOTION_OK levels=5 branches=4 wave_hit_sync=true wings_hit_sync=true pause=true safe_center=true warning_bounds=true meteor_acceleration=true")
	quit(1 if failed else 0)

func _test_tide(player: Node2D, level: int, branch: String) -> void:
	var data := {"origin": player.position, "radius": 170.0, "level": level, "branch_id": branch, "duration": 0.62, "time_left": 0.62}
	var visual := Tide.new()
	root.add_child(visual)
	visual.configure(data, player)
	_require(is_zero_approx(visual.main_sprite.modulate.a), "霜潮首帧未从零起势")
	_seek(visual, data, Tide.TRAVEL_TIME * 0.5)
	_require(is_equal_approx(visual.main_sprite.scale.x, 0.5 * 170.0 / Tide.TEXTURE_RADIUS), "视觉波前偏离真实径向命中")
	_require(visual.trail_sprite.scale.x < visual.main_sprite.scale.x, "尾潮没有落后波前")
	_check_frozen_and_safe(visual, data, player, visual.main_sprite, Vector2(1024, 1024))
	_seek(visual, data, Tide.TRAVEL_TIME)
	_require(is_equal_approx(visual.main_sprite.scale.x, 170.0 / Tide.TEXTURE_RADIUS), "霜潮未在传播结束时抵达伤害边界")
	if level == 5:
		_require(visual.crown_sprite.modulate.a > 0.5, "终极冰冠未在波前到达时凝结")
	_seek(visual, data, 0.62)
	_require(is_zero_approx(visual.main_sprite.modulate.a) and is_zero_approx(visual.trail_sprite.modulate.a), "霜潮结束后残留")
	visual.free()

func _test_phoenix(player: Node2D, level: int, branch: String) -> void:
	var data := {"origin": player.position, "radius": 180.0, "level": level, "branch_id": branch, "duration": 0.46, "time_left": 0.46}
	var visual := Phoenix.new()
	root.add_child(visual)
	visual.configure(data, player)
	_require(is_zero_approx(visual.left_main.modulate.a), "凤凰首帧突然出现完整翅膀")
	_seek(visual, data, 0.09)
	_require(visual.left_main.rotation < 0.0 and visual.right_main.rotation > 0.0, "凤凰没有左右独立展翼")
	_check_frozen_and_safe(visual, data, player, visual.left_main, Vector2(512, 1024))
	_seek(visual, data, Phoenix.IMPACT_TIME)
	for wing in [visual.left_main, visual.right_main]:
		_require(wing.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(wing.rotation), "凤凰没有在 180 ms 归位完整展开")
		_require(is_equal_approx(wing.material.get_shader_parameter("sweep_progress"), 1.0), "凤凰命中时揭示未完成")
	_require(visual.left_trail.material.get_shader_parameter("sweep_progress") < 1.0, "凤凰尾焰未滞后主体")
	var previous := 1.0
	for at in [0.235, 0.28, 0.34, 0.4, 0.46]:
		_seek(visual, data, at)
		_require(visual.left_main.modulate.a <= previous, "凤凰收尾二次增亮")
		previous = visual.left_main.modulate.a
	for wing in [visual.left_main, visual.right_main, visual.left_trail, visual.right_trail]:
		_require(is_zero_approx(wing.modulate.a), "凤凰结束后残留尾焰")
	visual.free()

func _check_frozen_and_safe(visual: Node2D, data: Dictionary, player: Node2D, sprite: Sprite2D, size: Vector2) -> void:
	var pose := sprite.transform
	var age: float = sprite.material.get_shader_parameter("age")
	_require(age > 0.0, "材质时钟没有跟随施放推进")
	visual.refresh(data)
	_require(sprite.transform.is_equal_approx(pose) and sprite.material.get_shader_parameter("age") == age, "重复刷新推进了动画或内部材质")
	var origin := visual.position
	player.position += Vector2(18, -14)
	visual.refresh(data)
	var uv: Vector2 = sprite.material.get_shader_parameter("safe_center_uv")
	_require(sprite.to_global((uv - Vector2(0.5, 0.5)) * size + sprite.offset).is_equal_approx(player.global_position), "变形后的角色保护区错位")
	_require(visual.position == origin and sprite.z_index < player.z_index, "技能跟随移动或遮挡角色")

func _test_warning_geometry() -> void:
	for length in [14.0, 100.0, 520.0, 730.0]:
		for offset in [0.0, 13.0, 37.9]:
			var segments := Telegraph.warning_dash_segments(length, offset)
			for segment in segments:
				_require(segment.x >= 0.0 and segment.y <= length and segment.y > segment.x, "虚线超出真实射程")
	var renderer := Telegraph.new()
	_require(not renderer.z_as_relative and renderer.z_index > 3900, "危险预警被友方投射物遮住")
	var enemy := Node2D.new()
	root.add_child(enemy)
	for id in Abilities.ids():
		var config := Abilities.ability(id)
		var state := {"enemy": enemy, "ability_id": id, "phase": "warning", "phase_left": float(config["warning"]) * 0.5, "direction": Vector2.RIGHT, "target": Vector2(100, 0)}
		renderer.set_states({1: state})
		var warning: Dictionary = renderer.warnings[0]
		_require(is_equal_approx(warning["progress"], 0.5) and warning["shape"] == config["shape"], "预警未采用真实阶段时钟或形状")
		_require(bool(warning["locked"]) == (config["runtime_kind"] != "bolt"), "锁定提示与实际瞄准状态不同步")
		if config["shape"] == "annular_sector":
			_require(warning["inner_radius"] == config["inner_radius"] and warning["arc_degrees"] <= 270.0, "尾扫安全内圈或缺口丢失")
	enemy.free()
	renderer.free()

func _test_shield_identity() -> void:
	var player := Player.new()
	var effects := Effects.new()
	var audio := AudioStub.new()
	var shield := Shield.new()
	shield.configure(player, effects, audio)
	_require(shield.try_absorb_hit(PlayerHitData.create(12.0, null, "test", Vector2.ZERO), 0.0), "格挡规则被改变")
	_require(effects.effects[0]["kind"] == "star_shield" and shield.damage_blocked == 12.0, "格挡仍复用攻击星芒或承伤统计改变")
	shield.advance(Vector2.ZERO, 0.1, 24.0)
	_require(effects.effects[1]["kind"] == "star_shield" and shield.ready, "护盾恢复表现或原有冷却改变")
	player.free()
	effects.free()
	audio.free()

func _seek(visual: Node2D, data: Dictionary, at: float) -> void:
	data["time_left"] = float(data["duration"]) - at
	visual.refresh(data)


func _test_meteor_lifecycle() -> void:
	var effects := Effects.new()
	var player := Node2D.new()
	root.add_child(effects)
	root.add_child(player)
	for level in range(1, 6):
		for branch in ["meteor_rain_focus", "meteor_rain_scatter"]:
			var origin := Vector2(100, 180)
			var data := {"level": level, "branch_id": branch if level > 1 else "", "player": player}
			effects.add_effect(origin, 96.0, Color.WHITE, 0.34, "meteor_warning", data)
			var visual: Node2D = effects.effects[0]["visual"]
			effects.advance(0.2)
			var pose: Transform2D = visual.comet.transform
			var age: float = visual.tail.material.get_shader_parameter("age")
			effects.advance(0.0)
			_require(visual.comet.transform == pose and visual.tail.material.get_shader_parameter("age") == age, "陨星暂停时仍推进材质或轨迹")
			player.position += Vector2(18, -12)
			effects.advance(0.0)
			_require(visual.position == origin and visual.core.material.get_shader_parameter("hero_position") == player.global_position, "陨星落点或角色保护区随移动错位")
			_require(visual.z_index < 3920 and visual.ground.z_index == 0, "陨星遮挡敌方预警或地表层次错误")
			var snapshot: Dictionary = effects.effects[0].duplicate()
			snapshot["time"] = 0.0
			visual.refresh(snapshot)
			var tip: Vector2 = visual.comet.to_global(Vector2(0, visual.body_size.y * Meteor.CORE_TIP))
			_require(tip.is_equal_approx(origin), "陨星前端未在真实落地帧接触落点")
			effects.advance(0.15)
			_require(effects.effects.is_empty() and not is_instance_valid(visual), "陨星坠落结束没有清理材质节点")
			effects.add_effect(origin, 96.0, Color.WHITE, Meteor.IMPACT_DURATION, "meteor_impact", data)
			visual = effects.effects[0]["visual"]
			_require(is_equal_approx(visual.ground.material.get_shader_parameter("front"), 0.78), "陨星命中首帧缺少完整范围冲击")
			effects.advance(0.056)
			_require(is_equal_approx(visual.ground.material.get_shader_parameter("front"), 1.0), "陨星冲击未在 56ms 到达外沿")
			effects.advance(0.12)
			_require(not visual.light.visible, "陨星暖光没有及时熄灭")
			effects.advance(Meteor.IMPACT_DURATION)
			_require(effects.get_child_count() == 0 and effects.effects.is_empty(), "陨星余烬结束后遗留节点")
	effects.add_effect(Vector2.ZERO, 60.0, Color.WHITE, 1.0, "meteor_warning")
	var evicted: Node = effects.effects[0]["visual"]
	effects.effects[0]["priority"] = 0
	for index in range(64): effects.add_effect(Vector2.ZERO, 8.0, Color.WHITE, 1.0, "defeat")
	_require(not is_instance_valid(evicted) and effects.get_child_count() == 0, "特效预算淘汰没有同步释放陨星材质")
	effects.clear_all()
	effects.add_effect(Vector2.ZERO, 60.0, Color.WHITE, 1.0, "meteor_impact")
	effects.clear_all()
	_require(effects.get_child_count() == 0, "离开战斗后陨星未清理")
	player.free()
	effects.free()

func _require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("SKILL_MOTION_FAILED: " + message)
