extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const ChoiceFactory = preload("res://scripts/systems/upgrade_choice_factory.gd")
const ChoicePlanner = preload("res://scripts/systems/upgrade_choice_planner.gd")
const SKILL_MAX_LEVEL := 3

const SKILL_UNLOCK := ChoiceFactory.SKILL_UNLOCK
const SKILL_UPGRADE := ChoiceFactory.SKILL_UPGRADE
const SKILL_BRANCH := ChoiceFactory.SKILL_BRANCH
const RELIC_UPGRADE := ChoiceFactory.RELIC_UPGRADE
const UTILITY_RECOVERY := ChoiceFactory.UTILITY_RECOVERY

var rng: RandomNumberGenerator
var planner: RefCounted


func _init(random: RandomNumberGenerator) -> void:
	rng = random
	planner = ChoicePlanner.new(random)


func build_structured_choices(build_state: RefCounted, skill_pool_ids, relic_pool_ids, health_ratio := 1.0) -> Array:
	var choices: Array = planner.pick_group(build_state, skill_pool_ids, relic_pool_ids, health_ratio, "")
	if not choices.is_empty():
		build_state.remember_offer(choices)
	return choices


func reroll_structured_choices(build_state: RefCounted, skill_pool_ids, relic_pool_ids, health_ratio := 1.0) -> Dictionary:
	if int(build_state.rerolls_remaining) <= 0:
		return {"success": false, "reason": "本局重抽次数已用完", "choices": []}
	var choices: Array = planner.pick_group(build_state, skill_pool_ids, relic_pool_ids, health_ratio, str(build_state.last_offer_key))
	if choices.is_empty():
		return {"success": false, "reason": "当前没有不同的合法候选组合", "choices": []}
	if not build_state.consume_reroll():
		return {"success": false, "reason": "本局重抽次数已用完", "choices": []}
	build_state.remember_offer(choices)
	return {"success": true, "reason": "候选已重抽", "choices": choices}


func legal_structured_candidates(build_state: RefCounted, skill_pool_ids, relic_pool_ids, health_ratio := 1.0) -> Array:
	return planner.legal_candidates(build_state, skill_pool_ids, relic_pool_ids, health_ratio)


func apply_structured_choice(raw_choice, build_state: RefCounted) -> Dictionary:
	var choice_key := str(raw_choice.get("choice_key", "")) if raw_choice is Dictionary else str(raw_choice)
	var choice: Dictionary = build_state.pending_choice(choice_key)
	if choice.is_empty():
		return {"success": false, "reason": "候选不存在或并非当前可选项", "effects": {}}
	var validation_error := _choice_validation_error(choice, build_state)
	if not validation_error.is_empty():
		return {"success": false, "reason": validation_error, "effects": {}}
	var kind := str(choice["kind"])
	var content_id := str(choice["content_id"])
	var applied := false
	var effects := {}
	if kind == SKILL_UNLOCK:
		applied = build_state.add_skill(content_id)
	elif kind == SKILL_BRANCH:
		applied = build_state.select_branch(content_id, str(choice["branch_id"]))
	elif kind == SKILL_UPGRADE:
		applied = build_state.upgrade_skill(content_id)
	elif kind == RELIC_UPGRADE:
		applied = build_state.add_or_upgrade_relic(content_id)
		if applied:
			effects = RelicCatalog.relic(content_id)["acquire_effects"].duplicate(true)
	elif kind == UTILITY_RECOVERY:
		applied = true
		effects = {"heal": 45.0}
	if not applied:
		return {"success": false, "reason": "构筑状态已变化，无法应用该候选", "effects": {}}
	build_state.clear_offer()
	return {
		"success": true,
		"reason": "强化已应用",
		"choice": choice.duplicate(true),
		"effects": effects,
		"snapshot": build_state.snapshot(),
	}


func build_choices(active_skill_ids: Array, levels: Dictionary, health_ratio: float) -> Array:
	var owned: Array = []
	var locked: Array = []
	var upgradeable: Array = []
	for skill_id in active_skill_ids:
		var skill_level: int = levels[skill_id]
		if skill_level >= SKILL_MAX_LEVEL:
			continue
		upgradeable.append(skill_id)
		if skill_level > 0:
			owned.append(skill_id)
		else:
			locked.append(skill_id)
	var choices: Array = []
	_append_random_unique(choices, owned)
	_append_random_unique(choices, locked)
	var common: Array = ["vitality", "swiftness"]
	if health_ratio <= 0.75:
		common.append("recovery")
	_append_random_unique(choices, common)
	var fallback := upgradeable + ["vitality", "swiftness", "recovery"]
	while choices.size() < 3 and _append_random_unique(choices, fallback):
		pass
	return choices


func choice_text(choice, levels := {}) -> String:
	if choice is Dictionary:
		return "%s\n%s" % [str(choice.get("title", "未知强化")), str(choice.get("description", ""))]
	var choice_id := str(choice)
	if levels.has(choice_id):
		var next_level: int = levels[choice_id] + 1
		var skill := HeroCatalog.skill(choice_id)
		var skill_name: String = skill["ultimate_name"] if next_level == SKILL_MAX_LEVEL else skill["name"]
		var prefix := "终极 · " if next_level == SKILL_MAX_LEVEL else ""
		return "%s%s  %s\n%s" % [prefix, skill_name, _roman(next_level), skill["descriptions"][next_level]]
	if choice_id == "vitality":
		return "星核扩容\n最大生命 +25，并立刻恢复 25"
	if choice_id == "swiftness":
		return "流光步\n移动速度永久 +12%"
	if choice_id == "recovery":
		return "应急修复\n恢复 45 点生命；满生命时上限 +10"
	return "无效强化"


func apply(choice_id: String, player: Node2D, skills: Node2D) -> bool:
	if skills.levels.has(choice_id):
		if int(skills.levels[choice_id]) >= SKILL_MAX_LEVEL:
			return false
		skills.upgrade(choice_id)
		return true
	if choice_id == "vitality":
		player.max_health += 25.0
		player.heal(25.0)
		return true
	if choice_id == "swiftness":
		player.speed *= 1.12
		return true
	if choice_id != "recovery":
		return false
	if is_equal_approx(player.health, player.max_health):
		player.max_health += 10.0
		player.heal(10.0)
	else:
		player.heal(45.0)
	return true


func _choice_validation_error(choice: Dictionary, build_state: RefCounted) -> String:
	var kind := str(choice.get("kind", ""))
	var content_id := str(choice.get("content_id", ""))
	var target_level := int(choice.get("target_level", -1))
	if kind == SKILL_UNLOCK:
		if not SkillCatalog.has(content_id) or not build_state.can_add_skill(content_id) or target_level != 1:
			return "技能已锁定、已拥有或没有空余技能槽"
		return ""
	if kind == SKILL_BRANCH:
		if not SkillCatalog.has(content_id) or not build_state.can_select_branch(content_id, str(choice.get("branch_id", ""))):
			return "技能分支已选择或当前等级不允许分支"
		return ""
	if kind == SKILL_UPGRADE:
		if not SkillCatalog.has(content_id) or not build_state.can_upgrade_skill(content_id):
			return "技能已满级或尚未完成分支选择"
		if target_level != int(build_state.skill_levels[content_id]) + 1:
			return "技能目标等级已失效"
		return ""
	if kind == RELIC_UPGRADE:
		if not RelicCatalog.has(content_id) or not build_state.can_add_or_upgrade_relic(content_id):
			return "遗物已满级或没有空余遗物槽"
		if target_level != int(build_state.relic_levels.get(content_id, 0)) + 1:
			return "遗物目标等级已失效"
		return ""
	if kind == UTILITY_RECOVERY and content_id == "recovery":
		return ""
	return "未知强化类型"


func _append_random_unique(target: Array, candidates: Array) -> bool:
	var available: Array = []
	for candidate in candidates:
		if not target.has(candidate):
			available.append(candidate)
	if available.is_empty():
		return false
	target.append(available[rng.randi_range(0, available.size() - 1)])
	return true


func _roman(value: int) -> String:
	return ["", "I", "II", "III"][clampi(value, 0, 3)]
