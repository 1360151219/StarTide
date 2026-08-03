extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")
const MainScene = preload("res://main.tscn")
const BASELINE_DIR := "res://preview/responsive"
const MAX_MEAN_DIFFERENCE := 0.035

var failed := false
var update_baselines := false


func _initialize() -> void:
	update_baselines = OS.get_cmdline_user_args().has("--update")
	call_deferred("_run")


func _run() -> void:
	if update_baselines:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASELINE_DIR))
	for profile in _profiles():
		await _check_profile(profile)
	if not failed:
		print("RESPONSIVE_SCREENSHOTS_OK profiles=4 threshold=%.3f updated=%s" % [MAX_MEAN_DIFFERENCE, update_baselines])
	quit(1 if failed else 0)


func _check_profile(profile: Dictionary) -> void:
	var viewport := SubViewport.new()
	viewport.size = profile["size"]
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game := MainScene.instantiate()
	viewport.add_child(game)
	for _frame in range(5):
		await process_frame
	CaptureSetup.isolate_records(game)
	game.audio_manager.audio_output_available = false
	game.audio_manager.music_enabled = true
	game.audio_manager.sfx_enabled = true
	game.audio_manager.set_music_volume(0.65, false)
	game.audio_manager.set_sfx_volume(0.75, false)
	game.start_screen.level_preview.set_active(false)
	game.start_screen.level_preview.phase = 0.25
	await process_frame
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	var baseline_path := "%s/%s.png" % [BASELINE_DIR, profile["id"]]
	if update_baselines:
		_require(image.save_png(baseline_path) == OK, "%s 基线保存失败" % profile["id"])
	else:
		_compare_with_baseline(image, baseline_path, profile["id"])
	viewport.free()
	await process_frame


func _compare_with_baseline(current: Image, path: String, profile_id: String) -> void:
	var baseline := Image.new()
	var error := baseline.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	_require(error == OK, "%s 缺少截图基线，请先使用 --update 生成" % profile_id)
	if error != OK:
		return
	_require(current.get_size() == baseline.get_size(), "%s 截图尺寸变化" % profile_id)
	if current.get_size() != baseline.get_size():
		return
	var difference := _mean_difference(current, baseline)
	_require(difference <= MAX_MEAN_DIFFERENCE, "%s 像素差异 %.4f 超过阈值" % [profile_id, difference])


func _mean_difference(first: Image, second: Image) -> float:
	var sample_size := Vector2i(maxi(1, first.get_width() / 4), maxi(1, first.get_height() / 4))
	var left := first.duplicate()
	var right := second.duplicate()
	left.resize(sample_size.x, sample_size.y, Image.INTERPOLATE_BILINEAR)
	right.resize(sample_size.x, sample_size.y, Image.INTERPOLATE_BILINEAR)
	left.convert(Image.FORMAT_RGBA8)
	right.convert(Image.FORMAT_RGBA8)
	var left_bytes: PackedByteArray = left.get_data()
	var right_bytes: PackedByteArray = right.get_data()
	var total := 0.0
	for index in range(left_bytes.size()):
		total += absf(float(left_bytes[index]) - float(right_bytes[index]))
	return total / (left_bytes.size() * 255.0)


func _profiles() -> Array[Dictionary]:
	return [
		{"id": "9_16", "size": Vector2i(540, 960)},
		{"id": "19_5_9", "size": Vector2i(540, 1170)},
		{"id": "20_9", "size": Vector2i(540, 1200)},
		{"id": "3_4", "size": Vector2i(720, 960)},
	]


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("RESPONSIVE_SCREENSHOTS_FAILED: " + message)
