extends RefCounted

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunRecords = preload("res://scripts/run_records.gd")


static func isolate_records(game: Node) -> void:
	var records := RunRecords.new("")
	var first_level_id := LevelCatalog.first().level_id
	game.run_records = records
	game.start_screen.records = records
	game.start_screen.route_map.records = records
	game.start_screen.route_map.selected_level_id = first_level_id
	game.start_screen.selected_level_id = first_level_id
	if is_instance_valid(game.start_screen.character_page):
		game.start_screen.character_page.configure(records, records.get_active_hero_id())
	game.start_screen.select_hero(records.get_active_hero_id())
	game.start_screen.select_level(first_level_id)
	game.start_screen.refresh_progress()


static func capture(tree: SceneTree, file_name: String) -> bool:
	RenderingServer.force_draw(false)
	var image := tree.root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("CAPTURE_FAILED: 无法读取画面：%s" % file_name)
		return false
	var error := image.save_png("res://preview/" + file_name)
	if error != OK:
		push_error("CAPTURE_FAILED: 保存失败：%s (%s)" % [file_name, error_string(error)])
		return false
	return true
