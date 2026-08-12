extends RefCounted

const MANIFEST: ContentManifestConfig = preload("res://content/enemy_abilities.tres")
static var ABILITIES: Dictionary = MANIFEST.as_dictionary()


static func ability(ability_id: String) -> Dictionary:
	return ABILITIES.get(ability_id, {})


static func ability_for_enemy(enemy_id: String) -> String:
	var fallback := ""
	for ability_id in ABILITIES:
		var data: Dictionary = ABILITIES[ability_id]
		if str(data.get("enemy_id", "")) != enemy_id:
			continue
		if bool(data.get("is_default", false)):
			return ability_id
		if fallback.is_empty():
			fallback = ability_id
	return fallback


static func threat_multiplier(ability_id: String) -> float:
	return float(ability(ability_id).get("threat_multiplier", 1.0))


static func ids() -> PackedStringArray:
	return PackedStringArray(ABILITIES.keys())


static func validation_errors(valid_enemy_ids := PackedStringArray()) -> PackedStringArray:
	var errors := MANIFEST.validation_errors(PackedStringArray([
		"enemy_id", "runtime_kind", "hit_type", "name", "warning", "cooldown",
		"min_range", "max_range", "damage", "recovery", "shape", "threat_multiplier",
		"warning_cue", "charge_cue", "execute_cue", "hit_cue",
	]))
	var default_enemies: Dictionary = {}
	for ability_id in ABILITIES:
		var data: Dictionary = ABILITIES[ability_id]
		var enemy_id := str(data.get("enemy_id", ""))
		if not valid_enemy_ids.is_empty() and not valid_enemy_ids.has(enemy_id):
			errors.append("%s 引用了未知怪物 %s" % [ability_id, enemy_id])
		var runtime_kind := str(data.get("runtime_kind", ""))
		if runtime_kind == "roll":
			_validate_positive_fields(errors, ability_id, data, PackedStringArray(["speed", "distance", "lane_width"]))
			if str(data.get("shape", "")) != "lane":
				errors.append("%s 的滚动预警必须使用 lane" % ability_id)
		elif runtime_kind == "bolt":
			_validate_positive_fields(errors, ability_id, data, PackedStringArray([
				"lock_time", "projectile_speed", "projectile_radius", "projectile_distance",
			]))
			if str(data.get("shape", "")) != "dashed_line":
				errors.append("%s 的弹体预警必须使用 dashed_line" % ability_id)
		elif runtime_kind == "burst":
			if str(data.get("shape", "")) == "circle":
				_validate_positive_fields(errors, ability_id, data, PackedStringArray(["radius"]))
			elif str(data.get("shape", "")) == "sector":
				_validate_positive_fields(errors, ability_id, data, PackedStringArray(["radius", "arc_degrees"]))
			else:
				errors.append("%s 的范围技能预警形状无效" % ability_id)
		elif runtime_kind == "boss_dash":
			_validate_positive_fields(errors, ability_id, data, PackedStringArray(["speed", "distance", "lane_width"]))
			if str(data.get("shape", "")) != "lane":
				errors.append("%s 的冲刺预警必须使用 lane" % ability_id)
		elif runtime_kind == "boss_tail_sweep":
			_validate_positive_fields(errors, ability_id, data, PackedStringArray(["inner_radius", "outer_radius", "arc_degrees"]))
			if str(data.get("shape", "")) != "annular_sector":
				errors.append("%s 的尾扫预警必须使用 annular_sector" % ability_id)
		elif runtime_kind == "boss_marks":
			_validate_positive_fields(errors, ability_id, data, PackedStringArray(["radius"]))
			if str(data.get("shape", "")) != "circle":
				errors.append("%s 的云印预警必须使用 circle" % ability_id)
		else:
			errors.append("%s 使用了未知运行类型 %s" % [ability_id, runtime_kind])
		if str(data.get("hit_type", "")).is_empty():
			errors.append("%s 的命中类型不能为空" % ability_id)
		_validate_positive_fields(errors, ability_id, data, PackedStringArray([
			"warning", "cooldown", "max_range", "damage", "recovery", "threat_multiplier",
		]))
		if float(data.get("min_range", -1.0)) < 0.0 or float(data.get("min_range", 0.0)) >= float(data.get("max_range", 0.0)):
			errors.append("%s 的施法距离区间无效" % ability_id)
		if bool(data.get("is_default", false)):
			if default_enemies.has(enemy_id):
				errors.append("怪物 %s 配置了多个默认技能" % enemy_id)
			default_enemies[enemy_id] = ability_id
	return errors


static func _validate_positive_fields(errors: PackedStringArray, ability_id: String, data: Dictionary, fields: PackedStringArray) -> void:
	for field in fields:
		if float(data.get(field, 0.0)) <= 0.0:
			errors.append("%s 的 %s 必须大于 0" % [ability_id, field])
