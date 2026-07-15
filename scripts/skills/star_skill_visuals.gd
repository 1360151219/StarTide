extends Node2D

const HeroCatalog = preload("res://scripts/hero_catalog.gd")

var runtime: Node
var player: Node2D
var levels: Dictionary


func configure(skill_runtime: Node, player_node: Node2D, skill_levels: Dictionary) -> void:
	runtime = skill_runtime
	player = player_node
	levels = skill_levels


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(player):
		return
	_draw_orbit()
	_draw_frost_pulse()


func _draw_orbit() -> void:
	var skill_level: int = levels.get("sun_orbit", 0)
	if skill_level <= 0:
		return
	var data: Dictionary = HeroCatalog.skill("sun_orbit")["runtime"]
	var count: int = data["count"][skill_level]
	var distance: float = data["orbit_radius"][skill_level]
	var orb_size: float = data["orb_radius"][skill_level]
	for index in range(count):
		var position: Vector2 = player.position + Vector2.from_angle(runtime.orbit_phase + index * TAU / count) * distance
		draw_circle(position, orb_size + 16.0, Color(1.0, 0.58, 0.16, 0.12))
		for ray_index in range(10):
			var direction := Vector2.from_angle(runtime.orbit_phase * 1.7 + ray_index * TAU / 10.0)
			draw_line(position + direction * (orb_size + 3.0), position + direction * (orb_size + 9.0 + ray_index % 2 * 4.0), Color(1.0, 0.76, 0.28, 0.64), 2.0, true)
		draw_arc(position, orb_size + 5.0, runtime.orbit_phase, runtime.orbit_phase + PI * 1.55, 18, Color(1.0, 0.72, 0.25, 0.75), 3.0)
		draw_circle(position, orb_size, Color("f7a83c"))
		draw_circle(position - Vector2(3, 4), orb_size * 0.5, Color("fff3b0"))
		draw_circle(position + Vector2(5, 4), orb_size * 0.28, Color("d96a26"))
	draw_arc(player.position, distance, runtime.orbit_phase - 1.2, runtime.orbit_phase + 1.9, 40, Color(1.0, 0.76, 0.28, 0.46), 2.2)
	draw_arc(player.position, distance + 6.0, runtime.orbit_phase + PI, runtime.orbit_phase + PI * 1.7, 24, Color(1.0, 0.94, 0.55, 0.24), 1.4)


func _draw_frost_pulse() -> void:
	var skill_level: int = levels.get("frost_tide", 0)
	if skill_level <= 0 or runtime.pulse_visual_time <= 0.0:
		return
	var data: Dictionary = HeroCatalog.skill("frost_tide")["runtime"]
	var radius: float = data["radius"][skill_level]
	var progress: float = 1.0 - runtime.pulse_visual_time / 0.3
	var alpha := 1.0 - progress
	draw_arc(player.position, radius * progress, 0.0, TAU, 72, Color(0.55, 0.95, 1.0, alpha), 8.0)
	draw_arc(player.position, radius * progress * 0.86, 0.0, TAU, 64, Color(0.78, 0.98, 1.0, alpha * 0.55), 2.0)
	for index in range(12):
		var angle := index * TAU / 12.0 + progress * 0.3
		var position := player.position + Vector2.from_angle(angle) * radius * progress
		var direction := Vector2.from_angle(angle)
		draw_line(position - direction * (8.0 + skill_level * 2.0), position + direction * (8.0 + skill_level * 2.0), Color(0.8, 0.98, 1.0, alpha), 2.6, true)
		draw_line(position - direction.rotated(PI * 0.5) * 5.0, position + direction.rotated(PI * 0.5) * 5.0, Color(0.68, 0.92, 1.0, alpha), 2.0, true)
