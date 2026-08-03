extends RefCounted

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const ChoiceFactory = preload("res://scripts/systems/upgrade_choice_factory.gd")

var rng: RandomNumberGenerator


func _init(random: RandomNumberGenerator) -> void:
	rng = random


func legal_candidates(build_state: RefCounted, skill_pool_ids, relic_pool_ids, health_ratio := 1.0) -> Array:
	var choices: Array = []
	for skill_id in _unique_sorted_ids(skill_pool_ids):
		if not SkillCatalog.has(skill_id):
			continue
		var skill := SkillCatalog.skill(skill_id)
		if str(skill["owner_hero_id"]) != str(build_state.hero_id):
			continue
		if not build_state.has_skill(skill_id):
			if build_state.can_add_skill(skill_id):
				choices.append(ChoiceFactory.skill_unlock(skill_id))
			continue
		var current_level := int(build_state.skill_levels[skill_id])
		if current_level >= int(skill["max_level"]):
			continue
		var target_level := current_level + 1
		if target_level == int(skill["branch_level"]) and not build_state.skill_branches.has(skill_id):
			for branch_id in SkillCatalog.branch_ids(skill_id):
				choices.append(ChoiceFactory.skill_branch(skill_id, branch_id, target_level))
		elif build_state.can_upgrade_skill(skill_id):
			choices.append(ChoiceFactory.skill_upgrade(skill_id, target_level))
	for relic_id in _unique_sorted_ids(relic_pool_ids):
		if RelicCatalog.has(relic_id) and build_state.can_add_or_upgrade_relic(relic_id):
			choices.append(ChoiceFactory.relic_upgrade(relic_id, int(build_state.relic_levels.get(relic_id, 0)) + 1))
	if health_ratio < 0.7:
		choices.append(ChoiceFactory.recovery())
	return choices


func pick_group(build_state: RefCounted, skill_pool_ids, relic_pool_ids, health_ratio: float, excluded_group_key: String) -> Array:
	var available: Array = []
	for group in _choice_groups(build_state, skill_pool_ids, relic_pool_ids, health_ratio):
		if group_key(group) != excluded_group_key:
			available.append(group)
	if available.is_empty():
		return []
	var result: Array = available[rng.randi_range(0, available.size() - 1)].duplicate(true)
	_shuffle(result)
	return result


func group_key(group: Array) -> String:
	var keys := PackedStringArray()
	for choice in group:
		keys.append(str(choice["choice_key"]))
	keys.sort()
	return "|".join(keys)


func _choice_groups(build_state: RefCounted, skill_pool_ids, relic_pool_ids, health_ratio: float) -> Array:
	var candidates := legal_candidates(build_state, skill_pool_ids, relic_pool_ids, health_ratio)
	var branch_pairs: Dictionary = {}
	var regular_skills: Array = []
	var relics: Array = []
	var utilities: Array = []
	for choice in candidates:
		var kind := str(choice["kind"])
		if kind == ChoiceFactory.SKILL_BRANCH:
			var skill_id := str(choice["content_id"])
			if not branch_pairs.has(skill_id):
				branch_pairs[skill_id] = []
			branch_pairs[skill_id].append(choice)
		elif kind == ChoiceFactory.SKILL_UNLOCK or kind == ChoiceFactory.SKILL_UPGRADE:
			regular_skills.append(choice)
		elif kind == ChoiceFactory.RELIC_UPGRADE:
			relics.append(choice)
		else:
			utilities.append(choice)
	var groups: Array = []
	var seen: Dictionary = {}
	for skill_id in branch_pairs:
		var pair: Array = branch_pairs[skill_id]
		if pair.size() != 2:
			continue
		var third_choices := relics + regular_skills + utilities
		if third_choices.is_empty():
			third_choices.append(ChoiceFactory.recovery())
		for third_choice in third_choices:
			_append_group(groups, seen, [pair[0], pair[1], third_choice])
	var regular_candidates := regular_skills + relics + utilities
	if regular_candidates.size() < 3 and not _has_kind(regular_candidates, [ChoiceFactory.UTILITY_RECOVERY]):
		regular_candidates.append(ChoiceFactory.recovery())
	var regular_groups: Array = []
	var regular_seen: Dictionary = {}
	for first in range(regular_candidates.size()):
		for second in range(first + 1, regular_candidates.size()):
			for third in range(second + 1, regular_candidates.size()):
				var group := [regular_candidates[first], regular_candidates[second], regular_candidates[third]]
				if _has_kind(group, [ChoiceFactory.SKILL_UNLOCK, ChoiceFactory.SKILL_UPGRADE]) and _has_kind(group, [ChoiceFactory.RELIC_UPGRADE]):
					_append_group(regular_groups, regular_seen, group)
	if regular_groups.is_empty() and regular_candidates.size() >= 3:
		for first in range(regular_candidates.size()):
			for second in range(first + 1, regular_candidates.size()):
				for third in range(second + 1, regular_candidates.size()):
					_append_group(regular_groups, regular_seen, [regular_candidates[first], regular_candidates[second], regular_candidates[third]])
	if regular_groups.is_empty() and groups.is_empty() and not regular_candidates.is_empty():
		_append_group(regular_groups, regular_seen, regular_candidates)
	for group in regular_groups:
		_append_group(groups, seen, group)
	return groups


func _append_group(groups: Array, seen: Dictionary, group: Array) -> void:
	var key := group_key(group)
	if seen.has(key):
		return
	seen[key] = true
	groups.append(group)


func _has_kind(group: Array, kinds: Array) -> bool:
	for choice in group:
		if kinds.has(str(choice["kind"])):
			return true
	return false


func _unique_sorted_ids(raw_ids) -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for raw_id in raw_ids:
		var content_id := str(raw_id)
		if content_id.is_empty() or seen.has(content_id):
			continue
		seen[content_id] = true
		result.append(content_id)
	result.sort()
	return result


func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
