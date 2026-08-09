extends RefCounted


static func create(seed_value: int) -> Dictionary:
	var streams := {}
	for stream_id in ["spawn", "loot", "skill", "upgrade", "enemy_ability"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + streams.size()
		streams[stream_id] = rng
	return streams
