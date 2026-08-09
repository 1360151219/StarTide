extends Node

signal settings_changed

const CueCatalog = preload("res://scripts/audio_cue_catalog.gd")
const BusLayoutBuilder = preload("res://scripts/audio_bus_layout.gd")
const SETTINGS_PATH := "user://audio_settings.cfg"
const MUSIC_BASE_DB := -9.0
const SFX_BASE_DB := -4.0
const MUSIC_DUCK_DB := -6.0
const MUSIC_DUCK_DOWN_SECONDS := 0.15
const MUSIC_DUCK_UP_SECONDS := 0.28
const VOICE_COUNT := 16

var music_enabled := true
var sfx_enabled := true
var music_volume := 0.65
var sfx_volume := 0.75
var music_ducked := false
var audio_output_available := true
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var save_timer: Timer
var cooldowns: Dictionary = {}
var voice_serial := 0
var music_duck_offset_db := 0.0
var current_music_profile := "lobby"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	audio_output_available = DisplayServer.get_name() != "headless"
	_ensure_audio_buses()
	_load_settings()
	save_timer = Timer.new()
	save_timer.one_shot = true
	save_timer.wait_time = 0.35
	save_timer.timeout.connect(_save_settings)
	add_child(save_timer)
	music_player = AudioStreamPlayer.new()
	music_player.bus = CueCatalog.BUS_MUSIC
	add_child(music_player)
	for _index in range(VOICE_COUNT):
		var player := AudioStreamPlayer.new()
		player.bus = CueCatalog.BUS_SFX
		player.set_meta("priority", -1)
		player.set_meta("cue_id", "")
		player.set_meta("voice_serial", -1)
		add_child(player)
		sfx_players.append(player)
	_apply_sfx_volume()
	_apply_music_volume()
	play_music()


func _process(delta: float) -> void:
	for cue_id in cooldowns.keys():
		cooldowns[cue_id] = maxf(0.0, float(cooldowns[cue_id]) - delta)
	var target := MUSIC_DUCK_DB if music_ducked else 0.0
	var duration := MUSIC_DUCK_DOWN_SECONDS if music_ducked else MUSIC_DUCK_UP_SECONDS
	var next_offset := move_toward(music_duck_offset_db, target, absf(MUSIC_DUCK_DB) * delta / duration)
	if not is_equal_approx(next_offset, music_duck_offset_db):
		music_duck_offset_db = next_offset
		_apply_music_volume()


func _exit_tree() -> void:
	if is_instance_valid(save_timer):
		if save_timer.time_left > 0.0:
			_save_settings()
		save_timer.stop()
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	for player in sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	cooldowns.clear()


func play_music(profile_id := "lobby") -> void:
	current_music_profile = profile_id
	if not audio_output_available or not music_enabled:
		return
	var stream := CueCatalog.music(profile_id)
	if music_player.playing and music_player.stream == stream:
		return
	music_player.stop()
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	music_player.stream = stream
	music_player.play()


func play_cue(cue_id: String, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if not audio_output_available or not sfx_enabled or cooldowns.get(cue_id, 0.0) > 0.0:
		return
	var cue := CueCatalog.cue(cue_id)
	if cue.is_empty():
		return
	var player := _select_voice(cue_id, int(cue["priority"]), int(cue["max_instances"]))
	if player == null:
		return
	player.stop()
	player.stream = cue["stream"]
	player.bus = cue["bus"]
	player.volume_db = float(cue.get("base_db", 0.0)) + volume_db
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.set_meta("priority", int(cue["priority"]))
	player.set_meta("cue_id", cue_id)
	player.set_meta("voice_serial", voice_serial)
	voice_serial += 1
	player.play()
	cooldowns[cue_id] = float(cue.get("cooldown", 0.025))


func play_sfx(cue_id: String, volume_db := 0.0, pitch_scale := 1.0) -> void:
	play_cue(cue_id, volume_db, pitch_scale)


func toggle_music() -> bool:
	music_enabled = not music_enabled
	if music_enabled:
		play_music(current_music_profile)
	else:
		music_player.stop()
	_save_settings()
	settings_changed.emit()
	return music_enabled


func toggle_sfx() -> bool:
	sfx_enabled = not sfx_enabled
	if not sfx_enabled:
		for player in sfx_players:
			player.stop()
	_save_settings()
	settings_changed.emit()
	return sfx_enabled


func set_music_volume(value: float, save := true) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_music_volume()
	if save:
		_schedule_save()
	settings_changed.emit()


func set_sfx_volume(value: float, save := true) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_sfx_volume()
	if save:
		_schedule_save()
	settings_changed.emit()


func set_music_ducked(value: bool) -> void:
	music_ducked = value


func active_cue_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for player in sfx_players:
		if player.playing:
			result.append(str(player.get_meta("cue_id", "")))
	return result


func _select_voice(cue_id: String, priority: int, max_instances: int) -> AudioStreamPlayer:
	var same_cue_count := 0
	var free_player: AudioStreamPlayer
	var lowest_player: AudioStreamPlayer
	var lowest_priority := INF
	var oldest_serial := INF
	for player in sfx_players:
		if not player.playing:
			if free_player == null:
				free_player = player
			continue
		if str(player.get_meta("cue_id", "")) == cue_id:
			same_cue_count += 1
		var candidate_priority := int(player.get_meta("priority", -1))
		var candidate_serial := int(player.get_meta("voice_serial", -1))
		if candidate_priority < lowest_priority or candidate_priority == lowest_priority and candidate_serial < oldest_serial:
			lowest_priority = candidate_priority
			oldest_serial = candidate_serial
			lowest_player = player
	if same_cue_count >= max_instances:
		return null
	if free_player != null:
		return free_player
	if lowest_player != null and priority > lowest_priority:
		return lowest_player
	return null


func _ensure_audio_buses() -> void:
	BusLayoutBuilder.ensure()


func _apply_music_volume() -> void:
	var bus_index := AudioServer.get_bus_index(CueCatalog.BUS_MUSIC)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, _volume_db(music_volume, MUSIC_BASE_DB) + music_duck_offset_db)


func _apply_sfx_volume() -> void:
	var bus_index := AudioServer.get_bus_index(CueCatalog.BUS_SFX)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, _volume_db(sfx_volume, SFX_BASE_DB))


func _volume_db(value: float, base_db: float) -> float:
	if value <= 0.001:
		return -80.0
	return base_db + linear_to_db(value)


func _load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	music_enabled = bool(settings.get_value("audio", "music_enabled", music_enabled))
	sfx_enabled = bool(settings.get_value("audio", "sfx_enabled", sfx_enabled))
	music_volume = clampf(float(settings.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(settings.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)


func _schedule_save() -> void:
	if is_instance_valid(save_timer):
		save_timer.start()


func _save_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value("audio", "music_enabled", music_enabled)
	settings.set_value("audio", "sfx_enabled", sfx_enabled)
	settings.set_value("audio", "music_volume", music_volume)
	settings.set_value("audio", "sfx_volume", sfx_volume)
	settings.save(SETTINGS_PATH)
