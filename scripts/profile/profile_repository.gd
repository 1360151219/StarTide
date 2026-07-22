extends RefCounted


func load_profile(default_profile: Dictionary) -> Dictionary:
	return default_profile.duplicate(true)


func save_profile(_profile: Dictionary) -> Error:
	return ERR_UNAVAILABLE
