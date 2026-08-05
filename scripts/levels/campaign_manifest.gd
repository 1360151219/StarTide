class_name CampaignManifest
extends Resource

@export var campaign_id := ""
@export var display_name := ""
@export var chapters: Array[ChapterConfig] = []
@export var difficulty_profiles: Array[DifficultyProfileConfig] = []
@export var levels: Array[LevelConfig] = []
@export var starter_equipment_reward: EquipmentRewardConfig


func profile_by_id(profile_id: String) -> DifficultyProfileConfig:
	for profile in difficulty_profiles:
		if profile != null and profile.profile_id == profile_id:
			return profile
	return null


func chapter_by_id(chapter_id: String) -> ChapterConfig:
	for chapter in chapters:
		if chapter != null and chapter.chapter_id == chapter_id:
			return chapter
	return null


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if campaign_id.is_empty():
		errors.append("战役 ID 不能为空")
	if display_name.is_empty():
		errors.append("战役名称不能为空")
	if levels.is_empty():
		errors.append("战役至少需要一个关卡")
	if chapters.is_empty():
		errors.append("战役至少需要一个章节")
	if difficulty_profiles.is_empty():
		errors.append("战役至少需要一条难度曲线")
	return errors
