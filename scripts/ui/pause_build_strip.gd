extends HBoxContainer

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const ChoiceFactory = preload("res://scripts/systems/upgrade_choice_factory.gd")
const MAX_ICONS := 7


func _ready() -> void:
	add_theme_constant_override("separation", 5)


func present(build_state: RefCounted) -> void:
	present_snapshot(build_state.snapshot() if build_state != null else {})


func present_snapshot(snapshot: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var entries := _entries(snapshot)
	if entries.is_empty():
		add_child(_empty_slot())
		return
	for index in range(mini(entries.size(), MAX_ICONS)):
		add_child(_build_icon(entries[index]))


func _entries(snapshot: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if snapshot.is_empty():
		return result
	var skill_levels: Dictionary = snapshot.get("skill_levels", {})
	var skill_branches: Dictionary = snapshot.get("skill_branches", {})
	for raw_skill_id in snapshot.get("skill_slots", []):
		var skill_id := str(raw_skill_id)
		if skill_id.is_empty() or not SkillCatalog.has(skill_id):
			continue
		var skill := SkillCatalog.skill(skill_id)
		result.append({
			"texture": skill["icon"],
			"level_text": ChoiceFactory.roman(int(skill_levels.get(skill_id, 1))),
			"accent": Color("49bfc0"),
			"name": _skill_name(skill_id, skill_branches),
		})
	var relic_levels: Dictionary = snapshot.get("relic_levels", {})
	for relic_id in RelicCatalog.ids():
		if not relic_levels.has(relic_id):
			continue
		result.append({
			"texture": RelicCatalog.icon(relic_id),
			"level_text": ChoiceFactory.level_mark(
				int(relic_levels[relic_id]),
				int(RelicCatalog.relic(relic_id)["max_level"]),
				true
			),
			"accent": Color("efb23f"),
			"name": RelicCatalog.relic(relic_id)["name"],
		})
	return result


func _skill_name(skill_id: String, skill_branches: Dictionary) -> String:
	var name := str(SkillCatalog.skill(skill_id)["name"])
	if not skill_branches.has(skill_id):
		return name
	var branch := SkillCatalog.branch(skill_id, str(skill_branches[skill_id]))
	return "%s · %s" % [name, str(branch.get("name", ""))]


func _build_icon(entry: Dictionary) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(50, 58)
	slot.tooltip_text = "%s · %s" % [entry["name"], entry["level_text"]]
	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = Color.TRANSPARENT
	slot_style.border_color = Color(entry["accent"], 0.72)
	slot_style.border_width_bottom = 3
	slot_style.corner_radius_bottom_left = 4
	slot_style.corner_radius_bottom_right = 4
	slot.add_theme_stylebox_override("panel", slot_style)
	var icon := TextureRect.new()
	icon.position = Vector2(5, 5)
	icon.size = Vector2(40, 44)
	icon.texture = entry["texture"]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(icon)
	var level := UiFactory.surface_label(str(entry["level_text"]), 11, UiFactory.HUD_TEXT)
	level.position = Vector2(27, 35)
	level.size = Vector2(20, 20)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level.add_theme_stylebox_override("normal", UiFactory.flat_bar_style(Color("176c73"), 9.0))
	slot.add_child(level)
	return slot
func _empty_slot() -> Panel:
	var empty := Panel.new()
	empty.custom_minimum_size = Vector2(396, 58)
	empty.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var label := UiFactory.surface_label("等待获得第一份远征强化", 15, UiFactory.MUTED_INK)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty.add_child(label)
	return empty
