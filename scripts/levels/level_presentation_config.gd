class_name LevelPresentationConfig
extends Resource

@export var level_id := ""
@export var preview_texture: Texture2D
@export var preview_region := Rect2()
@export var featured_enemy_ids := PackedStringArray()
@export var preview_tint := Color.WHITE


func validation_errors(valid_level_ids: PackedStringArray, valid_enemy_ids: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	if level_id.is_empty():
		errors.append("level_id 不能为空")
	elif not valid_level_ids.has(level_id):
		errors.append("引用了不存在的关卡：%s" % level_id)
	if preview_texture == null:
		errors.append("动态预览图不能为空")
	if featured_enemy_ids.is_empty():
		errors.append("至少需要一个预览怪物")
	var seen_enemy_ids: Dictionary = {}
	for enemy_id in featured_enemy_ids:
		if seen_enemy_ids.has(enemy_id):
			errors.append("预览怪物重复：%s" % enemy_id)
		elif not valid_enemy_ids.has(enemy_id):
			errors.append("预览引用了不存在的怪物：%s" % enemy_id)
		seen_enemy_ids[enemy_id] = true
	return errors
