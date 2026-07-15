class_name EliteConfig
extends Resource

@export var enabled := true
@export var spawn_time := 60.0
@export var enemy_id := "brute"
@export var display_name := "陨岩执政官"
@export var health_multiplier := 2.4
@export var speed_multiplier := 0.92
@export var damage_multiplier := 1.35
@export var radius_multiplier := 1.25
@export var visual_scale := 1.25
@export var experience := 36
@export var bonus_upgrade_count := 1
@export var magnet_duration := 6.0


func validation_errors(duration: float, valid_enemy_ids: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	if not enabled:
		return errors
	if spawn_time <= 0.0 or spawn_time >= duration:
		errors.append("精英出现时间必须位于关卡时长内")
	if not valid_enemy_ids.has(enemy_id):
		errors.append("精英怪物类型无效：%s" % enemy_id)
	if display_name.is_empty():
		errors.append("精英名称不能为空")
	if health_multiplier <= 0.0 or speed_multiplier <= 0.0 or damage_multiplier <= 0.0:
		errors.append("精英属性倍率必须大于 0")
	if radius_multiplier <= 0.0 or visual_scale <= 0.0:
		errors.append("精英视觉倍率必须大于 0")
	if experience < 0 or bonus_upgrade_count < 0 or magnet_duration < 0.0:
		errors.append("精英奖励不能为负数")
	return errors
