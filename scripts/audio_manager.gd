extends Node

signal settings_changed

const STREAMS := {
	"bgm": preload("res://assets/audio/bgm_starbound.wav"),
	"ui_select": preload("res://assets/audio/ui_select.wav"),
	"ui_confirm": preload("res://assets/audio/ui_confirm.wav"),
	"upgrade": preload("res://assets/audio/upgrade.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"hero_hurt": preload("res://assets/audio/hero_hurt.wav"),
	"enemy_defeat": preload("res://assets/audio/enemy_defeat.wav"),
	"impact": preload("res://assets/audio/impact.wav"),
	"skill_star_lance": preload("res://assets/audio/skill_star_lance.wav"),
	"skill_sun_orbit": preload("res://assets/audio/skill_sun_orbit.wav"),
	"skill_frost_tide": preload("res://assets/audio/skill_frost_tide.wav"),
	"skill_ember_volley": preload("res://assets/audio/skill_ember_volley.wav"),
	"skill_meteor_rain": preload("res://assets/audio/skill_meteor_rain.wav"),
	"skill_phoenix_heart": preload("res://assets/audio/skill_phoenix_heart.wav"),
}

const SFX_COOLDOWNS := {
	"impact": 0.07,
	"enemy_defeat": 0.055,
	"pickup": 0.06,
	"skill_star_lance": 0.18,
	"skill_ember_volley": 0.18,
}

const SETTINGS_PATH := "user://audio_settings.cfg"
const MUSIC_BASE_DB := -9.0
const SFX_BASE_DB := -4.0

var music_enabled := true
var sfx_enabled := true
var music_volume := 0.65
var sfx_volume := 0.75
var audio_output_available := true
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var save_timer: Timer
var cooldowns: Dictionary = {}
var next_player_index := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	audio_output_available = DisplayServer.get_name() != "headless"
	_load_settings()
	save_timer = Timer.new()
	save_timer.one_shot = true
	save_timer.wait_time = 0.35
	save_timer.timeout.connect(_save_settings)
	add_child(save_timer)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	for index in range(12):
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)
	_apply_music_volume()
	play_music()


func _process(delta: float) -> void:
	for sound_id in cooldowns.keys():
		cooldowns[sound_id] = maxf(0.0, cooldowns[sound_id] - delta)


func _exit_tree() -> void:
	if is_instance_valid(save_timer):
		save_timer.stop()
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	for player in sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	cooldowns.clear()


func play_music() -> void:
	if not audio_output_available or not music_enabled or music_player.playing:
		return
	var stream: AudioStreamWAV = STREAMS["bgm"]
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	music_player.stream = stream
	music_player.play()


func play_sfx(sound_id: String, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if not audio_output_available or not sfx_enabled or not STREAMS.has(sound_id) or cooldowns.get(sound_id, 0.0) > 0.0:
		return
	var player := sfx_players[next_player_index]
	next_player_index = (next_player_index + 1) % sfx_players.size()
	player.stop()
	player.stream = STREAMS[sound_id]
	player.set_meta("event_volume_db", volume_db)
	player.volume_db = _volume_db(sfx_volume, SFX_BASE_DB) + volume_db
	player.pitch_scale = pitch_scale
	player.play()
	cooldowns[sound_id] = SFX_COOLDOWNS.get(sound_id, 0.025)


func toggle_music() -> bool:
	music_enabled = not music_enabled
	if music_enabled:
		play_music()
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
	for player in sfx_players:
		if player.playing:
			player.volume_db = _volume_db(sfx_volume, SFX_BASE_DB) + float(player.get_meta("event_volume_db", 0.0))
	if save:
		_schedule_save()
	settings_changed.emit()


func _apply_music_volume() -> void:
	if is_instance_valid(music_player):
		music_player.volume_db = _volume_db(music_volume, MUSIC_BASE_DB)


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
