extends SceneTree

const AudioManager = preload("res://scripts/audio_manager.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const StartScreen = preload("res://scripts/ui/start_screen.gd")

var failed := false
var frame_count := 0
var start_payload: Array[String] = []
var screen: CanvasLayer


func _initialize() -> void:
	var host := Node.new()
	root.add_child(host)
	var audio := AudioManager.new()
	host.add_child(audio)
	screen = StartScreen.new()
	host.add_child(screen)
	screen.configure(RunRecords.new(""), audio)
	screen.start_requested.connect(_on_start_requested)
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	frame_count += 1
	if frame_count < 3:
		return
	_require(screen.lobby_view.visible and not screen.hero_view.visible, "默认页面不是关卡大厅")
	_require(screen.level_preview.animation_player.is_playing(), "动态关卡预览没有播放")
	_require(screen.level_preview.preview_sprite is AnimatedSprite2D and screen.level_preview.preview_sprite.is_playing(), "关卡预览没有使用 AnimatedSprite2D")
	_require(screen.level_preview.phase > 0.0, "关卡预览画面没有随时间更新")
	screen.level_selector.buttons["level_02"].pressed.emit()
	_require(screen.selected_level_id == "level_02", "未解锁关卡不能预览")
	_require(screen.start_button.disabled, "未解锁关卡可以进入")
	screen.level_selector.buttons["level_01"].pressed.emit()
	screen.start_button.pressed.emit()
	_require(screen.hero_view.visible and not screen.lobby_view.visible, "进入游戏后未显示英雄选择")
	_require(start_payload.is_empty(), "打开英雄选择时提前开始了游戏")
	_require(not screen.level_preview.animation_player.is_playing(), "离开大厅后预览仍在运行")
	_require(not screen.level_preview.preview_sprite.is_playing(), "离开大厅后预览精灵仍在运行")
	screen.hero_selector.select_hero("ember_ranger")
	_require(screen.selected_hero_id == "ember_ranger", "英雄选择没有同步")
	screen.training_panel.show_for("ember_ranger")
	_require(screen.training_panel.skill_buttons.size() == 3, "英雄培养没有展示三项技能")
	screen.training_panel._close()
	screen.confirm_button.pressed.emit()
	_require(start_payload == ["ember_ranger", "level_01"], "开始事件没有保留 hero_id/level_id 接口")
	if not failed:
		print("START_UI_OK flow=level_then_hero preview=animated locked_preview=true training=3")
	quit(1 if failed else 0)


func _on_start_requested(hero_id: String, level_id: String) -> void:
	start_payload = [hero_id, level_id]


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("START_UI_FAILED: " + message)
