extends SceneTree

const HeroRigScene = preload("res://scenes/presentation/hero_rig_2d.tscn")
const SpriteCatalog = preload("res://scripts/presentation/hero_sprite_catalog.gd")
const EXPECTED_FRAME_COUNTS := {
	"menu_idle": 1,
	"menu_react": 3,
	"idle": 1,
	"run": 2,
	"cast": 3,
	"hit": 3,
	"victory": 3,
}

var failed := false


func _initialize() -> void:
	_test_generated_full_body_heroes()
	_test_state_transitions_and_facing()
	_test_pause_and_fallback()
	_test_frame_canvas_contract()
	if not failed:
		print("HERO_RIG_OK heroes=2 full_body_components=1 states=7 baseline=488")
	quit(1 if failed else 0)


func _test_generated_full_body_heroes() -> void:
	for hero_id in SpriteCatalog.HERO_IDS:
		var rig = HeroRigScene.instantiate()
		root.add_child(rig)
		rig.configure(hero_id, 96.0)
		_require(rig.hero_id == hero_id, "角色 ID 没有应用：" + hero_id)
		_require(not rig.is_layered(), "完整帧角色不应声明为分层骨骼：" + hero_id)
		_require(rig.part_count() == 1, "完整帧角色必须只有一个绘制组件：" + hero_id)
		_require(rig.articulated_component_count() == 1, "完整帧角色不能残留分段肢体：" + hero_id)
		_require(rig.sprite is AnimatedSprite2D, "缺少 AnimatedSprite2D：" + hero_id)
		_require(rig.sprite.position == Vector2(-256.0, -488.0), "角色脚底原点不稳定：" + hero_id)
		_require(
			is_equal_approx(rig.visual_root.scale.x, 96.0 / SpriteCatalog.ART_HEIGHT),
			"显示高度缩放不正确：" + hero_id
		)
		var frames: SpriteFrames = rig.sprite.sprite_frames
		for state_id in SpriteCatalog.STATES:
			var animation_name := StringName(state_id)
			_require(frames.has_animation(animation_name), "缺少动作：" + state_id)
			_require(
				frames.get_frame_count(animation_name) == EXPECTED_FRAME_COUNTS[state_id],
				"%s 的 %s 帧数错误" % [hero_id, state_id]
			)
			_require(
				frames.get_animation_loop(animation_name) == ["menu_idle", "idle", "run"].has(state_id),
				"%s 的 %s 循环设置错误" % [hero_id, state_id]
			)
			for frame_index in range(frames.get_frame_count(animation_name)):
				var texture := frames.get_frame_texture(animation_name, frame_index)
				_require(
					Vector2i(texture.get_width(), texture.get_height()) == SpriteCatalog.FRAME_SIZE,
					"%s 的 %s 使用了错误尺寸帧" % [hero_id, state_id]
				)
		rig.free()


func _test_state_transitions_and_facing() -> void:
	var rig = HeroRigScene.instantiate()
	root.add_child(rig)
	rig.configure("star_warden", 120.0)
	for state_id in rig.available_states():
		_require(rig.play_state(state_id, true), "动画状态不可播放：" + state_id)
		_require(rig.sprite.animation == StringName(state_id), "动作没有传递到帧播放器：" + state_id)
	_require(not rig.play_state("missing_state", true), "接受了不存在的动作")
	rig.play_state("menu_idle", true)
	rig.trigger_menu_react()
	rig._process(1.0)
	_require(rig.current_state == "menu_idle", "菜单互动没有回到菜单待机")
	rig.play_state("idle", true)
	rig.set_motion(Vector2.RIGHT, 1.0)
	_require(rig.current_state == "run", "移动没有切换到跑步")
	_require(not rig.sprite.flip_h, "向右移动时角色被错误镜像")
	rig.set_facing(Vector2.LEFT)
	_require(rig.sprite.flip_h, "向左移动时角色没有整体镜像")
	_require(rig.visual_root.scale.x > 0.0, "翻面过程把完整角色压缩或反转")
	_require(is_equal_approx(rig.turn_width, 0.85), "翻面没有产生安全的轮廓回弹")
	rig._process(0.2)
	_require(is_equal_approx(rig.turn_width, 1.0), "翻面后没有恢复完整宽度")
	rig.trigger_hit()
	rig._process(1.0)
	_require(rig.current_state == "run", "受击动作没有回到移动状态")
	rig.set_motion(Vector2.DOWN, 0.0)
	_require(rig.current_state == "idle", "停止移动没有回到待机")
	rig.free()


func _test_pause_and_fallback() -> void:
	var rig = HeroRigScene.instantiate()
	root.add_child(rig)
	rig.configure("ember_ranger", 188.0)
	rig.play_state("run", true)
	rig.set_active(false)
	_require(not rig.sprite.is_playing(), "暂停后帧动画仍在播放")
	_require(not rig.is_processing(), "暂停后动作计时仍在推进")
	rig.set_active(true)
	_require(rig.sprite.is_playing(), "恢复后帧动画没有继续")
	_require(rig.is_processing(), "恢复后动作计时没有继续")
	rig.configure("ember_ranger", 96.0, {}, false)
	var fallback: Texture2D = rig.sprite.sprite_frames.get_frame_texture(&"idle", 0)
	_require(
		Vector2i(fallback.get_width(), fallback.get_height()) == SpriteCatalog.FRAME_SIZE,
		"完整立绘兜底没有归一化到动作画布"
	)
	_require(
		_alpha_bounds(fallback.get_image()).end.y == int(SpriteCatalog.FOOT_BASELINE),
		"完整立绘兜底没有对齐脚底基线"
	)
	_require(rig.part_count() == 1, "兜底角色重新启用了拆件骨骼")
	rig.free()


func _test_frame_canvas_contract() -> void:
	for hero_id in SpriteCatalog.HERO_IDS:
		for pose_id in ["idle", "run_contact", "run_pass", "cast", "hit", "victory"]:
			var path := SpriteCatalog.pose_path(hero_id, pose_id)
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			_require(not image.is_empty(), "动作帧无法读取：" + path)
			_require(image.get_size() == SpriteCatalog.FRAME_SIZE, "动作帧画布尺寸错误：" + path)
			var alpha_bounds := _alpha_bounds(image)
			_require(alpha_bounds.size != Vector2i.ZERO, "动作帧没有可见像素：" + path)
			_require(alpha_bounds.end.y == int(SpriteCatalog.FOOT_BASELINE), "脚底基线错误：" + path)
			_require(
				alpha_bounds.position.x > 0
				and alpha_bounds.position.y > 0
				and alpha_bounds.end.x < SpriteCatalog.FRAME_SIZE.x,
				"动作帧触碰画布边缘：" + path
			)


func _alpha_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.01:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < 0:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("HERO_RIG_FAILED: " + message)
