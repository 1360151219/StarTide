class_name DifficultyConfig
extends Resource

@export var health_start := 1.0
@export var health_end := 1.8571429
@export var speed_start := 1.0
@export var speed_end := 1.03
@export var damage_start := 1.0
@export var damage_end := 1.0


func multipliers_at(elapsed: float, duration: float) -> Dictionary:
	var progress := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
	return {
		"health": lerpf(health_start, health_end, progress),
		"speed": lerpf(speed_start, speed_end, progress),
		"damage": lerpf(damage_start, damage_end, progress),
	}


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if health_start <= 0.0 or speed_start <= 0.0 or damage_start <= 0.0:
		errors.append("起始倍率必须大于 0")
	if health_end < health_start or speed_end < speed_start or damage_end < damage_start:
		errors.append("结束倍率不能低于起始倍率")
	return errors
