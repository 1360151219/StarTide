extends RefCounted

const MANIFEST: ContentManifestConfig = preload("res://content/skills.tres")
static var SKILLS: Dictionary = MANIFEST.as_dictionary()


static func ids() -> PackedStringArray:
	return PackedStringArray(SKILLS.keys())


static func has(skill_id: String) -> bool:
	return SKILLS.has(skill_id)


static func skill(skill_id: String) -> Dictionary:
	return SKILLS.get(skill_id, {})


static func skills_for_hero(hero_id: String) -> PackedStringArray:
	var result := PackedStringArray()
	for skill_id in SKILLS:
		if str(SKILLS[skill_id].get("owner_hero_id", "")) == hero_id:
			result.append(skill_id)
	return result


static func signature_for_hero(hero_id: String) -> String:
	for skill_id in SKILLS:
		var data: Dictionary = SKILLS[skill_id]
		if str(data.get("owner_hero_id", "")) == hero_id and bool(data.get("is_signature", false)):
			return skill_id
	return ""


static func branch(skill_id: String, branch_id: String) -> Dictionary:
	var data := skill(skill_id)
	if data.is_empty():
		return {}
	return data["branches"].get(branch_id, {})


static func branch_ids(skill_id: String) -> PackedStringArray:
	var data := skill(skill_id)
	if data.is_empty():
		return PackedStringArray()
	return PackedStringArray(data["branches"].keys())


static func validation_errors() -> PackedStringArray:
	var errors := MANIFEST.validation_errors(PackedStringArray([
		"name", "ultimate_name", "owner_hero_id", "is_signature", "max_level",
		"branch_level", "runtime_key", "icon", "descriptions", "runtime", "branches",
	]))
	var signatures: Dictionary = {}
	for skill_id in SKILLS:
		var data: Dictionary = SKILLS[skill_id]
		var max_level := int(data.get("max_level", 0))
		var branch_level := int(data.get("branch_level", 0))
		if max_level <= 0 or branch_level <= 1 or branch_level >= max_level:
			errors.append("%s 技能等级配置无效" % skill_id)
		var descriptions = data.get("descriptions", [])
		if not descriptions is Array or descriptions.size() != max_level + 1:
			errors.append("%s 技能描述没有覆盖 0 到 %d 级" % [skill_id, max_level])
		var runtime = data.get("runtime", {})
		if data.get("icon") == null or not runtime is Dictionary or runtime.is_empty():
			errors.append("%s 技能运行时或图标为空" % skill_id)
		elif runtime is Dictionary:
			for field in runtime:
				var values = runtime[field]
				if not values is Array or values.size() != max_level + 1:
					errors.append("%s 运行时字段 %s 没有覆盖 0 到 %d 级" % [skill_id, field, max_level])
		var branches = data.get("branches", {})
		if not branches is Dictionary or branches.size() != 2:
			errors.append("%s 必须配置两个技能分支" % skill_id)
		elif branches is Dictionary:
			for branch_id in branches:
				var branch_data: Dictionary = branches[branch_id]
				var overrides = branch_data.get("level_overrides", {})
				if not overrides is Dictionary:
					errors.append("%s/%s 缺少分支等级配置" % [skill_id, branch_id])
					continue
				for required_level in [branch_level, max_level - 1, max_level]:
					if not overrides.has(required_level):
						errors.append("%s/%s 缺少 %d 级分支强化" % [skill_id, branch_id, required_level])
				for override_level in overrides:
					if int(override_level) < branch_level or int(override_level) > max_level:
						errors.append("%s/%s 包含越界的 %s 级分支强化" % [skill_id, branch_id, str(override_level)])
		if bool(data.get("is_signature", false)):
			var hero_id := str(data.get("owner_hero_id", ""))
			if signatures.has(hero_id):
				errors.append("英雄 %s 拥有多个签名技能" % hero_id)
			signatures[hero_id] = skill_id
	return errors
