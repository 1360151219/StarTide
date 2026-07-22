class_name LootConfig
extends Resource

@export_range(0.0, 1.0, 0.001) var heart_drop_chance := 0.055
@export var heart_value := 22
@export_range(0, 12, 1) var max_heart_drops := 5
@export_range(0.0, 1.0, 0.001) var magnet_drop_chance := 0.035
@export var magnet_duration := 5.0
@export var normal_pickup_radius := 92.0
@export var magnet_pickup_radius := 520.0


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if heart_drop_chance + magnet_drop_chance > 1.0:
		errors.append("额外掉落概率总和不能超过 1")
	if heart_value < 0 or max_heart_drops < 0 or magnet_duration < 0.0:
		errors.append("道具效果不能为负数")
	if normal_pickup_radius <= 0.0 or magnet_pickup_radius < normal_pickup_radius:
		errors.append("拾取范围配置无效")
	return errors
