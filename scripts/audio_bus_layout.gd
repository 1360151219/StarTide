extends RefCounted

const CueCatalog = preload("res://scripts/audio_cue_catalog.gd")


static func ensure() -> void:
	_ensure_bus(CueCatalog.BUS_MUSIC, &"Master")
	_ensure_bus(CueCatalog.BUS_SFX, &"Master")
	_ensure_bus(CueCatalog.BUS_UI, CueCatalog.BUS_SFX)
	_ensure_bus(CueCatalog.BUS_COMBAT, CueCatalog.BUS_SFX)
	_ensure_bus(CueCatalog.BUS_ALERT, CueCatalog.BUS_SFX)
	_ensure_bus(CueCatalog.BUS_AMBIENCE, CueCatalog.BUS_SFX)
	var master_index := AudioServer.get_bus_index(&"Master")
	var has_limiter := false
	if master_index >= 0:
		for effect_index in range(AudioServer.get_bus_effect_count(master_index)):
			has_limiter = has_limiter or AudioServer.get_bus_effect(master_index, effect_index) is AudioEffectLimiter
	if master_index >= 0 and not has_limiter:
		var limiter := AudioEffectLimiter.new()
		limiter.ceiling_db = -1.0
		AudioServer.add_bus_effect(master_index, limiter)


static func _ensure_bus(bus_name: StringName, send: StringName) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, send)
