extends RefCounted

const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUS_UI := &"UI"
const BUS_COMBAT := &"Combat"
const BUS_ALERT := &"Alert"
const BUS_AMBIENCE := &"Ambience"

const MUSIC := {
	"lobby": preload("res://assets/audio/bgm_lobby.wav"),
	"level_01": preload("res://assets/audio/bgm_windbell.wav"),
	"level_02": preload("res://assets/audio/bgm_oasis.wav"),
	"level_03": preload("res://assets/audio/bgm_volcano.wav"),
}

const CUES := {
	"ui_select": {"stream": preload("res://assets/audio/ui_select.wav"), "bus": BUS_UI, "priority": 70, "cooldown": 0.025, "max_instances": 2},
	"ui_confirm": {"stream": preload("res://assets/audio/ui_confirm.wav"), "bus": BUS_UI, "priority": 82, "cooldown": 0.04, "max_instances": 2},
	"ui_navigate": {"stream": preload("res://assets/audio/ui_navigate.wav"), "bus": BUS_UI, "priority": 64, "cooldown": 0.06, "max_instances": 1},
	"ui_open": {"stream": preload("res://assets/audio/ui_open.wav"), "bus": BUS_UI, "priority": 72, "cooldown": 0.08, "max_instances": 1},
	"ui_back": {"stream": preload("res://assets/audio/ui_back.wav"), "bus": BUS_UI, "priority": 72, "cooldown": 0.08, "max_instances": 1},
	"ui_locked": {"stream": preload("res://assets/audio/ui_locked.wav"), "bus": BUS_UI, "priority": 84, "cooldown": 0.16, "max_instances": 1},
	"ui_equip": {"stream": preload("res://assets/audio/ui_equip.wav"), "bus": BUS_UI, "priority": 78, "cooldown": 0.08, "max_instances": 1},
	"ui_upgrade_skill": {"stream": preload("res://assets/audio/ui_upgrade_skill.wav"), "bus": BUS_UI, "priority": 82, "cooldown": 0.12, "max_instances": 1},
	"upgrade": {"stream": preload("res://assets/audio/upgrade.wav"), "bus": BUS_UI, "priority": 86, "cooldown": 0.2, "max_instances": 1},
	"pickup": {"stream": preload("res://assets/audio/pickup.wav"), "bus": BUS_COMBAT, "priority": 42, "cooldown": 0.06, "max_instances": 2},
	"pickup_xp": {"stream": preload("res://assets/audio/pickup_xp.wav"), "bus": BUS_COMBAT, "priority": 40, "cooldown": 0.055, "max_instances": 2},
	"pickup_heal": {"stream": preload("res://assets/audio/pickup_heal.wav"), "bus": BUS_COMBAT, "priority": 68, "cooldown": 0.12, "max_instances": 1},
	"pickup_magnet": {"stream": preload("res://assets/audio/pickup_magnet.wav"), "bus": BUS_COMBAT, "priority": 62, "cooldown": 0.16, "max_instances": 1},
	"pickup_haste": {"stream": preload("res://assets/audio/pickup_haste.wav"), "bus": BUS_COMBAT, "priority": 62, "cooldown": 0.16, "max_instances": 1},
	"pickup_bomb": {"stream": preload("res://assets/audio/pickup_bomb.wav"), "bus": BUS_COMBAT, "priority": 76, "cooldown": 0.18, "max_instances": 1},
	"hero_hurt": {"stream": preload("res://assets/audio/hero_hurt.wav"), "bus": BUS_COMBAT, "priority": 92, "cooldown": 0.09, "max_instances": 1},
	"enemy_defeat": {"stream": preload("res://assets/audio/enemy_defeat.wav"), "bus": BUS_COMBAT, "priority": 48, "cooldown": 0.055, "max_instances": 3},
	"impact": {"stream": preload("res://assets/audio/impact.wav"), "bus": BUS_COMBAT, "priority": 24, "cooldown": 0.07, "max_instances": 4},
	"enemy_warning": {"stream": preload("res://assets/audio/enemy_warning.wav"), "bus": BUS_ALERT, "priority": 100, "cooldown": 0.28, "max_instances": 2},
	"grub_roll_charge": {"stream": preload("res://assets/audio/grub_roll_charge.wav"), "bus": BUS_COMBAT, "priority": 72, "cooldown": 0.28, "max_instances": 2},
	"grub_roll_move": {"stream": preload("res://assets/audio/grub_roll_move.wav"), "bus": BUS_COMBAT, "priority": 78, "cooldown": 0.2, "max_instances": 2},
	"grub_roll_miss": {"stream": preload("res://assets/audio/grub_roll_miss.wav"), "bus": BUS_COMBAT, "priority": 72, "cooldown": 0.22, "max_instances": 2},
	"bat_bolt_charge": {"stream": preload("res://assets/audio/bat_bolt_charge.wav"), "bus": BUS_COMBAT, "priority": 74, "cooldown": 0.28, "max_instances": 2},
	"bat_bolt_launch": {"stream": preload("res://assets/audio/bat_bolt_launch.wav"), "bus": BUS_COMBAT, "priority": 80, "cooldown": 0.16, "max_instances": 3},
	"bat_bolt_impact": {"stream": preload("res://assets/audio/bat_bolt_impact.wav"), "bus": BUS_COMBAT, "priority": 82, "cooldown": 0.12, "max_instances": 3},
	"stage_transition": {"stream": preload("res://assets/audio/stage_transition.wav"), "bus": BUS_ALERT, "priority": 94, "cooldown": 0.6, "max_instances": 1},
	"elite_appear": {"stream": preload("res://assets/audio/elite_appear.wav"), "bus": BUS_ALERT, "priority": 98, "cooldown": 0.8, "max_instances": 1},
	"elite_defeat": {"stream": preload("res://assets/audio/elite_defeat.wav"), "bus": BUS_ALERT, "priority": 98, "cooldown": 0.8, "max_instances": 1},
	"result_victory": {"stream": preload("res://assets/audio/result_victory.wav"), "bus": BUS_ALERT, "priority": 100, "cooldown": 1.0, "max_instances": 1},
	"result_failure": {"stream": preload("res://assets/audio/result_failure.wav"), "bus": BUS_ALERT, "priority": 100, "cooldown": 1.0, "max_instances": 1},
	"skill_star_lance": {"stream": preload("res://assets/audio/skill_star_lance.wav"), "bus": BUS_COMBAT, "priority": 60, "cooldown": 0.18, "max_instances": 2},
	"skill_sun_orbit": {"stream": preload("res://assets/audio/skill_sun_orbit.wav"), "bus": BUS_COMBAT, "priority": 46, "cooldown": 0.12, "max_instances": 2},
	"skill_frost_tide": {"stream": preload("res://assets/audio/skill_frost_tide.wav"), "bus": BUS_COMBAT, "priority": 68, "cooldown": 0.18, "max_instances": 1},
	"frost_hit": {"stream": preload("res://assets/audio/frost_hit.wav"), "bus": BUS_COMBAT, "priority": 44, "cooldown": 0.055, "max_instances": 3},
	"skill_ember_volley": {"stream": preload("res://assets/audio/skill_ember_volley.wav"), "bus": BUS_COMBAT, "priority": 60, "cooldown": 0.18, "max_instances": 2},
	"skill_meteor_rain": {"stream": preload("res://assets/audio/skill_meteor_rain.wav"), "bus": BUS_COMBAT, "priority": 72, "cooldown": 0.35, "max_instances": 1},
	"meteor_impact": {"stream": preload("res://assets/audio/meteor_impact.wav"), "bus": BUS_COMBAT, "priority": 84, "cooldown": 0.08, "max_instances": 3},
	"skill_phoenix_heart": {"stream": preload("res://assets/audio/skill_phoenix_heart.wav"), "bus": BUS_COMBAT, "priority": 72, "cooldown": 0.3, "max_instances": 1},
	"phoenix_impact": {"stream": preload("res://assets/audio/phoenix_impact.wav"), "bus": BUS_COMBAT, "priority": 82, "cooldown": 0.22, "max_instances": 1},
}


static func cue(cue_id: String) -> Dictionary:
	return CUES.get(cue_id, {})


static func music(profile_id := "lobby") -> AudioStream:
	return MUSIC.get(profile_id, MUSIC["lobby"])


static func ids() -> PackedStringArray:
	return PackedStringArray(CUES.keys())


static func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	for profile_id in ["lobby", "level_01", "level_02", "level_03"]:
		if MUSIC.get(profile_id) == null:
			errors.append("音乐配置 %s 缺少资源" % profile_id)
	for cue_id in CUES:
		var data: Dictionary = CUES[cue_id]
		if data.get("stream") == null:
			errors.append("音频 Cue %s 缺少资源" % cue_id)
		if StringName(data.get("bus", &"")) not in [BUS_UI, BUS_COMBAT, BUS_ALERT, BUS_AMBIENCE]:
			errors.append("音频 Cue %s 使用了未知总线" % cue_id)
		if int(data.get("priority", -1)) < 0 or int(data.get("max_instances", 0)) <= 0:
			errors.append("音频 Cue %s 的优先级或并发配置无效" % cue_id)
	return errors
