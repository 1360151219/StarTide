extends Control

signal level_selected(level_id: String)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const MEDALLIONS := {
	"level_01": preload("res://assets/art/ui/home/biome_meadow_medallion.png"),
	"level_02": preload("res://assets/art/ui/home/biome_oasis_medallion.png"),
	"level_03": preload("res://assets/art/ui/home/biome_volcano_medallion.png"),
}

var records: RefCounted
var levels: Array[LevelConfig]
var selected_level_id := "level_01"
var buttons: Dictionary = {}
var title_labels: Dictionary = {}
var status_labels: Dictionary = {}
var detail_label: Label


func configure(level_configs: Array[LevelConfig], run_records: RefCounted, initial_level_id: String) -> void:
	levels = level_configs
	records = run_records
	selected_level_id = initial_level_id if records.is_level_unlocked(initial_level_id) else levels[0].level_id
	size = Vector2(504, 194)
	for index in range(levels.size()):
		_build_medallion(levels[index], index)
	detail_label = UiFactory.label("", 13, Color("e9f8ef"))
	detail_label.position = Vector2(4, 174)
	detail_label.size = Vector2(496, 20)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(detail_label)
	refresh()


func select_level(level_id: String, emit_change := true) -> void:
	if not buttons.has(level_id):
		return
	selected_level_id = level_id
	refresh()
	if emit_change:
		level_selected.emit(level_id)


func refresh() -> void:
	for level in levels:
		var button: TextureButton = buttons[level.level_id]
		var unlocked: bool = records.is_level_unlocked(level.level_id)
		var selected := level.level_id == selected_level_id
		button.disabled = false
		button.self_modulate = Color.WHITE if selected else Color(0.72, 0.78, 0.8, 0.9)
		button.scale = Vector2.ONE * (1.025 if selected else 1.0)
		button.tooltip_text = "%s · %s" % [level.display_name, level.subtitle]
		title_labels[level.level_id].text = level.display_name
		status_labels[level.level_id].text = "难度 %s" % "◆".repeat(level.difficulty_rating) if unlocked else "◇ 尚未解锁"
		status_labels[level.level_id].add_theme_color_override("font_color", Color("ffe59a") if selected else Color("d8e7df"))
	var selected := _selected_level()
	detail_label.text = "%s  ·  首通奖励：%s" % [records.level_summary(selected.level_id), selected.reward.display_name]


func is_selected_unlocked() -> bool:
	return records.is_level_unlocked(selected_level_id)


func _build_medallion(level: LevelConfig, index: int) -> void:
	var button := TextureButton.new()
	button.position = Vector2(index * 172.0, 0)
	button.size = Vector2(160, 160)
	button.pivot_offset = button.size * 0.5
	button.texture_normal = MEDALLIONS[level.level_id]
	button.texture_hover = MEDALLIONS[level.level_id]
	button.texture_pressed = MEDALLIONS[level.level_id]
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(select_level.bind(level.level_id))
	button.mouse_entered.connect(_set_hovered.bind(level.level_id, true))
	button.mouse_exited.connect(_set_hovered.bind(level.level_id, false))
	add_child(button)
	buttons[level.level_id] = button
	var title := UiFactory.label(level.display_name, 14, Color("2b2f2f"))
	title.position = Vector2(26, 129)
	title.size = Vector2(108, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)
	title_labels[level.level_id] = title
	var status := UiFactory.label("", 12, Color("d8e7df"))
	status.position = Vector2(0, 151)
	status.size = Vector2(160, 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(status)
	status_labels[level.level_id] = status


func _set_hovered(level_id: String, hovered: bool) -> void:
	var button: TextureButton = buttons[level_id]
	if level_id == selected_level_id:
		return
	button.self_modulate = Color(0.9, 0.95, 0.95) if hovered else Color(0.72, 0.78, 0.8, 0.9)


func _selected_level() -> LevelConfig:
	for level in levels:
		if level.level_id == selected_level_id:
			return level
	return levels[0]
