extends SceneTree

const Visual = preload("res://scripts/skills/frost_slash_visual.gd")
const Runtime = preload("res://scripts/skills/star_skill_runtime.gd")

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := Node2D.new()
	player.position = Vector2(120, 160)
	player.z_index = 100
	root.add_child(player)
	for level in range(1, 6):
		for kind in ["ultimate_upper", "ultimate_lower"] if level == 5 else ["regular"]:
			_test_stroke(player, level, kind)
	player.free()
	if not failed:
		print("FROST_SLASH_VISUAL_OK levels=5 accelerating=true hit_sync=true tail=delayed reverse=true pause=stable safe_center=tracked")
	quit(1 if failed else 0)

func _test_stroke(player: Node2D, level: int, kind: String) -> void:
	var duration: float = Runtime.ULTIMATE_SLASH_VISUAL_DURATION if level == 5 else Runtime.SLASH_VISUAL_DURATION
	var data := {"origin": player.position, "angle": 0.7, "radius": 180.0 if level == 5 else 150.0, "inner_radius": 32.0, "level": level, "kind": kind, "duration": duration, "time_left": duration}
	var visual := Visual.new()
	root.add_child(visual)
	visual.configure(data, player)
	_require(visual.main_sprite.modulate.a == 0.0 and visual.trail_sprite.modulate.a == 0.0, "寒冰斩首帧突然显示整张冰刃")
	var material := visual.main_sprite.material as ShaderMaterial
	var stages: Array[float] = []
	for at in [0.02, 0.04, 0.06, Runtime.SLASH_HIT_DELAY]:
		_seek(visual, data, at)
		stages.append(float(material.get_shader_parameter("sweep_progress")))
	_require(stages[2] - stages[1] > stages[1] - stages[0], "挥斩仍为匀速显现，没有加速切入")
	_require(is_equal_approx(stages[3], 1.0) and visual.main_sprite.modulate.a >= 0.8, "真实命中时冰刃尚未抵达峰值")
	_require(visual.main_sprite.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(visual.main_sprite.rotation), "命中帧形变偏离已定义的攻击范围")
	var trail_material := visual.trail_sprite.material as ShaderMaterial
	_require(float(trail_material.get_shader_parameter("sweep_progress")) < stages[3] and visual.trail_sprite.modulate.a < visual.main_sprite.modulate.a, "尾迹没有滞后或抢占主刃层级")
	_seek(visual, data, 0.04)
	_require(visual.main_sprite.rotation > 0.0 if kind == "ultimate_lower" else visual.main_sprite.rotation < 0.0, "回斩没有反向运动")
	var pose: Transform2D = visual.main_sprite.transform
	var progress: float = material.get_shader_parameter("sweep_progress")
	var age: float = material.get_shader_parameter("age")
	visual.refresh(data)
	_require(age > 0.0 and material.get_shader_parameter("age") == age, "寒冰斩内部材质没有跟随战斗时钟或暂停失效")
	_require(visual.main_sprite.transform.is_equal_approx(pose) and is_equal_approx(material.get_shader_parameter("sweep_progress"), progress), "暂停或重复采样仍推进了技能动画")
	var origin := visual.position
	player.position += Vector2(20, -12)
	visual.refresh(data)
	var safe_uv: Vector2 = material.get_shader_parameter("safe_center_uv")
	_require(visual.position == origin and visual.main_sprite.to_global((safe_uv - Vector2(0.5, 0.5)) * 512.0).is_equal_approx(player.global_position), "移动后施放原点漂移或角色保护区错位")
	_require(visual.main_sprite.z_index < player.z_index and visual.trail_sprite.z_index < player.z_index, "技能层级盖住角色")
	var previous_alpha := 1.0
	for at in [0.12, 0.16, 0.2, duration]:
		_seek(visual, data, at)
		_require(visual.main_sprite.modulate.a <= previous_alpha, "收尾发生二次增亮")
		previous_alpha = visual.main_sprite.modulate.a
	_require(is_zero_approx(visual.main_sprite.modulate.a) and is_zero_approx(visual.trail_sprite.modulate.a), "生命周期结束后仍残留冰刃")
	visual.free()

func _seek(visual: Node2D, data: Dictionary, at: float) -> void:
	data["time_left"] = float(data["duration"]) - at
	visual.refresh(data)

func _require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("FROST_SLASH_VISUAL_FAILED: " + message)
