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
				choices.append(_with_weight(ChoiceFactory.skill_unlock(skill_id), _content_weight(skill_pool_ids, skill_id)))
			continue
		var current_level := int(build_state.skill_levels[skill_id])
		if current_level >= int(skill["max_level"]):
			continue
		var target_level := current_level + 1
		if target_level == int(skill["branch_level"]) and not build_state.skill_branches.has(skill_id):
			for branch_id in SkillCatalog.branch_ids(skill_id):
				choices.append(_with_weight(ChoiceFactory.skill_branch(skill_id, branch_id, target_level), _content_weight(skill_pool_ids, skill_id)))
		elif build_state.can_upgrade_skill(skill_id):
			choices.append(_with_weight(ChoiceFactory.skill_upgrade(skill_id, target_level), _content_weight(skill_pool_ids, skill_id)))
	for relic_id in _unique_sorted_ids(relic_pool_ids):
		if RelicCatalog.has(relic_id) and build_state.can_add_or_upgrade_relic(relic_id):
			choices.append(_with_weight(ChoiceFactory.relic_upgrade(relic_id, int(build_state.relic_levels.get(relic_id, 0)) + 1), _content_weight(relic_pool_ids, relic_id)))
	if health_ratio < 0.7:
		choices.append(ChoiceFactory.recovery())
	return choices


func pick_group(build_state: RefCounted, skill_pool_ids, relic_pool_ids, health_ratio: float, excluded_group_key: String, required_choice_keys := PackedStringArray()) -> Array:
	var available: Array = []
	var groups := _choice_groups(build_state, skill_pool_ids, relic_pool_ids, health_ratio)
	if not required_choice_keys.is_empty():
		groups = _required_choice_groups(legal_candidates(build_state, skill_pool_ids, relic_pool_ids, health_ratio), required_choice_keys)
	for group in groups:
		if group_key(group) != excluded_group_key:
			available.append(group)
	if available.is_empty():
		return []
	var result: Array = available[_weighted_group_index(available)].duplicate(true)
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


func _required_choice_groups(candidates: Array, required_choice_keys) -> Array:
	var candidates_by_key: Dictionary = {}
	var branch_pairs: Dictionary = {}
	var regular_fillers: Array = []
	for choice in candidates:
		candidates_by_key[str(choice["choice_key"])] = choice
		if str(choice["kind"]) == ChoiceFactory.SKILL_BRANCH:
			var skill_id := str(choice["content_id"])
			if not branch_pairs.has(skill_id):
				branch_pairs[skill_id] = []
			branch_pairs[skill_id].append(choice)
		elif not required_choice_keys.has(str(choice["choice_key"])):
			regular_fillers.append(choice)
	var required: Array = []
	for raw_key in required_choice_keys:
		var choice_key := str(raw_key)
		if not candidates_by_key.has(choice_key):
			return []
		required.append(candidates_by_key[choice_key])
	if required.is_empty() or required.size() > 3:
		return []
	var groups: Array = []
	var seen: Dictionary = {}
	var remaining := 3 - required.size()
	if remaining == 0:
		_append_group(groups, seen, required)
	elif remaining == 1:
		if regular_fillers.is_empty():
			regular_fillers.append(ChoiceFactory.recovery())
		for filler in regular_fillers:
			_append_group(groups, seen, required + [filler])
	else:
		for skill_id in branch_pairs:
			var pair: Array = branch_pairs[skill_id]
			if pair.size() == 2:
				_append_group(groups, seen, required + pair)
		if regular_fillers.size() < 2 and not _has_choice_key(regular_fillers, "utility:recovery"):
			regular_fillers.append(ChoiceFactory.recovery())
		for first in range(regular_fillers.size()):
			for second in range(first + 1, regular_fillers.size()):
				_append_group(groups, seen, required + [regular_fillers[first], regular_fillers[second]])
	if groups.is_empty():
		if regular_fillers.is_empty():
			regular_fillers.append(ChoiceFactory.recovery())
		_append_group(groups, seen, required + regular_fillers.slice(0, remaining))
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


func _has_choice_key(choices: Array, choice_key: String) -> bool:
	for choice in choices:
		if str(choice.get("choice_key", "")) == choice_key:
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


func _content_weight(raw_pool, content_id: String) -> float:
	return maxf(0.001, float(raw_pool.get(content_id, 1.0))) if raw_pool is Dictionary else 1.0


func _with_weight(choice: Dictionary, weight: float) -> Dictionary:
	choice["offer_weight"] = weight
	return choice


func _weighted_group_index(groups: Array) -> int:
	var weights := PackedFloat32Array()
	var total := 0.0
	for group in groups:
		var seen_content: Dictionary = {}
		var weight := 0.0
		for choice in group:
			var content_id := str(choice["content_id"])
			if not seen_content.has(content_id):
				weight += float(choice.get("offer_weight", 1.0))
				seen_content[content_id] = true
		weight = maxf(weight, 0.001)
		weights.append(weight)
		total += weight
	var roll := rng.randf() * total
	var cursor := 0.0
	for index in range(groups.size()):
		cursor += weights[index]
		if roll < cursor:
			return index
	return groups.size() - 1


func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
