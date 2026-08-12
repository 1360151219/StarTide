extends RefCounted

const Contract = preload("res://scripts/run/balance_sample_contract.gd")
const DEFAULT_PATH := Contract.DEFAULT_PLAYER_SAMPLE_PATH

var storage_path := DEFAULT_PATH


func _init(path := DEFAULT_PATH) -> void:
	storage_path = path


func append(sample: Dictionary) -> Error:
	if storage_path.is_empty():
		return ERR_UNAVAILABLE
	if not _has_valid_identity(sample) or not _matches_existing_identity(sample):
		return ERR_INVALID_DATA
	var file := FileAccess.open(storage_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.seek_end()
	file.store_line(JSON.stringify(sample))
	var error := file.get_error()
	file.close()
	return error


func _has_valid_identity(sample: Dictionary) -> bool:
	return int(sample.get("schema_version", 0)) == Contract.SCHEMA_VERSION \
		and not str(sample.get("build_id", "")).is_empty() \
		and int(sample.get("content_balance_version", 0)) > 0 \
		and not str(sample.get("sample_id", "")).is_empty()


func _matches_existing_identity(sample: Dictionary) -> bool:
	if not FileAccess.file_exists(storage_path):
		return true
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		return false
	var was_empty := file.get_length() == 0
	while file.get_position() < file.get_length():
		var parsed: Variant = JSON.parse_string(file.get_line())
		if parsed is Dictionary:
			file.close()
			return int(parsed.get("schema_version", 0)) == int(sample["schema_version"]) \
				and str(parsed.get("build_id", "")) == str(sample["build_id"]) \
				and int(parsed.get("content_balance_version", 0)) == int(sample["content_balance_version"])
	file.close()
	return was_empty


func read_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if storage_path.is_empty() or not FileAccess.file_exists(storage_path):
		return result
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		return result
	while file.get_position() < file.get_length():
		var line := file.get_line()
		if line.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary:
			result.append(parsed)
	file.close()
	return result
