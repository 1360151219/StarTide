extends SceneTree

const AudioManager = preload("res://scripts/audio_manager.gd")
const RunRecords = preload("res://scripts/run_records.gd")
const StartScreen = preload("res://scripts/ui/start_screen.gd")
const LevelSelector = preload("res://scripts/ui/level_selector.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")

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
	_require(screen.level_selector.page_buttons.size() == 3, "轮播没有固定复用三个页面节点")
	_require(screen.level_selector.page_label.text == "第 1 / 3 关", "轮播页码错误")
	_require(screen.level_selector.left_button.disabled and not screen.level_selector.right_button.disabled, "轮播首尾按钮状态错误")
	var caption_center: Vector2 = screen.start_button.caption.position + screen.start_button.caption.size * 0.5
	_require(caption_center.is_equal_approx(screen.start_button.size * 0.5), "踏入星门文案没有居中")
	screen.open_compendium("enemies")
	_require(screen.compendium.list.get_child_count() == 4, "锁定内容没有保留图鉴槽位")
	_require(screen.compendium.tab_buttons["enemies"].text == "怪物 0/4", "怪物图鉴进度错误")
	_require(not bool(screen.compendium.list.get_child(0).get_meta("discovered", true)), "新存档错误显示怪物详情")
	screen.records.discover_content("enemies", "green_grub")
	screen.compendium.show_category("enemies")
	_require(screen.compendium.tab_buttons["enemies"].text == "怪物 1/4", "发现怪物后图鉴进度没有刷新")
	_require(bool(screen.compendium.list.get_child(0).get_meta("discovered", false)), "发现怪物后图鉴详情仍被锁定")
	screen.compendium.show_category("relics")
	_require(screen.compendium.list.get_child_count() == 6, "遗物没有保留全部图鉴槽位")
	_require(screen.compendium.tab_buttons["relics"].text == "遗物 0/6", "遗物图鉴进度错误")
	_require(not bool(screen.compendium.list.get_child(0).get_meta("discovered", true)), "未获得遗物错误显示详情")
	screen.records.discover_content("skills", "star_lance")
	screen.compendium.show_category("skills")
	var discovered_skill_card: Panel = screen.compendium.list.get_child(0)
	var skill_description: Label = discovered_skill_card.get_child(3)
	_require(skill_description.text.contains("分支 · ？？？"), "未选过的技能分支提前显示详情")
	screen.compendium.close()
	screen.level_selector.right_button.pressed.emit()
	_require(screen.selected_level_id == "level_02", "未解锁关卡不能预览")
	_require(screen.start_button.disabled, "未解锁关卡可以进入")
	_require(screen.level_preview.lock_panel.visible and screen.level_preview.preview_sprite.visible, "锁定关卡没有保留可见预览")
	var touch := InputEventScreenTouch.new()
	touch.index = 8
	touch.pressed = true
	touch.position = Vector2(120, 180)
	screen.level_preview._gui_input(touch)
	touch.pressed = false
	touch.position = Vector2(250, 180)
	screen.level_preview._gui_input(touch)
	_require(screen.selected_level_id == "level_01", "关卡预览区域右滑没有切换上一关")
	_require(screen.level_selector.left_button.disabled, "返回首关后左箭头仍可用")
	_test_constant_carousel_nodes()
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
		print("START_UI_OK flow=level_then_hero preview=animated carousel=3 swipe=true locked_preview=true centered=true training=3 compendium=discovery")
	quit(1 if failed else 0)


func _on_start_requested(hero_id: String, level_id: String) -> void:
	start_payload = [hero_id, level_id]


func _test_constant_carousel_nodes() -> void:
	var carousel := LevelSelector.new()
	root.add_child(carousel)
	var templates := LevelCatalog.all()
	var simulated_levels: Array[LevelConfig] = []
	for index in range(12):
		var level := templates[index % templates.size()].duplicate(true) as LevelConfig
		level.level_id = "carousel_%02d" % (index + 1)
		level.display_name = "模拟关卡 %d" % (index + 1)
		simulated_levels.append(level)
	carousel.configure(simulated_levels, screen.records, simulated_levels[0].level_id)
	var child_count := carousel.get_child_count()
	_require(carousel.page_buttons.size() == 3, "12关轮播创建了超过三个页面节点")
	carousel.configure(LevelCatalog.all(), screen.records, "level_01")
	_require(carousel.get_child_count() == child_count and carousel.page_buttons.size() == 3, "轮播节点数量随关卡数量变化")
	carousel.queue_free()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("START_UI_FAILED: " + message)
