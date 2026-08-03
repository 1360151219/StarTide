extends "res://scripts/profile/profile_repository.gd"

const ProfileSchema = preload("res://scripts/profile/profile_schema.gd")

var storage_path: String


func _init(path: String) -> void:
	storage_path = path


func load_profile(default_profile: Dictionary) -> Dictionary:
	var profile := default_profile.duplicate(true)
	_ensure_profile_id(profile)
	if storage_path.is_empty():
		return profile
	var config := ConfigFile.new()
	if config.load(storage_path) != OK:
		return profile
	var source_schema := maxi(1, int(config.get_value("meta", "schema_version", 1)))
	profile["source_schema_version"] = source_schema
	profile["profile_id"] = str(config.get_value("meta", "profile_id", profile["profile_id"]))
	profile["revision"] = maxi(0, int(config.get_value("meta", "revision", 0)))
	profile["last_hero_id"] = str(config.get_value("meta", "last_hero_id", profile["last_hero_id"]))
	profile["active_hero_id"] = str(config.get_value("meta", "active_hero_id", profile["last_hero_id"]))
	profile["last_level_id"] = str(config.get_value("meta", "last_level_id", profile["last_level_id"]))
	profile["next_equipment_sequence"] = maxi(1, int(config.get_value("meta", "next_equipment_sequence", 1)))
	for hero_id in profile["records"]:
		_load_record(config, "hero/" + hero_id, profile["records"][hero_id])
	for level_id in profile["level_records"]:
		_load_record(config, "level/" + level_id, profile["level_records"][level_id])
		profile["unlocked_levels"][level_id] = bool(config.get_value("progress", "unlocked_" + level_id, profile["unlocked_levels"][level_id]))
	for hero_id in profile["hero_progressions"]:
		_load_progression(config, profile, hero_id, source_schema)
	_load_equipment(config, profile)
	_load_reward_receipts(config, profile)
	if source_schema < ProfileSchema.CONTENT_DISCOVERY_VERSION:
		profile["discovered_content"] = _legacy_public_content()
	else:
		_load_discovered_content(config, profile)
	_ensure_profile_id(profile)
	return profile


func save_profile(profile: Dictionary) -> Error:
	if storage_path.is_empty():
		return OK
	_ensure_profile_id(profile)
	profile["revision"] = maxi(0, int(profile.get("revision", 0))) + 1
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", ProfileSchema.VERSION)
	config.set_value("meta", "profile_id", profile["profile_id"])
	config.set_value("meta", "revision", profile["revision"])
	config.set_value("meta", "last_hero_id", profile["last_hero_id"])
	config.set_value("meta", "active_hero_id", profile["active_hero_id"])
	config.set_value("meta", "last_level_id", profile["last_level_id"])
	config.set_value("meta", "next_equipment_sequence", profile["next_equipment_sequence"])
	for hero_id in profile["records"]:
		_write_record(config, "hero/" + hero_id, profile["records"][hero_id])
	for level_id in profile["level_records"]:
		_write_record(config, "level/" + level_id, profile["level_records"][level_id])
		config.set_value("progress", "unlocked_" + level_id, profile["unlocked_levels"][level_id])
	for hero_id in profile["hero_progressions"]:
		_write_progression(config, hero_id, profile["hero_progressions"][hero_id])
	_write_equipment(config, profile)
	_write_reward_receipts(config, profile.get("granted_reward_ids", {}))
	_write_discovered_content(config, profile.get("discovered_content", {}))
	return config.save(storage_path)


func _load_progression(config: ConfigFile, profile: Dictionary, hero_id: String, source_schema: int) -> void:
	var progression: Dictionary = profile["hero_progressions"][hero_id]
	if source_schema < ProfileSchema.HERO_PROGRESSION_VERSION:
		progression["hero_xp"] = int(profile["records"][hero_id]["wins"]) * 100
		return
	var section := "progression/" + hero_id
	var xp_key := "hero_xp" if source_schema >= ProfileSchema.HERO_XP_VERSION else "mastery_xp"
	progression["hero_xp"] = maxi(0, int(config.get_value(section, xp_key, 0)))
	for skill_id in progression["training"]:
		progression["training"][skill_id] = int(config.get_value(section, "training_" + skill_id, 0))


func _write_progression(config: ConfigFile, hero_id: String, progression: Dictionary) -> void:
	var section := "progression/" + hero_id
	config.set_value(section, "hero_xp", progression["hero_xp"])
	for skill_id in progression["training"]:
		config.set_value(section, "training_" + skill_id, progression["training"][skill_id])


func _load_equipment(config: ConfigFile, profile: Dictionary) -> void:
	var items := {}
	if config.has_section("equipment/items"):
		for instance_id in config.get_section_keys("equipment/items"):
			var raw_item: Variant = config.get_value("equipment/items", instance_id, {})
			if raw_item is Dictionary:
				items[instance_id] = raw_item
	profile["equipment_inventory"] = items
	for hero_id in profile["equipment_loadouts"]:
		var section: String = "equipment/loadout/" + hero_id
		for slot_id in profile["equipment_loadouts"][hero_id]:
			profile["equipment_loadouts"][hero_id][slot_id] = str(config.get_value(section, slot_id, ""))


func _write_equipment(config: ConfigFile, profile: Dictionary) -> void:
	for instance_id in profile["equipment_inventory"]:
		config.set_value("equipment/items", instance_id, profile["equipment_inventory"][instance_id])
	for hero_id in profile["equipment_loadouts"]:
		var section: String = "equipment/loadout/" + hero_id
		for slot_id in profile["equipment_loadouts"][hero_id]:
			config.set_value(section, slot_id, profile["equipment_loadouts"][hero_id][slot_id])


func _load_reward_receipts(config: ConfigFile, profile: Dictionary) -> void:
	var stored_ids: Variant = config.get_value("rewards", "granted_ids", PackedStringArray())
	if stored_ids is Array or stored_ids is PackedStringArray:
		for reward_id in stored_ids:
			profile["granted_reward_ids"][str(reward_id)] = true


func _write_reward_receipts(config: ConfigFile, granted_reward_ids: Dictionary) -> void:
	var stored_ids := PackedStringArray(granted_reward_ids.keys())
	stored_ids.sort()
	config.set_value("rewards", "granted_ids", stored_ids)


func _load_discovered_content(config: ConfigFile, profile: Dictionary) -> void:
	for category in ProfileSchema.DISCOVERY_CATEGORIES:
		var category_state: Dictionary = profile["discovered_content"][category]
		var stored_ids: Variant = config.get_value("discovery", category, PackedStringArray())
		if stored_ids is Array or stored_ids is PackedStringArray:
			for content_id in stored_ids:
				category_state[str(content_id)] = true


func _write_discovered_content(config: ConfigFile, discovered_content: Dictionary) -> void:
	for category in ProfileSchema.DISCOVERY_CATEGORIES:
		var category_state: Dictionary = discovered_content.get(category, {})
		var content_ids := PackedStringArray(category_state.keys())
		content_ids.sort()
		config.set_value("discovery", category, content_ids)


func _legacy_public_content() -> Dictionary:
	var result := {}
	for category in ProfileSchema.DISCOVERY_CATEGORIES:
		result[category] = {}
		for content_id in ProfileSchema.LEGACY_PUBLIC_CONTENT_V3[category]:
			result[category][content_id] = true
	return result


func _load_record(config: ConfigFile, section: String, record: Dictionary) -> void:
	for field in record:
		record[field] = maxi(0, int(config.get_value(section, field, 0)))


func _write_record(config: ConfigFile, section: String, record: Dictionary) -> void:
	for field in record:
		config.set_value(section, field, record[field])


func _ensure_profile_id(profile: Dictionary) -> void:
	if not str(profile.get("profile_id", "")).is_empty():
		return
	var random := RandomNumberGenerator.new()
	random.randomize()
	profile["profile_id"] = "local-%x-%x-%x" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), random.randi()]
