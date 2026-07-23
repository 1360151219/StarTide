extends RefCounted

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")


static func text(build_state: RefCounted) -> String:
	if build_state == null:
		return ""
	return "%s\n%s · 重抽 %d" % [
		_skill_line(build_state),
		_relic_line(build_state),
		int(build_state.rerolls_remaining),
	]


static func _skill_line(build_state: RefCounted) -> String:
	var entries := PackedStringArray()
	for raw_skill_id in build_state.skill_slots:
		var skill_id := str(raw_skill_id)
		if skill_id.is_empty() or not SkillCatalog.has(skill_id):
			continue
		var entry := "%s %s" % [
			SkillCatalog.skill(skill_id)["name"],
			_level_mark(int(build_state.skill_levels.get(skill_id, 1))),
		]
		if build_state.skill_branches.has(skill_id):
			var branch := SkillCatalog.branch(skill_id, str(build_state.skill_branches[skill_id]))
			if not branch.is_empty():
				entry += "·" + str(branch["name"])
		entries.append(entry)
	return "技能：" + (" / ".join(entries) if not entries.is_empty() else "暂无")


static func _relic_line(build_state: RefCounted) -> String:
	var entries := PackedStringArray()
	for relic_id in RelicCatalog.ids():
		if not build_state.relic_levels.has(relic_id):
			continue
		entries.append("%s %s" % [
			RelicCatalog.relic(relic_id)["name"],
			_level_mark(int(build_state.relic_levels[relic_id])),
		])
	return "遗物：" + (" / ".join(entries) if not entries.is_empty() else "暂无")


static func _level_mark(level: int) -> String:
	var marks := ["", "I", "II", "III"]
	return marks[clampi(level, 0, marks.size() - 1)]
