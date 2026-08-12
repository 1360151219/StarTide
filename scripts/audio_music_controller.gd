extends Node

signal players_swapped(active: AudioStreamPlayer, standby: AudioStreamPlayer)

const CueCatalog = preload("res://scripts/audio_cue_catalog.gd")

var active: AudioStreamPlayer
var standby: AudioStreamPlayer
var transition: Tween


func configure() -> void:
	active = _create_player()
	standby = _create_player()


func play(stream: AudioStream) -> void:
	if active.playing and active.stream == stream:
		return
	_stop_transition()
	active.stop()
	standby.stop()
	_prepare_loop(stream)
	active.stream = stream
	active.volume_db = 0.0
	active.play()


func crossfade(stream: AudioStream, duration: float) -> void:
	if active.playing and active.stream == stream:
		return
	_prepare_loop(stream)
	_stop_transition()
	standby.stop()
	standby.stream = stream
	standby.volume_db = -40.0
	standby.play()
	var fade_duration := maxf(duration, 0.05)
	transition = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.parallel().tween_property(active, "volume_db", -40.0, fade_duration)
	transition.parallel().tween_property(standby, "volume_db", 0.0, fade_duration)
	transition.tween_callback(_finish_crossfade)


func stop_all() -> void:
	_stop_transition()
	for player in [active, standby]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null


func _finish_crossfade() -> void:
	active.stop()
	active.stream = null
	active.volume_db = 0.0
	var previous := active
	active = standby
	standby = previous
	players_swapped.emit(active, standby)


func _stop_transition() -> void:
	if transition != null and transition.is_valid():
		transition.kill()


func _create_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = CueCatalog.BUS_MUSIC
	add_child(player)
	return player


func _prepare_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
