extends SceneTree

const AudioManager = preload("res://scripts/audio_manager.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const FrontendShell = preload("res://scripts/ui/frontend_shell.gd")
const HomeShellContract = preload("res://tools/support/home_shell_contract.gd")

var failed := false
var frame_count := 0
var screen: CanvasLayer
var shell_instances: Array[int]


func _initialize() -> void:
	var host := Node.new()
	root.add_child(host)
	var audio := AudioManager.new()
	host.add_child(audio)
	screen = FrontendShell.new()
	host.add_child(screen)
	screen.configure(RunRecords.new(""), audio)
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count == 3:
		shell_instances = HomeShellContract.snapshot(screen)
		_require(screen.selected_level_id == "level_01", "初始关卡不是第一关")
		_require(screen.level_preview.title_label.text == "风铃草原", "第一关信息没有进入动态关卡区域")
		screen.level_selector.move_by(1)
	elif frame_count == 8:
		_require(screen.selected_level_id == "level_02", "第一次滑动没有切换到第二关")
		_require(HomeShellContract.snapshot(screen) == shell_instances, "第一次滑动替换了远征页面组件树")
		_require(screen.level_preview.title_label.text == "金砂绿洲", "第二关信息没有更新")
		_require(screen.level_selector.page_label.text == "第 2 / %d 关" % LevelCatalog.all().size(), "第二关页码没有更新")
		screen.level_selector.move_by(1)
	elif frame_count == 13:
		_require(screen.selected_level_id == "level_03", "第二次滑动没有切换到第三关")
		_require(HomeShellContract.snapshot(screen) == shell_instances, "第二次滑动替换了远征页面组件树")
		_require(screen.level_preview.title_label.text == "彩晶火山", "第三关信息没有更新")
		_require(screen.level_selector.page_label.text == "第 3 / %d 关" % LevelCatalog.all().size(), "第三关页码没有更新")
		if not failed:
			print("HOME_CONTINUITY_OK levels=%d shell=stable data=updated" % LevelCatalog.all().size())
		quit(1 if failed else 0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("HOME_CONTINUITY_FAILED: " + message)
