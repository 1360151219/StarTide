extends SceneTree

const MAX_SCRIPT_LINES := 250

var failed := false


func _initialize() -> void:
	_check_directory("res://scripts")
	_check_directory("res://tools")
	_check_composition_root()
	if not failed:
		print("ARCHITECTURE_OK max_lines=%d config_isolated=true composition_clean=true" % MAX_SCRIPT_LINES)
	quit(1 if failed else 0)


func _check_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		_fail("无法读取目录：%s" % path)
		return
	for file_name in directory.get_files():
		if file_name.ends_with(".gd"):
			_check_file(path.path_join(file_name))
	for child_directory in directory.get_directories():
		_check_directory(path.path_join(child_directory))


func _check_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("无法读取脚本：%s" % path)
		return
	var source := file.get_as_text()
	var lines := source.count("\n") + 1
	if lines > MAX_SCRIPT_LINES:
		_fail("%s 有 %d 行，超过 %d 行上限" % [path, lines, MAX_SCRIPT_LINES])
	if path.contains("/levels/"):
		_check_level_dependencies(path, source)


func _check_level_dependencies(path: String, source: String) -> void:
	for line in source.split("\n"):
		if not line.contains("res://scripts/"):
			continue
		if line.contains("res://scripts/levels/") or line.contains("res://scripts/enemy_catalog.gd"):
			continue
		_fail("配置层依赖了非数据模块：%s -> %s" % [path, line.strip_edges()])


func _check_composition_root() -> void:
	var path := "res://scripts/game.gd"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("无法读取组合根：%s" % path)
		return
	var source := file.get_as_text()
	for forbidden in [
		"res://scripts/systems/", "res://scripts/skills/", "res://scripts/passives/",
		"StageConfig", "EliteConfig", "EnemySpawner", "spawn_interval", "enemy_weights",
		"health_multiplier", "damage_multiplier", "spawn_enemy", "damage_enemy",
	]:
		if source.contains(forbidden):
			_fail("组合根越过编排边界：%s" % forbidden)


func _fail(message: String) -> void:
	failed = true
	push_error("ARCHITECTURE_FAILED: " + message)
