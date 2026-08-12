extends Node

var played_cue_ids := PackedStringArray()

func play_sfx(sound_id: String, _volume_db := 0.0, _pitch_scale := 1.0) -> void:
	played_cue_ids.append(sound_id)
