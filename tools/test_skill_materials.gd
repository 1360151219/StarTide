extends SceneTree

const Projectile = preload("res://scripts/projectile.gd")
const Effects = preload("res://scripts/combat_effects.gd")
const Impact = preload("res://scripts/skills/skill_impact_visual.gd")

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for level in range(1, 6):
		for branch in ["star_lance_pierce", "star_lance_fan", "ember_volley_blast", "ember_volley_flock"]:
			_test_projectile(level, branch if level > 1 else "", branch.begins_with("ember"))
	_test_impacts()
	if not failed: print("SKILL_MATERIALS_OK levels=5 branches=4 pause=true collision=unchanged impact_budget=64 cleanup=true")
	quit(1 if failed else 0)

func _test_projectile(level: int, branch: String, fiery: bool) -> void:
	var player := Node2D.new()
	root.add_child(player)
	var projectile := Projectile.new()
	projectile.visual_player = player
	projectile.visual_kind = "ember_arrow" if fiery else "star_lance"
	projectile.skill_level = level
	projectile.branch_id = branch
	projectile.velocity = Vector2(600, 0)
	projectile.radius = 7.0
	root.add_child(projectile)
	_require(is_zero_approx(projectile.visual.wake.modulate.a), "飞行前凭空出现长尾")
	projectile.advance(0.1)
	var pose: Transform2D = projectile.visual.body.transform
	var age: float = projectile.visual.body.material.get_shader_parameter("age")
	_require(is_equal_approx(age, 0.1) and projectile.position == Vector2(60, 0), "材质与弹体时钟不同步或改变轨迹")
	_require(is_equal_approx(projectile.collision_fraction(Vector2(40, 0), 10.0), 0.5), "材质改造改变了连续碰撞")
	projectile.advance(0.0)
	_require(projectile.visual.body.transform == pose and projectile.visual.body.material.get_shader_parameter("age") == age, "暂停时弹体材质仍在运动")
	player.position += Vector2(30, -20)
	projectile.visual.refresh()
	_require(projectile.visual.body.material.get_shader_parameter("hero_position") == player.global_position, "投射物保护区没有跟随移动或错误改变世界尺寸")
	_require(projectile.radius == 7.0 and projectile.visual.get_child_count() == 2, "弹体尺寸影响碰撞或超出层数预算")
	projectile.free()
	player.free()

func _test_impacts() -> void:
	var effects := Effects.new()
	var player := Node2D.new()
	root.add_child(effects)
	root.add_child(player)
	effects.player = player
	for kind in Impact.KINDS:
		for level in range(1, 6):
			effects.add_effect(Vector2(120, 130), 40.0, Color.WHITE, 0.28, kind, {"level": level})
			var visual: Node2D = effects.effects[0]["visual"]
			effects.advance(0.07)
			var age: float = visual.elapsed
			effects.advance(0.0)
			_require(visual.elapsed == age and visual.z_index < 3920, "命中动画暂停失效或遮挡危险预警")
			player.position += Vector2(20, 5)
			effects.advance(0.0)
			for cloud in visual.clouds:
				_require(cloud.material.get_shader_parameter("hero_position") == player.global_position, "命中材质的角色保护区没有跟随")
			_require(visual.clouds.size() <= 2, "命中云雾超过层数预算")
			effects.advance(0.3)
			_require(not is_instance_valid(visual) and effects.get_child_count() == 0, "命中结束后残留材质实例")
	for index in range(64): effects.add_effect(Vector2.ZERO, 30.0, Color.WHITE, 0.28, "star_hit")
	var evicted: Node = effects.effects[0]["visual"]
	effects.add_effect(Vector2.ZERO, 30.0, Color.WHITE, 0.28, "phoenix_impact")
	_require(not is_instance_valid(evicted) and effects.get_child_count() == 64, "命中预算淘汰没有同步释放节点")
	effects.add_effect(Vector2.ZERO, 30.0, Color.WHITE, 0.28, "star_hit")
	_require(effects.get_child_count() == 64, "低优先级命中突破总预算")
	effects.clear_all()
	_require(effects.effects.is_empty() and effects.get_child_count() == 0, "战斗清理后命中特效仍残留")
	player.free()
	effects.free()

func _require(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("SKILL_MATERIALS_FAILED: " + message)
