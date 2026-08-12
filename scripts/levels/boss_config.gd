class_name BossConfig
extends Resource

@export var enabled := true
@export var boss_id := ""
@export var display_name := ""
@export_range(0.05, 0.95, 0.01) var spawn_progress := 0.5
@export var health := 6000.0
@export var speed := 72.0
@export var contact_damage := 10.0
@export var collision_radius := 52.0
@export var visual_scale := 2.2
@export var phase_thresholds := PackedFloat32Array([0.66, 0.33])
@export var skill_ids := PackedStringArray()
@export_range(0, 32, 1) var initial_minion_limit := 6
@export_range(0, 32, 1) var minion_limit := 8
@export var music_profile_id := ""
@export_range(0.0, 2.0, 0.05) var music_crossfade_duration := 0.45


func spawn_time(duration: float) -> float:
	return duration * spawn_progress


func phase_for_health(health_ratio: float) -> int:
	if health_ratio > phase_thresholds[0]:
		return 1
	if health_ratio > phase_thresholds[1]:
		return 2
	return 3


func skill_interval(phase: int) -> float:
	match phase:
		1:
			return 1.2
		2:
			return 1.05
		_:
			return 0.9


func validation_errors(duration: float, valid_enemy_ids: PackedStringArray, valid_ability_ids: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	if not enabled:
		return errors
	if not valid_enemy_ids.has(boss_id):
		errors.append("Boss 类型无效：%s" % boss_id)
	if display_name.is_empty():
		errors.append("Boss 名称不能为空")
	if spawn_time(duration) <= 0.0 or spawn_time(duration) >= duration:
		errors.append("Boss 出现时间必须位于关卡时长内")
	if health <= 0.0 or speed <= 0.0 or contact_damage <= 0.0:
		errors.append("Boss 基础属性必须大于 0")
	if collision_radius <= 0.0 or visual_scale <= 0.0:
		errors.append("Boss 碰撞与视觉体量必须大于 0")
	if phase_thresholds.size() != 2 or phase_thresholds[0] <= phase_thresholds[1] or phase_thresholds[0] >= 1.0 or phase_thresholds[1] <= 0.0:
		errors.append("Boss 阶段阈值必须为递减的两个百分比")
	if skill_ids.size() < 2:
		errors.append("Boss 至少需要两个技能")
	for skill_id in skill_ids:
		if not valid_ability_ids.has(skill_id):
			errors.append("Boss 技能无效：%s" % skill_id)
	if initial_minion_limit > minion_limit:
		errors.append("Boss 登场时随从上限不能高于战中上限")
	if music_profile_id.is_empty():
		errors.append("Boss 音乐配置不能为空")
	return errors
