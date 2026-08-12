extends RefCounted

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const UltimateOfferPity = preload("res://scripts/run/ultimate_offer_pity.gd")
const SKILL_SLOT_LIMIT := 3
const RELIC_SLOT_LIMIT := 4
const INITIAL_REROLLS := 1

var hero_id := ""
var skill_slots: Array = ["", "", ""]
var skill_levels: Dictionary = {}
var skill_branches: Dictionary = {}
var relic_levels: Dictionary = {}
var run_modifiers: Dictionary = {}
var rerolls_remaining := INITIAL_REROLLS
var pending_choices: Dictionary = {}
var last_offer_key := ""
var ultimate_pity := UltimateOfferPity.new()
var pinned_choice_keys := PackedStringArray()


func _init(selected_hero_id := "", signature_skill_id := "") -> void:
	reset(selected_hero_id, signature_skill_id)


func reset(selected_hero_id: String, signature_skill_id := "") -> void:
	hero_id = selected_hero_id
	skill_slots = ["", "", ""]
	skill_levels.clear()
	skill_branches.clear()
	relic_levels.clear()
	rerolls_remaining = INITIAL_REROLLS
	pending_choices.clear()
	last_offer_key = ""
	ultimate_pity.reset()
	pinned_choice_keys.clear()
	_rebuild_modifiers()
	var signature := signature_skill_id
	if signature.is_empty():
		signature = SkillCatalog.signature_for_hero(hero_id)
	if _skill_belongs_to_hero(signature):
		skill_slots[0] = signature
		skill_levels[signature] = 1


func active_skill_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for skill_id in skill_slots:
		if not str(skill_id).is_empty():
			result.append(str(skill_id))
	return result


func has_skill(skill_id: String) -> bool:
	return skill_levels.has(skill_id)


func has_free_skill_slot() -> bool:
	return skill_slots.has("")


func can_add_skill(skill_id: String) -> bool:
	return _skill_belongs_to_hero(skill_id) and not has_skill(skill_id) and has_free_skill_slot()


func add_skill(skill_id: String) -> bool:
	if not can_add_skill(skill_id):
		return false
	var slot_index := skill_slots.find("")
	skill_slots[slot_index] = skill_id
	skill_levels[skill_id] = 1
	return true


func can_upgrade_skill(skill_id: String) -> bool:
	if not has_skill(skill_id) or not SkillCatalog.has(skill_id):
		return false
	var level := int(skill_levels[skill_id])
	var data := SkillCatalog.skill(skill_id)
	if level >= int(data["max_level"]):
		return false
	return level + 1 != int(data["branch_level"]) or skill_branches.has(skill_id)


func upgrade_skill(skill_id: String) -> bool:
	if not can_upgrade_skill(skill_id):
		return false
	var max_level := int(SkillCatalog.skill(skill_id)["max_level"])
	var next_level := int(skill_levels[skill_id]) + 1
	skill_levels[skill_id] = next_level
	ultimate_pity.track_upgrade(skill_id, next_level, max_level)
	return true


func can_select_branch(skill_id: String, branch_id: String) -> bool:
	if not has_skill(skill_id) or skill_branches.has(skill_id):
		return false
	var data := SkillCatalog.skill(skill_id)
	if data.is_empty() or int(skill_levels[skill_id]) + 1 != int(data["branch_level"]):
		return false
	return data["branches"].has(branch_id)


func select_branch(skill_id: String, branch_id: String) -> bool:
	if not can_select_branch(skill_id, branch_id):
		return false
	skill_branches[skill_id] = branch_id
	skill_levels[skill_id] = int(skill_levels[skill_id]) + 1
	return true


func branch_overrides(skill_id: String) -> Dictionary:
	if not skill_branches.has(skill_id) or not skill_levels.has(skill_id):
		return {}
	var branch := SkillCatalog.branch(skill_id, str(skill_branches[skill_id]))
	if branch.is_empty():
		return {}
	var overrides: Dictionary = branch["level_overrides"]
	var current_level := int(skill_levels[skill_id])
	for level in range(current_level, 0, -1):
		if overrides.has(level):
			return overrides[level].duplicate(true)
	return {}


func unique_relic_count() -> int:
	return relic_levels.size()


func can_add_or_upgrade_relic(relic_id: String) -> bool:
	if not RelicCatalog.has(relic_id):
		return false
	var current_level := int(relic_levels.get(relic_id, 0))
	if current_level >= int(RelicCatalog.relic(relic_id)["max_level"]):
		return false
	return current_level > 0 or unique_relic_count() < RELIC_SLOT_LIMIT


func add_or_upgrade_relic(relic_id: String) -> bool:
	if not can_add_or_upgrade_relic(relic_id):
		return false
	relic_levels[relic_id] = int(relic_levels.get(relic_id, 0)) + 1
	_rebuild_modifiers()
	return true


func modifier(modifier_id: String) -> float:
	return float(run_modifiers.get(modifier_id, _modifier_default(modifier_id)))


func ultimate_pity_due_skill_ids() -> PackedStringArray:
	return ultimate_pity.due_skill_ids(skill_levels)


func record_upgrade_offer(choices: Array) -> void:
	ultimate_pity.record_offer(choices, skill_levels)


func remember_offer(choices: Array, required_choice_keys := PackedStringArray()) -> void:
	pending_choices.clear()
	pinned_choice_keys = PackedStringArray(required_choice_keys)
	var keys := PackedStringArray()
	for raw_choice in choices:
		var choice: Dictionary = raw_choice
		var choice_key := str(choice.get("choice_key", ""))
		if choice_key.is_empty():
			continue
		pending_choices[choice_key] = choice.duplicate(true)
		keys.append(choice_key)
	keys.sort()
	last_offer_key = "|".join(keys)


func pending_choice(choice_key: String) -> Dictionary:
	return pending_choices.get(choice_key, {})


func clear_offer() -> void:
	pending_choices.clear()
	pinned_choice_keys.clear()


func consume_reroll() -> bool:
	if rerolls_remaining <= 0:
		return false
	rerolls_remaining -= 1
	return true


func snapshot() -> Dictionary:
	return {
		"hero_id": hero_id,
		"skill_slots": skill_slots.duplicate(),
		"skill_levels": skill_levels.duplicate(true),
		"skill_branches": skill_branches.duplicate(true),
		"relic_levels": relic_levels.duplicate(true),
		"run_modifiers": run_modifiers.duplicate(true),
		"rerolls_remaining": rerolls_remaining,
	}


func _skill_belongs_to_hero(skill_id: String) -> bool:
	if not SkillCatalog.has(skill_id):
		return false
	return str(SkillCatalog.skill(skill_id)["owner_hero_id"]) == hero_id


func _rebuild_modifiers() -> void:
	run_modifiers = {
		"max_health_flat": 0.0,
		"move_speed_multiplier": 1.0,
		"damage_multiplier": 1.0,
		"cooldown_multiplier": 1.0,
		"hit_interval_multiplier": 1.0,
		"range_multiplier": 1.0,
		"pickup_radius_multiplier": 1.0,
	}
	for relic_id in relic_levels:
		if not RelicCatalog.has(relic_id):
			continue
		var level := int(relic_levels[relic_id])
		var per_level: Dictionary = RelicCatalog.relic(relic_id)["modifiers_per_level"]
		for modifier_id in per_level:
			run_modifiers[modifier_id] = float(run_modifiers.get(modifier_id, _modifier_default(modifier_id))) + float(per_level[modifier_id]) * level


func _modifier_default(modifier_id: String) -> float:
	return 0.0 if modifier_id.ends_with("_flat") else 1.0
