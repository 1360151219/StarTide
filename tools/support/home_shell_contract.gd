extends RefCounted


static func snapshot(screen: CanvasLayer) -> Array[int]:
	return [
		screen.lobby_view.get_instance_id(),
		screen.screen_background.get_instance_id(),
		screen.title_label.get_instance_id(),
		screen.subtitle_label.get_instance_id(),
		screen.level_preview.get_instance_id(),
		screen.level_preview.scene_texture.get_instance_id(),
		screen.level_preview.portal_frame.get_instance_id(),
		screen.level_preview.preview_hero.get_instance_id(),
		screen.level_selector.get_instance_id(),
		screen.level_selector.expedition_brief.get_instance_id(),
		screen.start_button.get_instance_id(),
		screen.bottom_bar.get_instance_id(),
		screen.lobby_view.get_child_count(),
	]
