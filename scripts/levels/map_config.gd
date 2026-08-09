class_name MapConfig
extends Resource

@export var map_id := ""
@export var display_name := ""
@export var biome_id := "windbell_meadow"
@export var floor_texture: Texture2D
@export var world_bounds := Rect2(-1600.0, -1600.0, 3200.0, 3200.0)
@export var player_start := Vector2.ZERO
@export var spawn_distance_min := 570.0
@export var spawn_distance_max := 690.0
@export var elite_spawn_distance_min := 500.0
@export var elite_spawn_distance_max := 560.0
@export var background_color := Color("09132c")
@export var floor_tint := Color(0.82, 0.87, 1.0, 0.92)
@export var border_color := Color(0.76, 0.62, 0.3, 0.6)
@export var glow_color := Color(0.18, 0.72, 0.82, 0.025)
@export_range(0.4, 1.0, 0.01) var scene_saturation := 0.72
@export_range(0.6, 1.1, 0.01) var scene_exposure := 0.92
@export_range(48, 96, 8) var decoration_count := 72
@export var environment_particle_color := Color(1.0, 0.98, 0.74, 0.68)


func depth_index(world_y: float) -> int:
	var progress := inverse_lerp(world_bounds.position.y, world_bounds.end.y, world_y)
	return clampi(roundi(lerpf(1.0, 3800.0, progress)), 1, 3800)


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if map_id.is_empty():
		errors.append("map_id 不能为空")
	if display_name.is_empty():
		errors.append("地图名称不能为空")
	if biome_id.is_empty():
		errors.append("地图生态 ID 不能为空")
	if floor_texture == null:
		errors.append("地图贴图不能为空")
	if world_bounds.size.x <= 0.0 or world_bounds.size.y <= 0.0:
		errors.append("地图边界必须为正数")
	var spawn_area_size := world_bounds.size - Vector2(60.0, 60.0)
	if spawn_area_size.x <= 0.0 or spawn_area_size.y <= 0.0:
		errors.append("地图必须为刷怪安全边距预留至少 60 像素")
	elif maxf(spawn_distance_min, elite_spawn_distance_min) > spawn_area_size.length() * 0.5:
		errors.append("地图尺寸无法保证最小刷怪距离")
	if not world_bounds.has_point(player_start):
		errors.append("玩家出生点必须位于地图边界内")
	if spawn_distance_min <= 0.0 or spawn_distance_max < spawn_distance_min:
		errors.append("普通刷怪距离配置无效")
	if elite_spawn_distance_min <= 0.0 or elite_spawn_distance_max < elite_spawn_distance_min:
		errors.append("精英刷怪距离配置无效")
	return errors
