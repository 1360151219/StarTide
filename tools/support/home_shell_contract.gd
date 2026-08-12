extends RefCounted


static func snapshot(screen: CanvasLayer) -> Array[int]:
	var instances: Array[int] = [
		screen.lobby_view.get_instance_id(),
		screen.screen_background.get_instance_id(),
		screen.route_map.get_instance_id(),
		screen.route_map.scene_texture.get_instance_id(),
		screen.route_map.map_frame.get_instance_id(),
		screen.route_map.preview_hero.get_instance_id(),
		screen.route_map.expedition_brief.get_instance_id(),
	]
	for pin in screen.route_map.route_pins:
		instances.append(pin.get_instance_id())
	instances.append(screen.start_button.get_instance_id())
	instances.append(screen.bottom_bar.get_instance_id())
	instances.append(screen.lobby_view.get_child_count())
	return instances
