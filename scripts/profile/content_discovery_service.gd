extends RefCounted

const ProfileSchema = preload("res://scripts/profile/profile_schema.gd")

var discovered: Dictionary = {}
var recent: Array[Dictionary] = []


func _init(raw_discovered: Dictionary = {}) -> void:
	for category in ProfileSchema.DISCOVERY_CATEGORIES:
		discovered[category] = {}
		var raw_category: Variant = raw_discovered.get(category, {})
		if raw_category is Dictionary:
			for content_id in raw_category:
				if bool(raw_category[content_id]) and _valid_id(str(content_id)):
					discovered[category][str(content_id)] = true
		elif raw_category is Array or raw_category is PackedStringArray:
			for content_id in raw_category:
				if _valid_id(str(content_id)):
					discovered[category][str(content_id)] = true


func discover(category: String, content_id: String) -> bool:
	if not discovered.has(category) or not _valid_id(content_id):
		return false
	if discovered[category].has(content_id):
		return false
	discovered[category][content_id] = true
	recent.append({"category": category, "content_id": content_id})
	return true


func is_discovered(category: String, content_id: String) -> bool:
	return discovered.has(category) and bool(discovered[category].get(content_id, false))


func count(category: String) -> int:
	return discovered[category].size() if discovered.has(category) else 0


func ids(category: String) -> PackedStringArray:
	if not discovered.has(category):
		return PackedStringArray()
	var result := PackedStringArray(discovered[category].keys())
	result.sort()
	return result


func new_discoveries() -> Array[Dictionary]:
	return recent.duplicate(true)


func clear_new_discoveries() -> void:
	recent.clear()


func snapshot() -> Dictionary:
	return discovered.duplicate(true)


func _valid_id(content_id: String) -> bool:
	return content_id.is_valid_identifier() and content_id == content_id.to_snake_case()
