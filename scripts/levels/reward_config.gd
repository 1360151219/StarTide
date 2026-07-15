class_name RewardConfig
extends Resource

@export var reward_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var unlock_level_id := ""


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if reward_id.is_empty():
		errors.append("reward_id 不能为空")
	if display_name.is_empty():
		errors.append("奖励名称不能为空")
	return errors
