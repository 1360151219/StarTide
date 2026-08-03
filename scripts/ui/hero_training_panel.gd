extends Panel

signal closed
signal progression_changed

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var records: RefCounted
var hero_id := ""
var title_label: Label
var progress_label: Label
var status_label: Label
var skill_buttons: Array[Button] = []
var reset_button: Button
var reset_armed := false


func _ready() -> void:
	size = Vector2(504, 680)
	add_theme_stylebox_override("panel", UiFactory.panel_style(Color(0.012, 0.07, 0.11, 0.985), 24.0, UiFactory.GOLD))
	_build_header()
	for index in range(3):
		skill_buttons.append(_build_skill_button(index))
	_build_actions()
	visible = false


func configure(run_records: RefCounted) -> void:
	records = run_records


func show_for(selected_hero_id: String) -> void:
	hero_id = selected_hero_id
	reset_armed = false
	visible = true
	refresh()


func refresh() -> void:
	var hero := HeroCatalog.hero(hero_id)
	title_label.text = "%s · 技能培养" % hero["name"]
	if not records.has_method("progression_snapshot"):
		progress_label.text = "成长档案正在初始化"
		status_label.text = "完成一局后即可获得英雄经验与技能点"
		for button in skill_buttons:
			button.disabled = true
		return
	var snapshot: Dictionary = records.progression_snapshot(hero_id)
	progress_label.text = "Lv.%d  ·  熟练 %d/%d  ·  可用技能点 %d" % [
		int(snapshot.get("level", 1)), int(snapshot.get("level_progress", 0)),
		int(snapshot.get("level_progress_max", 100)), int(snapshot.get("available_skill_points", 0)),
	]
	var skills: Array = snapshot.get("skills", [])
	for index in range(skill_buttons.size()):
		_refresh_skill_button(skill_buttons[index], skills[index] if index < skills.size() else {})
	reset_button.disabled = int(snapshot.get("spent_skill_points", 0)) <= 0
	reset_button.text = "再点一次确认重置" if reset_armed else "免费重置技能点"


func _build_header() -> void:
	title_label = UiFactory.label("技能培养", 28, UiFactory.PALE)
	title_label.position = Vector2(24, 20)
	title_label.size = Vector2(456, 38)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)
	progress_label = UiFactory.label("", 16, UiFactory.CYAN)
	progress_label.position = Vector2(20, 62)
	progress_label.size = Vector2(464, 28)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(progress_label)
	var hint := UiFactory.label("通关提升英雄等级；培养只强化技能，不会提前解锁终极技能", 13, UiFactory.PALE_MUTED)
	hint.position = Vector2(18, 94)
	hint.size = Vector2(468, 44)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)


func _build_skill_button(index: int) -> Button:
	var button := Button.new()
	button.position = Vector2(24, 146 + index * 126)
	button.size = Vector2(456, 112)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = true
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_constant_override("icon_max_width", 72)
	button.add_theme_constant_override("h_separation", 14)
	UiFactory.apply_glass_button(button, false, UiFactory.STROKE)
	button.pressed.connect(_train_skill.bind(button))
	add_child(button)
	return button


func _build_actions() -> void:
	status_label = UiFactory.label("点击技能卡消耗技能点进行培养", 13, UiFactory.PALE_MUTED)
	status_label.position = Vector2(24, 526)
	status_label.size = Vector2(456, 24)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)
	reset_button = Button.new()
	reset_button.position = Vector2(24, 562)
	reset_button.size = Vector2(216, 52)
	reset_button.text = "免费重置技能点"
	reset_button.add_theme_font_size_override("font_size", 16)
	UiFactory.apply_glass_button(reset_button, false, UiFactory.GOLD)
	reset_button.pressed.connect(_reset_training)
	add_child(reset_button)
	var close_button := Button.new()
	close_button.position = Vector2(264, 562)
	close_button.size = Vector2(216, 52)
	close_button.text = "完成"
	close_button.add_theme_font_size_override("font_size", 17)
	UiFactory.apply_glass_button(close_button, true, UiFactory.GOLD)
	close_button.pressed.connect(_close)
	add_child(close_button)


func _refresh_skill_button(button: Button, skill: Dictionary) -> void:
	if skill.is_empty():
		button.disabled = true
		button.text = "技能资料不可用"
		return
	var skill_id: String = skill.get("id", "")
	button.set_meta("skill_id", skill_id)
	button.icon = SkillCatalog.skill(skill_id).get("icon") if SkillCatalog.has(skill_id) else null
	if records.has_method("is_content_discovered") and not records.is_content_discovered("skills", skill_id):
		button.text = "？？？ · 尚未发现\n在对应远征中获得后开放永久培养"
		button.disabled = true
		button.modulate = Color(0.58, 0.66, 0.68)
		return
	button.modulate = Color.WHITE
	var training_level := int(skill.get("training_level", 0))
	var maximum := int(skill.get("max_training_level", 3))
	var cost_text := "已满级" if training_level >= maximum else "下一级消耗 %d 点" % int(skill.get("next_cost", 1))
	button.text = "%s  ·  培养 %d/%d\n%s\n%s" % [skill.get("name", skill_id), training_level, maximum, skill.get("effect_text", "等待培养"), cost_text]
	button.disabled = not bool(skill.get("can_train", false))


func _train_skill(button: Button) -> void:
	if not records.has_method("train_skill"):
		return
	reset_armed = false
	var result: Dictionary = records.train_skill(hero_id, str(button.get_meta("skill_id", "")))
	status_label.text = "培养成功，技能更强了！" if bool(result.get("success", false)) else str(result.get("reason", "技能点不足或已满级"))
	refresh()
	progression_changed.emit()


func _reset_training() -> void:
	if not reset_armed:
		reset_armed = true
		status_label.text = "再次点击即可返还全部技能点"
		refresh()
		return
	var result: Dictionary = records.reset_skill_training(hero_id)
	reset_armed = false
	status_label.text = "技能点已全部返还" if bool(result.get("success", false)) else str(result.get("reason", "当前无需重置"))
	refresh()
	progression_changed.emit()


func _close() -> void:
	visible = false
	reset_armed = false
	closed.emit()
