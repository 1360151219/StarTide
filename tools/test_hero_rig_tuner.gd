extends SceneTree

const TunerScene = preload("res://scenes/tools/hero_rig_tuner.tscn")
const TunerContract = preload("res://tools/hero_rig_tuner_contract.gd")
const FORBIDDEN_RUNTIME_SYMBOLS := [
	"get_tuning_snapshot",
	"apply_tuning_value",
	"save_tuning_profile",
	"reset_tuning_profile",
	"set_debug_skeleton_visible",
	"set_debug_selected_bone",
]

var tuner
var frame_count := 0
var failed := false


func _initialize() -> void:
	tuner = TunerScene.instantiate()
	root.add_child(tuner)
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count < 4:
		return
	_require(TunerContract.has_preview_api(tuner.rig), "HeroRig2D 缺少帧预览稳定接口")
	_require(tuner.hero_selector.item_count == 2, "英雄选择器数量错误")
	_require(tuner.action_selector.item_count == tuner.rig.available_states().size(), "动作选择器没有完整读取运行时状态")
	_require(tuner.action_selector.item_count == 7, "动作选择器数量错误")
	_require(tuner.preview_size_selector.item_count == 3, "预览尺寸数量错误")
	_require(is_equal_approx(tuner.selected_preview_height, 188.0), "默认预览尺寸不是角色中心尺寸")
	_require(not tuner.play_button.disabled and not tuner.replay_button.disabled, "帧预览控制没有启用")
	_require(tuner.get_node_or_null("%BoneSelector") == null, "场景仍暴露骨骼选择器")
	_require(tuner.get_node_or_null("%PositionX") == null, "场景仍暴露骨骼位置控件")
	_test_action_selection()
	_test_playback()
	_test_preview_sizes()
	_test_hero_selection()
	_test_source_boundary()
	if not failed:
		print("HERO_RIG_TUNER_OK heroes=2 actions=7 sizes=3 frame_preview=true")
	tuner.free()
	quit(1 if failed else 0)


func _test_action_selection() -> void:
	var run_index := _find_metadata(tuner.action_selector, "run")
	_require(run_index >= 0, "缺少奔跑动作")
	tuner.action_selector.select(run_index)
	tuner.action_selector.item_selected.emit(run_index)
	_require(tuner.selected_action_id == "run", "动作切换没有更新帧预览")
	tuner.replay_button.pressed.emit()
	_require(tuner.selected_action_id == "run", "重播改变了所选动作")


func _test_playback() -> void:
	tuner.play_button.pressed.emit()
	_require(not tuner.is_playing, "暂停按钮没有冻结预览")
	_require(tuner.play_button.text == "继续播放", "暂停后的按钮文案错误")
	tuner.play_button.pressed.emit()
	_require(tuner.is_playing, "继续按钮没有恢复预览")
	_require(tuner.play_button.text == "暂停预览", "继续后的按钮文案错误")


func _test_preview_sizes() -> void:
	var compact_index := _find_metadata(tuner.preview_size_selector, 96.0)
	_require(compact_index >= 0, "缺少实战尺寸")
	tuner.preview_size_selector.select(compact_index)
	tuner.preview_size_selector.item_selected.emit(compact_index)
	_require(is_equal_approx(tuner.selected_preview_height, 96.0), "预览尺寸切换没有生效")


func _test_hero_selection() -> void:
	tuner.hero_selector.select(1)
	tuner.hero_selector.item_selected.emit(1)
	_require(tuner.selected_hero_id == "ember_ranger", "切换英雄没有重载帧预览")


func _test_source_boundary() -> void:
	for path in [
		"res://tools/hero_rig_tuner.gd",
		"res://tools/hero_rig_tuner_contract.gd",
	]:
		var source := FileAccess.get_file_as_string(path)
		for symbol in FORBIDDEN_RUNTIME_SYMBOLS:
			_require(not source.contains(symbol), "%s 仍依赖旧骨骼接口 %s" % [path, symbol])


func _find_metadata(selector: OptionButton, expected: Variant) -> int:
	for index in range(selector.item_count):
		if selector.get_item_metadata(index) == expected:
			return index
	return -1


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("HERO_RIG_TUNER_FAILED: " + message)
