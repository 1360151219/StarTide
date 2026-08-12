extends Panel

signal training_changed(message: String)

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const SunlitLockBadge = preload("res://scripts/ui/sunlit_lock_badge.gd")

var records: RefCounted
var hero_id := ""
var points_label: Label
var invested_label: Label
var status_label: Label
var skill_cards: Array[Panel] = []
var skill_icons: Array[TextureRect] = []
var skill_locks: Array[Control] = []
var skill_names: Array[Label] = []
var skill_levels: Array[Label] = []
var skill_effects: Array[Label] = []
var skill_buttons: Array[Button] = []
var reset_button: Button
var reset_armed := false


func _ready() -> void:
	size = Vector2(504, 574)
	CharacterStyle.apply_panel(self, false, 22.0)
	_build_header()
	for index in range(3):
		_build_skill_card(index)
	status_label = CharacterStyle.add_label(self, "远征发现后可培养", 14, CharacterStyle.MUTED, Vector2(18, 446), Vector2(306, 50))
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reset_button = Button.new()
	reset_button.position = Vector2(336, 452)
	reset_button.size = Vector2(150, 54)
	reset_button.add_theme_font_size_override("font_size", 14)
	reset_button.pressed.connect(_reset)
	add_child(reset_button)
	CharacterStyle.apply_segment(reset_button, false)


func configure(run_records: RefCounted) -> void:
	records = run_records


func show_for(selected_hero_id: String, snapshot: Dictionary) -> void:
	hero_id = selected_hero_id
	reset_armed = false
	_refresh(snapshot)


func _build_header() -> void:
	var header := Panel.new()
	header.position = Vector2(14, 14)
	header.size = Vector2(476, 72)
	CharacterStyle.apply_continuous_panel(header, UiFactory.SURFACE_ALT, Color(UiFactory.PRIMARY, 0.62), 8.0)
	add_child(header)
	var heading := CharacterStyle.add_label(header, "技能培养", 20, UiFactory.INK, Vector2(16, 10), Vector2(180, 28))
	UiFactory.apply_key_heading(heading, 20)
	points_label = CharacterStyle.add_label(header, "", 22, UiFactory.ACCENT_DARK, Vector2(330, 8), Vector2(128, 32), HORIZONTAL_ALIGNMENT_RIGHT)
	points_label.tooltip_text = "可用技能点"
	invested_label = CharacterStyle.add_label(header, "", 14, UiFactory.MUTED_INK, Vector2(16, 40), Vector2(442, 22), HORIZONTAL_ALIGNMENT_RIGHT)


func _build_skill_card(index: int) -> void:
	var card := Panel.new()
	card.position = Vector2(14, 98 + index * 112)
	card.size = Vector2(476, 100)
	CharacterStyle.apply_training_row(card)
	add_child(card)
	skill_cards.append(card)
	var icon := TextureRect.new()
	icon.position = Vector2(18, 20)
	icon.size = Vector2(60, 60)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(icon)
	skill_icons.append(icon)
	var lock_badge := SunlitLockBadge.new()
	lock_badge.position = Vector2(14, 14)
	lock_badge.size = Vector2(72, 72)
	card.add_child(lock_badge)
	skill_locks.append(lock_badge)
	skill_names.append(CharacterStyle.add_label(card, "", 18, CharacterStyle.INK, Vector2(92, 10), Vector2(218, 28)))
	skill_levels.append(CharacterStyle.add_label(card, "", 14, UiFactory.PRIMARY_DARK, Vector2(310, 10), Vector2(146, 28), HORIZONTAL_ALIGNMENT_RIGHT))
	var effect := CharacterStyle.add_label(card, "", 14, CharacterStyle.MUTED, Vector2(92, 38), Vector2(238, 52))
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_effects.append(effect)
	var action := Button.new()
	action.position = Vector2(340, 42)
	action.size = Vector2(120, 48)
	action.add_theme_font_size_override("font_size", 14)
	action.pressed.connect(_train.bind(action))
	card.add_child(action)
	skill_buttons.append(action)


func _refresh(snapshot: Dictionary) -> void:
	var progression: Dictionary = snapshot.get("progression", snapshot)
	var available := int(progression.get("available_skill_points", 0))
	var invested := int(progression.get("spent_skill_points", 0))
	points_label.text = "技能点 %d" % available
	points_label.accessibility_name = "可用技能点 %d" % available
	invested_label.text = "LV.%d  ·  已用 %d" % [int(progression.get("level", 1)), invested]
	var skills: Array = progression.get("skills", [])
	for index in range(skill_buttons.size()):
		_refresh_skill(index, skills[index] if index < skills.size() else {})
	reset_button.disabled = invested <= 0
	reset_button.text = "再次确认" if reset_armed else "重置培养"
	reset_button.tooltip_text = "免费返还全部技能点"


func _refresh_skill(index: int, skill: Dictionary) -> void:
	var button := skill_buttons[index]
	if skill.is_empty():
		_set_discovered_state(index, false)
		skill_cards[index].tooltip_text = "技能资料暂不可用"
		button.disabled = true
		return
	var skill_id := str(skill.get("id", ""))
	var discovered: bool = not is_instance_valid(records) or not records.has_method("is_content_discovered") or records.is_content_discovered("skills", skill_id)
	var level := int(skill.get("training_level", 0))
	var maximum := int(skill.get("max_training_level", 3))
	button.set_meta("skill_id", skill_id)
	_set_discovered_state(index, discovered)
	if not discovered:
		skill_cards[index].tooltip_text = "远征中获得后开放培养"
		skill_cards[index].accessibility_name = "未发现技艺，远征中获得后开放培养"
		button.disabled = true
		return
	skill_icons[index].texture = SkillCatalog.skill(skill_id).get("icon") if SkillCatalog.has(skill_id) else null
	skill_names[index].text = str(skill.get("name", skill_id))
	skill_levels[index].text = _level_pips(level, maximum)
	skill_effects[index].text = "待培养" if level <= 0 else str(skill.get("effect_text", ""))
	var at_maximum := level >= maximum
	var next_cost := int(skill.get("next_cost", 1))
	button.text = "满级" if at_maximum else "培养 · %d 点" % next_cost
	button.tooltip_text = "消耗 %d 技能点进行培养" % next_cost
	button.disabled = not bool(skill.get("can_train", false))
	CharacterStyle.apply_segment(button, not button.disabled)


func _set_discovered_state(index: int, discovered: bool) -> void:
	skill_icons[index].visible = discovered
	skill_locks[index].visible = not discovered
	skill_names[index].visible = true
	skill_names[index].position.y = 10 if discovered else 35
	skill_levels[index].visible = discovered
	skill_effects[index].visible = discovered
	skill_buttons[index].visible = discovered
	if not discovered:
		skill_names[index].text = "未发现"
		skill_effects[index].text = ""
	skill_cards[index].modulate = Color.WHITE if discovered else Color(0.82, 0.87, 0.84)


func _train(button: Button) -> void:
	if not is_instance_valid(records) or not records.has_method("train_skill"):
		return
	reset_armed = false
	var result: Dictionary = records.train_skill(hero_id, str(button.get_meta("skill_id", "")))
	status_label.text = "培养成功，养成评分已更新" if bool(result.get("success", false)) else str(result.get("reason", "技能点不足或已满级"))
	training_changed.emit(status_label.text)


func _reset() -> void:
	if not reset_armed:
		reset_armed = true
		status_label.text = "再次点击将返还全部技能点"
		reset_button.text = "再次确认"
		return
	if not is_instance_valid(records) or not records.has_method("reset_skill_training"):
		return
	var result: Dictionary = records.reset_skill_training(hero_id)
	reset_armed = false
	status_label.text = "技能点已全部返还" if bool(result.get("success", false)) else str(result.get("reason", "当前无需重置"))
	training_changed.emit(status_label.text)


func _level_pips(level: int, maximum: int) -> String:
	if level <= 0:
		return "未培养"
	if level >= maximum:
		return "MAX"
	return "II" if level == 2 else "I"
