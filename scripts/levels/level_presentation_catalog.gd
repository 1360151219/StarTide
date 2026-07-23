extends RefCounted

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const MANIFEST: LevelPresentationManifest = preload("res://levels/level_presentations.tres")


static func all() -> Array[LevelPresentationConfig]:
	return MANIFEST.all()


static func by_id(level_id: String) -> LevelPresentationConfig:
	return MANIFEST.by_id(level_id)


static func validation_errors(valid_level_ids: PackedStringArray) -> PackedStringArray:
	return MANIFEST.validation_errors(valid_level_ids, EnemyCatalog.ids())
