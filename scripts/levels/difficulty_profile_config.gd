class_name DifficultyProfileConfig
extends Resource

@export var profile_id := ""
@export var display_name := ""
@export var pressure_curve := PackedFloat32Array([1.0])
@export var recommended_power_curve := PackedInt32Array([1000])
@export_range(0.0, 0.5, 0.01) var pressure_tolerance := 0.08


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if profile_id.is_empty():
		errors.append("难度曲线 ID 不能为空")
	if display_name.is_empty():
		errors.append("难度曲线名称不能为空")
	if pressure_curve.is_empty() or pressure_curve.size() != recommended_power_curve.size():
		errors.append("压力曲线与推荐战力曲线长度必须相同且非空")
	for index in range(pressure_curve.size()):
		if pressure_curve[index] <= 0.0 or recommended_power_curve[index] <= 0:
			errors.append("难度曲线第 %d 阶必须大于 0" % (index + 1))
		if index > 0 and pressure_curve[index] <= pressure_curve[index - 1]:
			errors.append("压力曲线必须严格递增")
		if index > 0 and recommended_power_curve[index] < recommended_power_curve[index - 1]:
			errors.append("推荐战力曲线不能下降")
	return errors


func pressure_target(step: int) -> float:
	return pressure_curve[clampi(step, 0, pressure_curve.size() - 1)]


func power_target(step: int) -> int:
	return recommended_power_curve[clampi(step, 0, recommended_power_curve.size() - 1)]
