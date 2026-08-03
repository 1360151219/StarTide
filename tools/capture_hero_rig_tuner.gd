extends SceneTree

const CaptureSetup = preload("res://tools/support/capture_setup.gd")

var frame_count := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/tools/hero_rig_tuner.tscn")
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count > 90:
		push_error("HERO_RIG_TUNER_CAPTURE_FAILED: 调参器加载超时")
		quit(1)
		return
	if current_scene == null or frame_count < 12:
		return
	if CaptureSetup.capture(self, "hero_rig_tuner.png"):
		print("HERO_RIG_TUNER_CAPTURE_OK")
		quit()
