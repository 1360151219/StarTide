class_name VictoryConfig
extends Resource

const SURVIVE_DURATION := "survive_duration"
const DEFEAT_ELITE := "defeat_elite"
const SURVIVE_AND_DEFEAT_ELITE := "survive_and_defeat_elite"
const DEFEAT_BOSS := "defeat_boss"

@export_enum("survive_duration", "defeat_elite", "survive_and_defeat_elite", "defeat_boss") var mode := SURVIVE_DURATION
@export var perfect_requires_elite := true
@export var normal_heading := "星门已开启"
@export var perfect_heading := "完美远征"
@export var failure_heading := "远征中断"


func is_victory(elapsed: float, duration: float, elite_defeated: bool, boss_defeated := false) -> bool:
	if mode == DEFEAT_BOSS:
		return boss_defeated
	if mode == DEFEAT_ELITE:
		return elite_defeated
	if mode == SURVIVE_AND_DEFEAT_ELITE:
		return elapsed >= duration and elite_defeated
	return elapsed >= duration


func is_timeout_failure(elapsed: float, duration: float, elite_defeated: bool, boss_defeated := false) -> bool:
	return elapsed >= duration and not is_victory(elapsed, duration, elite_defeated, boss_defeated)


func is_perfect(elite_defeated: bool) -> bool:
	return perfect_requires_elite and elite_defeated


func validation_errors(elite_enabled: bool, boss_enabled := false) -> PackedStringArray:
	var errors := PackedStringArray()
	if mode not in [SURVIVE_DURATION, DEFEAT_ELITE, SURVIVE_AND_DEFEAT_ELITE, DEFEAT_BOSS]:
		errors.append("不支持的胜利条件：%s" % mode)
	if mode in [DEFEAT_ELITE, SURVIVE_AND_DEFEAT_ELITE] and not elite_enabled:
		errors.append("击败精英胜利必须配置精英事件")
	if mode == DEFEAT_BOSS and not boss_enabled:
		errors.append("击败 Boss 胜利必须配置 Boss 事件")
	return errors
