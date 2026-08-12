extends RefCounted

const EXPERIENCE_REQUIREMENTS := [24, 48, 76, 108, 144, 184, 220, 248, 280]
const EXPERIENCE_LATE_STEP := 28
const END_COMPLETED := "completed"
const END_DEFEATED := "defeated"

var hero_id := "star_warden"
var level_id := "level_01"
var elapsed := 0.0
var kills := 0
var player_level := 1
var experience := 0
var experience_needed := int(EXPERIENCE_REQUIREMENTS[0])
var pending_upgrades := 0
var paused := false
var finished := false
var victory := false
var end_reason := ""
var elite_spawned := false
var elite_defeated := false
var elite_spawned_at := -1.0
var elite_defeated_at := -1.0
var boss_spawned := false
var boss_defeated := false


func reset(selected_hero_id: String, selected_level_id: String) -> void:
	hero_id = selected_hero_id
	level_id = selected_level_id
	elapsed = 0.0
	kills = 0
	player_level = 1
	experience = 0
	experience_needed = experience_required_for_level(1)
	pending_upgrades = 0
	paused = false
	finished = false
	victory = false
	end_reason = ""
	elite_spawned = false
	elite_defeated = false
	elite_spawned_at = -1.0
	elite_defeated_at = -1.0
	boss_spawned = false
	boss_defeated = false


func objective_elapsed() -> float:
	if elite_spawned_at < 0.0:
		return elapsed
	var pause_end := elite_defeated_at if elite_defeated_at >= 0.0 else elapsed
	return elapsed - maxf(0.0, pause_end - elite_spawned_at)


func add_experience(amount: int) -> int:
	experience += amount
	var levels_gained := 0
	while experience >= experience_needed:
		experience -= experience_needed
		player_level += 1
		experience_needed = experience_required_for_level(player_level)
		levels_gained += 1
	pending_upgrades += levels_gained
	return levels_gained


static func experience_required_for_level(current_level: int) -> int:
	var index := maxi(0, current_level - 1)
	if index < EXPERIENCE_REQUIREMENTS.size():
		return int(EXPERIENCE_REQUIREMENTS[index])
	return int(EXPERIENCE_REQUIREMENTS[-1]) + (index - EXPERIENCE_REQUIREMENTS.size() + 1) * EXPERIENCE_LATE_STEP
