extends RefCounted

const EXPERIENCE_BASE := 36
const EXPERIENCE_STEP := 28
const END_COMPLETED := "completed"
const END_DEFEATED := "defeated"
const END_OBJECTIVE_TIMEOUT := "objective_timeout"

var hero_id := "star_warden"
var level_id := "level_01"
var elapsed := 0.0
var kills := 0
var player_level := 1
var experience := 0
var experience_needed := EXPERIENCE_BASE
var pending_upgrades := 0
var paused := false
var finished := false
var victory := false
var end_reason := ""
var elite_spawned := false
var elite_defeated := false
var boss_spawned := false
var boss_defeated := false


func reset(selected_hero_id: String, selected_level_id: String) -> void:
	hero_id = selected_hero_id
	level_id = selected_level_id
	elapsed = 0.0
	kills = 0
	player_level = 1
	experience = 0
	experience_needed = EXPERIENCE_BASE
	pending_upgrades = 0
	paused = false
	finished = false
	victory = false
	end_reason = ""
	elite_spawned = false
	elite_defeated = false
	boss_spawned = false
	boss_defeated = false


func add_experience(amount: int) -> int:
	experience += amount
	var levels_gained := 0
	while experience >= experience_needed:
		experience -= experience_needed
		player_level += 1
		experience_needed = EXPERIENCE_BASE + (player_level - 1) * EXPERIENCE_STEP
		levels_gained += 1
	pending_upgrades += levels_gained
	return levels_gained
