extends Node2D

const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const PERSISTENT_ALPHA := 0.72

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
	var player_center := player.position
	var data: Dictionary = SkillCatalog.skill("sun_orbit")["runtime"]
	var count := int(runtime._stat("sun_orbit", "count", data["count"][skill_level]))
	var range_multiplier := _range_multiplier("sun_orbit")
	var distance: float = data["orbit_radius"][skill_level] * range_multiplier
	var orb_size: float = data["orb_radius"][skill_level] * range_multiplier * runtime._branch_multiplier("sun_orbit", "orb_radius_multiplier")
	var path_rotation: float = runtime.orbit_phase * 0.42
	for segment in range(3):
		var start_angle := path_rotation + segment * TAU / 3.0 + 0.16
		var end_angle := start_angle + TAU / 3.0 - 0.42
		draw_arc(player_center, distance, start_angle, end_angle, 16, Color(0.08, 0.24, 0.27, 0.56 * PERSISTENT_ALPHA), 4.6)
		draw_arc(player_center, distance, start_angle, end_angle, 16, Color(1.0, 0.76, 0.28, 0.72 * PERSISTENT_ALPHA), 2.0)
	for index in range(count):
		var angle: float = runtime.orbit_phase + index * TAU / count
		var radial := Vector2.from_angle(angle)
		var position: Vector2 = player_center + radial * distance
		_draw_sun_node(position, radial, orb_size)


func _draw_frost_pulse() -> void:
	var skill_level: int = levels.get("frost_tide", 0)
	if skill_level <= 0 or runtime.pulse_visual_time <= 0.0:
		return
	var data: Dictionary = SkillCatalog.skill("frost_tide")["runtime"]
	var radius: float = data["radius"][skill_level] * _range_multiplier("frost_tide") * runtime._branch_multiplier("frost_tide", "radius_multiplier")
	var progress: float = 1.0 - runtime.pulse_visual_time / runtime.FROST_TRAVEL_TIME
	var alpha := 1.0 - progress
	var wave_radius := radius * (0.08 + progress * 0.92)
	var trailing_radius := maxf(4.0, wave_radius - 12.0 - skill_level)
	for segment in range(8):
		var start_angle := segment * TAU / 8.0 + 0.055
		var end_angle := start_angle + TAU / 8.0 - 0.14
		draw_arc(runtime.pulse_center, wave_radius, start_angle, end_angle, 10, Color(0.03, 0.27, 0.38, alpha * 0.72), 6.0, true)
		draw_arc(runtime.pulse_center, wave_radius, start_angle, end_angle, 10, Color(0.7, 0.97, 1.0, alpha * 0.94), 2.8, true)
		draw_arc(runtime.pulse_center, trailing_radius, start_angle + 0.08, end_angle - 0.04, 8, Color(0.5, 0.93, 1.0, alpha * 0.28), 3.0, true)
	for shard_index in range(16):
		var angle := shard_index * TAU / 16.0 + 0.1
		var radial := Vector2.from_angle(angle)
		var tangent := radial.orthogonal()
		var base_center: Vector2 = runtime.pulse_center + radial * (wave_radius - 2.0)
		var shard_length := 9.0 + float((shard_index * 5) % 4) * 2.2 + skill_level
		var half_width := 3.4 + float(shard_index % 3) * 0.7
		var shard := PackedVector2Array([
			base_center - tangent * half_width,
			base_center + radial * shard_length,
			base_center + tangent * half_width,
			base_center - radial * 4.0,
		])
		draw_colored_polygon(shard, Color(0.68, 0.96, 1.0, alpha * 0.58))
		draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2]]), Color(0.84, 0.99, 1.0, alpha * 0.82), 1.4, true)


func _draw_sun_node(position: Vector2, radial: Vector2, orb_size: float) -> void:
	var tangent := radial.orthogonal()
	var length := orb_size + 7.0
	var width := maxf(6.0, orb_size * 0.78)
	var outer_color := Color("243c43")
	outer_color.a = PERSISTENT_ALPHA
	var outer := PackedVector2Array([
		position + radial * length,
		position + tangent * width,
		position - radial * length * 0.68,
		position - tangent * width,
	])
	draw_colored_polygon(outer, outer_color)
	var inner_color := Color("f2b84b")
	inner_color.a = PERSISTENT_ALPHA
	var inner := PackedVector2Array([
		position + radial * (length - 3.0),
		position + tangent * (width - 2.5),
		position - radial * (length * 0.48),
		position - tangent * (width - 2.5),
	])
	draw_colored_polygon(inner, inner_color)
	draw_circle(position - radial * 1.0, maxf(3.0, orb_size * 0.34), Color(1.0, 0.94, 0.7, PERSISTENT_ALPHA))
	draw_line(position + radial * (length + 2.0), position + radial * (length + 8.0), Color(1.0, 0.82, 0.34, 0.82 * PERSISTENT_ALPHA), 2.2, true)


func _range_multiplier(skill_id: String) -> float:
	return runtime._multiplier(skill_id, "range_multiplier")
