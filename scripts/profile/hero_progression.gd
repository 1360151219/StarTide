extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const MAX_LEVEL := 10
const XP_PER_LEVEL := 100
const MAX_MASTERY_XP := (MAX_LEVEL - 1) * XP_PER_LEVEL
const MAX_TRAINING_LEVEL := 3
const TRAINING_COSTS := [1, 2, 3]


static func default_progress(hero_id: String) -> Dictionary:
	var training := {}
	for skill_id in _skill_ids(hero_id):
		training[skill_id] = 0
	return {"mastery_xp": 0, "training": training}


static func sanitize(hero_id: String, raw_progress: Dictionary) -> Dictionary:
	var progress := default_progress(hero_id)
	progress["mastery_xp"] = clampi(int(raw_progress.get("mastery_xp", 0)), 0, MAX_MASTERY_XP)
	var raw_training: Dictionary = raw_progress.get("training", {})
	for skill_id in _skill_ids(hero_id):
		progress["training"][skill_id] = clampi(int(raw_training.get(skill_id, 0)), 0, MAX_TRAINING_LEVEL)
	_repair_training_budget(hero_id, progress)
	return progress


static func snapshot(hero_id: String, raw_progress: Dictionary) -> Dictionary:
	var progress := sanitize(hero_id, raw_progress)
	var mastery_xp: int = progress["mastery_xp"]
	var hero_level := level_for_xp(mastery_xp)
	var total_points := hero_level - 1
	var spent_points := spent_skill_points(progress["training"])
	var skill_rows: Array = []
	var modifiers := {}
	for skill_id in _skill_ids(hero_id):
		var training_level: int = progress["training"][skill_id]
		var next_cost := training_cost(training_level + 1)
		skill_rows.append({
			"id": skill_id,
			"name": HeroCatalog.skill(skill_id)["name"],
			"training_level": training_level,
			"max_training_level": MAX_TRAINING_LEVEL,
			"next_cost": next_cost,
			"can_train": training_level < MAX_TRAINING_LEVEL and total_points - spent_points >= next_cost,
			"effect_text": _effect_text(skill_id, training_level),
		})
		modifiers[skill_id] = _skill_modifiers(skill_id, training_level, hero_level)
	return {
		"hero_id": hero_id,
		"mastery_xp": mastery_xp,
		"level": hero_level,
		"max_level": MAX_LEVEL,
		"level_progress": XP_PER_LEVEL if hero_level >= MAX_LEVEL else mastery_xp % XP_PER_LEVEL,
		"level_progress_max": XP_PER_LEVEL,
		"total_skill_points": total_points,
		"spent_skill_points": spent_points,
		"available_skill_points": total_points - spent_points,
		"training": progress["training"].duplicate(true),
		"skills": skill_rows,
		"damage_multiplier": 1.0 + (hero_level - 1) * 0.015,
		"health_multiplier": 1.0 + (hero_level - 1) * 0.01,
		"skill_modifiers": modifiers,
	}


static func award_run(hero_id: String, raw_progress: Dictionary, won: bool, survival_seconds: float) -> Dictionary:
	var before := snapshot(hero_id, raw_progress)
	var requested_xp := 100 if won else mini(30, floori(maxf(0.0, survival_seconds) / 30.0) * 10)
	var progress := sanitize(hero_id, raw_progress)
	progress["mastery_xp"] = mini(MAX_MASTERY_XP, int(progress["mastery_xp"]) + requested_xp)
	var after := snapshot(hero_id, progress)
	return {
		"progress": progress,
		"reward": {
			"mastery_xp_gained": int(after["mastery_xp"]) - int(before["mastery_xp"]),
			"previous_mastery_xp": before["mastery_xp"],
			"mastery_xp": after["mastery_xp"],
			"previous_level": before["level"],
			"level": after["level"],
			"levels_gained": int(after["level"]) - int(before["level"]),
			"skill_points_gained": int(after["total_skill_points"]) - int(before["total_skill_points"]),
			"available_skill_points": after["available_skill_points"],
			"reached_max_level": after["level"] >= MAX_LEVEL,
		},
	}


static func train(hero_id: String, raw_progress: Dictionary, skill_id: String) -> Dictionary:
	var progress := sanitize(hero_id, raw_progress)
	if not progress["training"].has(skill_id):
		return {"success": false, "reason": "该技能不属于当前英雄", "progress": progress}
	var current_level: int = progress["training"][skill_id]
	if current_level >= MAX_TRAINING_LEVEL:
		return {"success": false, "reason": "技能训练已满级", "progress": progress}
	var available_points: int = snapshot(hero_id, progress)["available_skill_points"]
	var cost := training_cost(current_level + 1)
	if available_points < cost:
		return {"success": false, "reason": "技能点不足", "progress": progress}
	progress["training"][skill_id] = current_level + 1
	return {"success": true, "reason": "技能训练已提升", "progress": progress}


static func reset_training(hero_id: String, raw_progress: Dictionary) -> Dictionary:
	var progress := sanitize(hero_id, raw_progress)
	if spent_skill_points(progress["training"]) <= 0:
		return {"success": false, "reason": "尚未分配技能点", "progress": progress}
	for skill_id in progress["training"]:
		progress["training"][skill_id] = 0
	return {"success": true, "reason": "技能训练已免费重置", "progress": progress}


static func level_for_xp(mastery_xp: int) -> int:
	return mini(MAX_LEVEL, 1 + maxi(0, mastery_xp) / XP_PER_LEVEL)


static func training_cost(target_level: int) -> int:
	if target_level < 1 or target_level > MAX_TRAINING_LEVEL:
		return 0
	return TRAINING_COSTS[target_level - 1]


static func spent_skill_points(training: Dictionary) -> int:
	var spent := 0
	for raw_level in training.values():
		for target_level in range(1, clampi(int(raw_level), 0, MAX_TRAINING_LEVEL) + 1):
			spent += training_cost(target_level)
	return spent


static func _repair_training_budget(hero_id: String, progress: Dictionary) -> void:
	var available_budget := level_for_xp(progress["mastery_xp"]) - 1
	var skill_ids := _skill_ids(hero_id)
	while spent_skill_points(progress["training"]) > available_budget:
		for index in range(skill_ids.size() - 1, -1, -1):
			var skill_id: String = skill_ids[index]
			if int(progress["training"][skill_id]) > 0:
				progress["training"][skill_id] -= 1
				break


static func _skill_modifiers(skill_id: String, training_level: int, hero_level: int) -> Dictionary:
	return {
		"damage_multiplier": (1.0 + (hero_level - 1) * 0.015) * (1.04 if training_level >= 1 else 1.0),
		"healing_multiplier": 1.04 if training_level >= 1 else 1.0,
		"range_multiplier": 1.08 if training_level >= 2 and skill_id != "star_lance" else 1.0,
		"projectile_speed_multiplier": 1.10 if training_level >= 2 and skill_id == "star_lance" else 1.0,
		"cooldown_multiplier": 0.96 if training_level >= 3 else 1.0,
		"hit_interval_multiplier": 0.96 if training_level >= 3 else 1.0,
	}


static func _effect_text(skill_id: String, training_level: int) -> String:
	if training_level <= 0:
		return "未训练"
	var effects := ["伤害与治疗 +4%"]
	if training_level >= 2:
		effects.append("弹速 +10%" if skill_id == "star_lance" else "作用范围 +8%")
	if training_level >= 3:
		effects.append("冷却或命中间隔 -4%")
	return " · ".join(effects)


static func _skill_ids(hero_id: String) -> Array:
	if not HeroCatalog.HEROES.has(hero_id):
		return []
	return HeroCatalog.hero(hero_id)["skills"].duplicate()
