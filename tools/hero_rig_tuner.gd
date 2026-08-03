extends Control

const TunerContract = preload("res://tools/hero_rig_tuner_contract.gd")

@onready var hero_selector: OptionButton = %HeroSelector
@onready var action_selector: OptionButton = %ActionSelector
@onready var preview_size_selector: OptionButton = %PreviewSizeSelector
@onready var play_button: Button = %PlayButton
@onready var replay_button: Button = %ReplayButton
@onready var status_label: Label = %StatusLabel
@onready var preview_canvas: Control = %PreviewCanvas
@onready var rig: Node2D = %HeroRig2D

var selected_hero_id := ""
var selected_action_id := ""
var selected_preview_height := TunerContract.DEFAULT_PREVIEW_HEIGHT
var is_playing := true
var desktop_enabled := true


func _ready() -> void:
	desktop_enabled = not OS.has_feature("mobile")
	TunerContract.configure_desktop_window()
	_connect_controls()
	TunerContract.populate_heroes(hero_selector)
	TunerContract.populate_actions(action_selector, rig)
	TunerContract.populate_preview_sizes(preview_size_selector)
	preview_canvas.resized.connect(_center_rig)
	call_deferred("_initialize_selection")


func _connect_controls() -> void:
	hero_selector.item_selected.connect(_on_hero_selected)
	action_selector.item_selected.connect(_on_action_selected)
	preview_size_selector.item_selected.connect(_on_preview_size_selected)
	play_button.pressed.connect(_toggle_playback)
	replay_button.pressed.connect(_replay_selected_action)


func _initialize_selection() -> void:
	if not desktop_enabled:
		_set_editor_enabled(false)
		_set_status("此场景仅供桌面开发使用，移动端已禁用。", true)
		return
	if not TunerContract.has_preview_api(rig):
		_set_editor_enabled(false)
		_set_status("HeroRig2D 缺少帧预览所需的稳定接口。", true)
		return
	if hero_selector.item_count <= 0 or action_selector.item_count <= 0:
		_set_editor_enabled(false)
		_set_status("英雄或动作目录为空。", true)
		return
	_on_preview_size_selected(preview_size_selector.selected)
	_on_hero_selected(hero_selector.selected)
	_on_action_selected(action_selector.selected)
	_center_rig()


func _on_hero_selected(index: int) -> void:
	selected_hero_id = TunerContract.selected_id(hero_selector, index)
	if selected_hero_id.is_empty():
		return
	_configure_preview()


func _on_action_selected(index: int) -> void:
	selected_action_id = TunerContract.selected_id(action_selector, index)
	if selected_action_id.is_empty():
		return
	_play_selected_action()


func _on_preview_size_selected(index: int) -> void:
	selected_preview_height = TunerContract.selected_preview_height(preview_size_selector, index)
	if not selected_hero_id.is_empty():
		_configure_preview()


func _configure_preview() -> void:
	rig.configure(selected_hero_id, selected_preview_height)
	_play_selected_action()


func _toggle_playback() -> void:
	is_playing = not is_playing
	rig.set_active(is_playing)
	play_button.text = "暂停预览" if is_playing else "继续播放"
	_set_status("动作预览已%s。" % ("播放" if is_playing else "暂停"))


func _replay_selected_action() -> void:
	_play_selected_action()
	_set_status("已从首帧重播 %s。" % TunerContract.action_name(selected_action_id))


func _play_selected_action() -> void:
	if selected_action_id.is_empty():
		return
	rig.set_active(true)
	var accepted: bool = rig.play_state(selected_action_id, true)
	if not is_playing:
		rig.set_active(false)
	_set_status(
		"%s · %s · %.0f px" % [
			TunerContract.hero_name(selected_hero_id),
			TunerContract.action_name(selected_action_id),
			selected_preview_height,
		],
		not accepted
	)


func _set_editor_enabled(enabled: bool) -> void:
	hero_selector.disabled = not enabled
	action_selector.disabled = not enabled
	preview_size_selector.disabled = not enabled
	play_button.disabled = not enabled
	replay_button.disabled = not enabled


func _center_rig() -> void:
	rig.position = Vector2(preview_canvas.size.x * 0.5, preview_canvas.size.y * 0.88)


func _set_status(message: String, error := false) -> void:
	status_label.text = message
	status_label.modulate = Color("ff9c8f") if error else Color("a9e9df")
