extends RefCounted

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const ChoiceFactory = preload("res://scripts/systems/upgrade_choice_factory.gd")
const HEART_ICON := preload("res://assets/art/pickups/healing_heart.png")


static func normalize(raw_choice, upgrade_system: RefCounted) -> Dictionary:
	if raw_choice is Dictionary:
		return raw_choice
	var lines: PackedStringArray = upgrade_system.choice_text(raw_choice).split("\n", false, 1)
	return {
		"choice_key": str(raw_choice),
		"kind": "legacy",
		"content_id": str(raw_choice),
		"target_level": 0,
		"branch_id": "",
		"title": str(lines[0]) if not lines.is_empty() else "未知强化",
		"description": str(lines[1]) if lines.size() > 1 else "",
	}


static func view_model(choice: Dictionary) -> Dictionary:
	var kind := str(choice.get("kind", ""))
	var special := _special_text(choice)
	var rarity_level := 3 if special == "终极进化" else (2 if kind in ["skill_branch", "relic_upgrade"] else 1)
	return {
		"icon": _icon(choice),
		"kind": kind,
		"shape": _shape_id(kind),
		"type": _type_text(kind),
		"name": _name_text(choice),
		"description": str(choice.get("description", "")),
		"metrics": _metrics(choice),
		"special": special,
		"highlighted": rarity_level == 3,
		"branch": kind == "skill_branch",
		"rarity_level": rarity_level,
	}


static func _icon(choice: Dictionary) -> Texture2D:
	var content_id := str(choice.get("content_id", ""))
	if str(choice.get("kind", "")) == "relic_upgrade":
		return RelicCatalog.icon(content_id)
	if SkillCatalog.has(content_id):
		return SkillCatalog.skill(content_id)["icon"]
	return HEART_ICON


static func _type_text(kind: String) -> String:
	match kind:
		"skill_unlock":
			return "新技能"
		"skill_upgrade":
			return "技能强化"
		"skill_branch":
			return "流派分支"
		"relic_upgrade":
			return "星遗物"
		"utility_recovery":
			return "生存补给"
		_:
			return "星辉强化"


static func _shape_id(kind: String) -> String:
	if kind == "relic_upgrade":
		return "relic"
	if kind == "utility_recovery":
		return "supply"
	return "skill"


static func _name_text(choice: Dictionary) -> String:
	var title_text := str(choice.get("title", "未知强化"))
	var kind := str(choice.get("kind", ""))
	var target_level := int(choice.get("target_level", 0))
	if kind == "skill_upgrade" and target_level > 0 and not title_text.begins_with("终极"):
		return "%s  ·  %s" % [title_text, ChoiceFactory.roman(target_level)]
	return title_text


static func _special_text(choice: Dictionary) -> String:
	var kind := str(choice.get("kind", ""))
	if kind == "skill_branch":
		return "选择分支"
	if kind == "skill_upgrade":
		var skill := SkillCatalog.skill(str(choice.get("content_id", "")))
		if not skill.is_empty() and int(choice.get("target_level", 0)) >= int(skill["max_level"]):
			return "终极进化"
	return ""


static func _metrics(choice: Dictionary) -> Array[Dictionary]:
	var kind := str(choice.get("kind", ""))
	var content_id := str(choice.get("content_id", ""))
	var target_level := int(choice.get("target_level", 0))
	if kind == "skill_branch":
		return _branch_metrics(content_id, str(choice.get("branch_id", "")), target_level)
	if kind == "skill_unlock" or kind == "skill_upgrade":
		return _skill_metrics(content_id, target_level)
	if kind == "relic_upgrade":
		return _relic_metrics(content_id, target_level)
	if kind == "utility_recovery":
		return [_metric("恢复", "+45", "heal"), _metric("生命上限", "+10", "heal")]
	return [_metric("强化", "立即", "confirm")]


static func _skill_metrics(skill_id: String, target_level: int) -> Array[Dictionary]:
	var skill := SkillCatalog.skill(skill_id)
	if skill.is_empty() or not skill.has("runtime"):
		return [_metric("等级", ChoiceFactory.roman(target_level), "level")]
	var result: Array[Dictionary] = []
	var definitions := [
		["count", "数量", "level"], ["damage", "伤害", "enemy"], ["healing", "恢复", "heal"],
		["cooldown", "间隔", "clock"], ["hit_interval", "间隔", "clock"],
		["radius", "范围", "magnet"], ["blast_radius", "爆炸", "bomb"], ["orbit_radius", "环绕", "expedition"],
	]
	var runtime: Dictionary = skill["runtime"]
	for definition in definitions:
		var key := str(definition[0])
		var values = runtime.get(key, [])
		if target_level <= 0 or target_level >= values.size():
			continue
		var before := float(values[maxi(0, target_level - 1)])
		var after := float(values[target_level])
		if is_equal_approx(before, after):
			continue
		result.append(_metric(str(definition[1]), _skill_value(key, before, after), str(definition[2])))
		if result.size() >= 3:
			break
	if result.is_empty():
		result.append(_metric("等级", ChoiceFactory.roman(target_level), "level"))
	return result


static func _branch_metrics(skill_id: String, branch_id: String, target_level: int) -> Array[Dictionary]:
	var branch := SkillCatalog.branch(skill_id, branch_id)
	var result: Array[Dictionary] = [_metric("阶段", ChoiceFactory.roman(target_level), "level")]
	for tag in branch.get("visual_tags", []):
		result.append(_metric("特性" if result.size() == 1 else "定位", str(tag), "confirm" if result.size() == 1 else "expedition"))
		if result.size() >= 3:
			break
	return result


static func _relic_metrics(relic_id: String, target_level: int) -> Array[Dictionary]:
	var relic := RelicCatalog.relic(relic_id)
	if relic.is_empty():
		return [_metric("等级", ChoiceFactory.roman(target_level), "level")]
	var modifiers: Dictionary = relic.get("modifiers_per_level", {})
	var result: Array[Dictionary] = []
	var seen_labels := {}
	for raw_key in modifiers:
		var key := str(raw_key)
		var label := _modifier_name(key)
		if seen_labels.has(label):
			continue
		seen_labels[label] = true
		var per_level := float(modifiers[key])
		var before := per_level * maxi(0, target_level - 1)
		var after := per_level * target_level
		result.append(_metric(label, _transition(_modifier_value(key, before), _modifier_value(key, after), before), _modifier_symbol(key)))
	var healing := float(relic.get("acquire_effects", {}).get("heal", 0.0))
	if healing > 0.0 and result.size() < 3:
		result.append(_metric("恢复", "+%.0f" % healing, "heal"))
	if result.is_empty():
		result.append(_metric("等级", ChoiceFactory.level_mark(target_level, int(relic["max_level"]), true), "level"))
	return result


static func _metric(label: String, value: String, symbol: String) -> Dictionary:
	return {"label": label, "value": value, "symbol": symbol}


static func _skill_value(key: String, before: float, after: float) -> String:
	var before_text := "%.1f" % before if key in ["cooldown", "hit_interval", "healing"] else "%.0f" % before
	var after_text := "%.1f" % after if key in ["cooldown", "hit_interval", "healing"] else "%.0f" % after
	if is_zero_approx(before):
		return after_text
	return "%s→%s" % [before_text, after_text]


static func _transition(before_text: String, after_text: String, before: float) -> String:
	return after_text if is_zero_approx(before) else "%s→%s" % [before_text, after_text]


static func _modifier_name(key: String) -> String:
	match key:
		"max_health_flat":
			return "最大生命"
		"move_speed_multiplier":
			return "移动速度"
		"damage_multiplier":
			return "技能伤害"
		"cooldown_multiplier":
			return "技能间隔"
		"hit_interval_multiplier":
			return "技能间隔"
		"range_multiplier":
			return "技能范围"
		"pickup_radius_multiplier":
			return "拾取范围"
		_:
			return "遗物效果"


static func _modifier_symbol(key: String) -> String:
	if key == "max_health_flat":
		return "heal"
	if key == "move_speed_multiplier":
		return "haste"
	if key in ["cooldown_multiplier", "hit_interval_multiplier"]:
		return "clock"
	if key in ["range_multiplier", "pickup_radius_multiplier"]:
		return "magnet"
	return "confirm"


static func _modifier_value(key: String, value: float) -> String:
	if key.ends_with("_flat"):
		return "%+.0f" % value
	return "%+.0f%%" % (value * 100.0)
