extends RefCounted


static func snapshot(screen: CanvasLayer) -> Array[int]:
	return [
		screen.lobby_view.get_instance_id(),
		screen.screen_background.get_instance_id(),
		screen.route_map.get_instance_id(),
		screen.route_map.scene_texture.get_instance_id(),
		screen.route_map.map_frame.get_instance_id(),
		screen.route_map.preview_hero.get_instance_id(),
		screen.route_map.expedition_brief.get_instance_id(),
		screen.route_map.route_pins[0].get_instance_id(),
		screen.route_map.route_pins[1].get_instance_id(),
		screen.route_map.route_pins[2].get_instance_id(),
		screen.start_button.get_instance_id(),
		screen.bottom_bar.get_instance_id(),
		screen.lobby_view.get_child_count(),
	]
