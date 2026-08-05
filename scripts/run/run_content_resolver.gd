extends RefCounted

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")


static func resolve(level_id: String, hero_id: String, records: RefCounted, rng: RandomNumberGenerator = null) -> Dictionary:
	var level_pool := LevelCatalog.resolved_content_pool(level_id)
	var skill_entries := _valid_entries(level_pool["skill_entries"], "skills", hero_id)
	var relic_entries := _valid_entries(level_pool["relic_entries"], "relics", hero_id)
	_append_discovered(
		skill_entries, records.discovered_content_ids("skills"), "skills", hero_id,
		int(level_pool["discovered_skill_slots"]), float(level_pool["discovered_content_weight"]), rng
	)
	_append_discovered(
		relic_entries, records.discovered_content_ids("relics"), "relics", hero_id,
		int(level_pool["discovered_relic_slots"]), float(level_pool["discovered_content_weight"]), rng
	)
	_guarantee_signature(skill_entries, hero_id)
	var selected_skills := _select_entries(skill_entries, int(level_pool["skill_pool_limit"]), rng)
	var selected_relics := _select_entries(relic_entries, int(level_pool["relic_pool_limit"]), rng)
	return {
		"skill_ids": _entry_ids(selected_skills),
		"relic_ids": _entry_ids(selected_relics),
		"skill_weights": _weight_map(selected_skills),
		"relic_weights": _weight_map(selected_relics),
	}


static func _valid_entries(raw_entries: Array, category: String, hero_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_entry in raw_entries:
		var entry: Dictionary = raw_entry
		var content_id := str(entry.get("content_id", ""))
		if category == "skills" and not _skill_matches_hero(content_id, hero_id):
			continue
		if category == "relics" and not RelicCatalog.has(content_id):
			continue
		result.append(entry.duplicate(true))
	return result


static func _append_discovered(target: Array[Dictionary], discovered_ids: PackedStringArray, category: String, hero_id: String, slot_count: int, weight: float, rng: RandomNumberGenerator) -> void:
	if slot_count <= 0:
		return
	var known_ids := _entry_ids(target)
	var candidates: Array[Dictionary] = []
	for content_id in discovered_ids:
		if known_ids.has(content_id):
			continue
		if category == "skills" and not _skill_matches_hero(content_id, hero_id):
			continue
		if category == "relics" and not RelicCatalog.has(content_id):
			continue
		candidates.append({"content_id": content_id, "weight": weight, "guaranteed": false})
	for entry in _select_entries(candidates, slot_count, rng):
		target.append(entry)


static func _guarantee_signature(entries: Array[Dictionary], hero_id: String) -> void:
	var signature := SkillCatalog.signature_for_hero(hero_id)
	if signature.is_empty():
		return
	for entry in entries:
		if str(entry["content_id"]) == signature:
			entry["guaranteed"] = true
			return
	entries.append({"content_id": signature, "weight": 1.0, "guaranteed": true})


static func _select_entries(entries: Array[Dictionary], limit: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	if limit <= 0 or entries.is_empty():
		return []
	var result: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []
	for entry in entries:
		if bool(entry.get("guaranteed", false)) and result.size() < limit:
			result.append(entry)
		else:
			remaining.append(entry)
	while result.size() < limit and not remaining.is_empty():
		var index := _weighted_index(remaining, rng)
		result.append(remaining.pop_at(index))
	return result


static func _weighted_index(entries: Array[Dictionary], rng: RandomNumberGenerator) -> int:
	if rng == null:
		var best_index := 0
		for index in range(1, entries.size()):
			var best_weight := float(entries[best_index].get("weight", 1.0))
			var weight := float(entries[index].get("weight", 1.0))
			if weight > best_weight or (is_equal_approx(weight, best_weight) and str(entries[index]["content_id"]) < str(entries[best_index]["content_id"])):
				best_index = index
		return best_index
	var total_weight := 0.0
	for entry in entries:
		total_weight += float(entry.get("weight", 1.0))
	var roll := rng.randf() * total_weight
	var cursor := 0.0
	for index in range(entries.size()):
		cursor += float(entries[index].get("weight", 1.0))
		if roll < cursor:
			return index
	return entries.size() - 1


static func _skill_matches_hero(skill_id: String, hero_id: String) -> bool:
	return SkillCatalog.has(skill_id) and str(SkillCatalog.skill(skill_id)["owner_hero_id"]) == hero_id


static func _entry_ids(entries: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for entry in entries:
		result.append(str(entry["content_id"]))
	return result


static func _weight_map(entries: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for entry in entries:
		result[str(entry["content_id"])] = float(entry.get("weight", 1.0))
	return result
