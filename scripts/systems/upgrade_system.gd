extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const SKILL_MAX_LEVEL := 3

var rng: RandomNumberGenerator


func _init(random: RandomNumberGenerator) -> void:
	rng = random


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


func choice_text(choice_id: String, levels: Dictionary) -> String:
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
	return "应急修复\n恢复 45 点生命；满生命时上限 +10"


func apply(choice_id: String, player: Node2D, skills: Node2D) -> void:
	if skills.levels.has(choice_id):
		skills.upgrade(choice_id)
	elif choice_id == "vitality":
		player.max_health += 25.0
		player.heal(25.0)
	elif choice_id == "swiftness":
		player.speed *= 1.12
	elif is_equal_approx(player.health, player.max_health):
		player.max_health += 10.0
		player.heal(10.0)
	else:
		player.heal(45.0)


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
	return ["", "I", "II", "III"][value]
