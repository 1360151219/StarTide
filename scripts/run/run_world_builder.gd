extends RefCounted

const PlayerEntity = preload("res://scripts/player.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const EnemySystem = preload("res://scripts/systems/enemy_system.gd")
const ProjectileSystem = preload("res://scripts/systems/projectile_system.gd")
const PickupSystem = preload("res://scripts/systems/pickup_system.gd")
const UpgradeSystem = preload("res://scripts/systems/upgrade_system.gd")
const PassiveController = preload("res://scripts/passives/passive_controller.gd")
const SkillController = preload("res://scripts/skills/skill_controller.gd")
const WorldRenderer = preload("res://scripts/presentation/world_renderer.gd")


func build(parent: Node2D, state: RefCounted, level: LevelConfig, stage_director: RefCounted, audio: Node, effects: Node2D, random_streams: Dictionary) -> Dictionary:
	var world := WorldRenderer.new()
	world.z_index = -100
	world.configure(level.map)
	parent.add_child(world)
	var player := PlayerEntity.new()
	player.position = level.map.player_start
	player.configure(state.hero_id, HeroCatalog.hero(state.hero_id), level.map)
	player.z_index = level.map.depth_index(player.position.y)
	parent.add_child(player)
	var camera := _create_camera(player, level.map)
	var enemies := EnemySystem.new()
	parent.add_child(enemies)
	enemies.configure(level, state, player, stage_director, random_streams["spawn"], effects, audio)
	var projectiles := ProjectileSystem.new()
	projectiles.z_index = 3900
	parent.add_child(projectiles)
	projectiles.configure(enemies, effects, audio, random_streams["skill"])
	var pickups := PickupSystem.new()
	parent.add_child(pickups)
	pickups.configure(level, state, player, random_streams["loot"], audio)
	var skills := SkillController.new()
	skills.z_index = 3850
	parent.add_child(skills)
	skills.configure(state.hero_id, player, enemies, projectiles, effects, audio, random_streams["skill"])
	var passives := PassiveController.new()
	passives.configure(state.hero_id, player, effects, audio)
	return {
		"world": world, "player": player, "camera": camera, "enemies": enemies,
		"projectiles": projectiles, "pickups": pickups, "skills": skills,
		"passives": passives, "upgrades": UpgradeSystem.new(random_streams["upgrade"]),
	}


func _create_camera(player: Node2D, map: MapConfig) -> Camera2D:
	var camera := Camera2D.new()
	camera.limit_left = roundi(map.world_bounds.position.x)
	camera.limit_top = roundi(map.world_bounds.position.y)
	camera.limit_right = roundi(map.world_bounds.end.x)
	camera.limit_bottom = roundi(map.world_bounds.end.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.enabled = true
	player.add_child(camera)
	return camera
