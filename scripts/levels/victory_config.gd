class_name VictoryConfig
extends Resource

const SURVIVE_DURATION := "survive_duration"
const DEFEAT_ELITE := "defeat_elite"
const SURVIVE_AND_DEFEAT_ELITE := "survive_and_defeat_elite"

@export_enum("survive_duration", "defeat_elite", "survive_and_defeat_elite") var mode := SURVIVE_DURATION
@export var perfect_requires_elite := true
@export var normal_heading := "星门已开启"
@export var perfect_heading := "完美远征"
@export var failure_heading := "远征中断"


func is_victory(elapsed: float, duration: float, elite_defeated: bool) -> bool:
	if mode == DEFEAT_ELITE:
		return elite_defeated
	if mode == SURVIVE_AND_DEFEAT_ELITE:
		return elapsed >= duration and elite_defeated
	return elapsed >= duration


func is_timeout_failure(elapsed: float, duration: float, elite_defeated: bool) -> bool:
	return elapsed >= duration and not is_victory(elapsed, duration, elite_defeated)


func is_perfect(elite_defeated: bool) -> bool:
	return perfect_requires_elite and elite_defeated


func validation_errors(elite_enabled: bool) -> PackedStringArray:
	var errors := PackedStringArray()
	if mode != SURVIVE_DURATION and mode != DEFEAT_ELITE and mode != SURVIVE_AND_DEFEAT_ELITE:
		errors.append("不支持的胜利条件：%s" % mode)
	if mode != SURVIVE_DURATION and not elite_enabled:
		errors.append("击败精英胜利必须配置精英事件")
	return errors
