extends Control

signal level_selected(level_id: String)

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var records: RefCounted
var levels: Array[LevelConfig]
var selected_level_id := "level_01"
var buttons: Dictionary = {}
var detail_label: Label


func configure(level_configs: Array[LevelConfig], run_records: RefCounted, initial_level_id: String) -> void:
	levels = level_configs
	records = run_records
	selected_level_id = initial_level_id if records.is_level_unlocked(initial_level_id) else levels[0].level_id
	size = Vector2(504, 112)
	var gap := 10.0
	var button_width := (size.x - gap * (levels.size() - 1)) / levels.size()
	for index in range(levels.size()):
		var level := levels[index]
		var button := Button.new()
		button.position = Vector2(index * (button_width + gap), 0)
		button.size = Vector2(button_width, 66)
		button.add_theme_font_size_override("font_size", 16 if button_width >= 140.0 else 14)
		button.pressed.connect(select_level.bind(level.level_id))
		add_child(button)
		buttons[level.level_id] = button
	detail_label = UiFactory.label("", 14, Color("cbd9e8"))
	detail_label.position = Vector2(4, 72)
	detail_label.size = Vector2(496, 36)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(detail_label)
	refresh()


func select_level(level_id: String) -> void:
	if not records.is_level_unlocked(level_id):
		return
	selected_level_id = level_id
	refresh()
	level_selected.emit(level_id)


func refresh() -> void:
	for level in levels:
		var button: Button = buttons[level.level_id]
		var unlocked: bool = records.is_level_unlocked(level.level_id)
		button.disabled = not unlocked
		button.text = "%s\n%s" % [level.display_name, "难度 " + "◆".repeat(level.difficulty_rating) if unlocked else "未解锁"]
		var selected := level.level_id == selected_level_id
		button.add_theme_stylebox_override("normal", UiFactory.button_style(Color("173c63") if selected else Color("101d36"), Color("f2ca72") if selected else Color("526d8c")))
		button.add_theme_stylebox_override("disabled", UiFactory.button_style(Color(0.04, 0.05, 0.08, 0.9), Color("354154")))
	var selected := _selected_level()
	detail_label.text = "%s · %s · %s" % [selected.subtitle, records.level_summary(selected.level_id), selected.reward.display_name]


func _selected_level() -> LevelConfig:
	for level in levels:
		if level.level_id == selected_level_id:
			return level
	return levels[0]
