extends Node2D

const SkillCatalog = preload("res://scripts/skill_catalog.gd")

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
	var data: Dictionary = SkillCatalog.skill("sun_orbit")["runtime"]
	var count := int(runtime._stat("sun_orbit", "count", data["count"][skill_level]))
	var range_multiplier := _range_multiplier("sun_orbit")
	var distance: float = data["orbit_radius"][skill_level] * range_multiplier
	var orb_size: float = data["orb_radius"][skill_level] * range_multiplier * runtime._branch_multiplier("sun_orbit", "orb_radius_multiplier")
	var path_rotation: float = runtime.orbit_phase * 0.42
	for segment in range(3):
		var start_angle := path_rotation + segment * TAU / 3.0 + 0.16
		var end_angle := start_angle + TAU / 3.0 - 0.42
		draw_arc(player.position, distance, start_angle, end_angle, 16, Color(0.08, 0.24, 0.27, 0.56), 4.6)
		draw_arc(player.position, distance, start_angle, end_angle, 16, Color(1.0, 0.76, 0.28, 0.72), 2.0)
	for index in range(count):
		var angle: float = runtime.orbit_phase + index * TAU / count
		var radial := Vector2.from_angle(angle)
		var position: Vector2 = player.position + radial * distance
		_draw_sun_node(position, radial, orb_size)


func _draw_frost_pulse() -> void:
	var skill_level: int = levels.get("frost_tide", 0)
	if skill_level <= 0 or runtime.pulse_visual_time <= 0.0:
		return
	var data: Dictionary = SkillCatalog.skill("frost_tide")["runtime"]
	var radius: float = data["radius"][skill_level] * _range_multiplier("frost_tide") * runtime._branch_multiplier("frost_tide", "radius_multiplier")
	var progress: float = 1.0 - runtime.pulse_visual_time / runtime.FROST_TRAVEL_TIME
	var alpha := 1.0 - progress
	var direction: Vector2 = runtime.pulse_direction.normalized()
	var tangent := direction.orthogonal()
	var front_center: Vector2 = runtime.pulse_center + direction * radius * (0.05 + progress * 0.95)
	var half_width := radius * (0.24 + progress * 0.46)
	var thickness := 12.0 + skill_level * 2.0
	var back_center := front_center - direction * thickness
	var teeth := 6
	var wave := PackedVector2Array([
		back_center + tangent * half_width,
		back_center - tangent * half_width,
	])
	for point_index in range(teeth * 2 + 1):
		var amount := float(point_index) / float(teeth * 2)
		var lateral := lerpf(-half_width, half_width, amount)
		var tooth_length := 7.0 if point_index % 2 == 0 else 19.0 + skill_level * 2.0
		wave.append(front_center + tangent * lateral + direction * tooth_length)
	draw_colored_polygon(wave, Color(0.5, 0.93, 1.0, alpha * 0.18))
	var outline := PackedVector2Array(wave)
	outline.append(wave[0])
	draw_polyline(outline, Color(0.03, 0.27, 0.38, alpha * 0.88), 7.0, true)
	draw_polyline(outline, Color(0.7, 0.97, 1.0, alpha), 3.0, true)
	for tooth_index in range(teeth):
		var lateral := lerpf(-half_width, half_width, (tooth_index + 0.5) / teeth)
		var tip := front_center + tangent * lateral + direction * (19.0 + skill_level * 2.0)
		var root := back_center + tangent * lateral * 0.84
		draw_line(root, tip, Color(0.84, 0.99, 1.0, alpha * 0.62), 1.8, true)
	for shard_index in range(5):
		var side := -1.0 if shard_index % 2 == 0 else 1.0
		var shard_center := front_center - direction * (18.0 + shard_index * 12.0) + tangent * side * half_width * (0.18 + shard_index * 0.11)
		var shard_length := 7.0 + shard_index * 1.4
		draw_line(shard_center - direction * shard_length, shard_center + direction * shard_length, Color(0.62, 0.94, 1.0, alpha * 0.72), 2.2, true)


func _draw_sun_node(position: Vector2, radial: Vector2, orb_size: float) -> void:
	var tangent := radial.orthogonal()
	var length := orb_size + 7.0
	var width := maxf(6.0, orb_size * 0.78)
	var outer := PackedVector2Array([
		position + radial * length,
		position + tangent * width,
		position - radial * length * 0.68,
		position - tangent * width,
	])
	draw_colored_polygon(outer, Color("243c43"))
	var inner := PackedVector2Array([
		position + radial * (length - 3.0),
		position + tangent * (width - 2.5),
		position - radial * (length * 0.48),
		position - tangent * (width - 2.5),
	])
	draw_colored_polygon(inner, Color("f2b84b"))
	draw_circle(position - radial * 1.0, maxf(3.0, orb_size * 0.34), Color("fff0b2"))
	draw_line(position + radial * (length + 2.0), position + radial * (length + 8.0), Color(1.0, 0.82, 0.34, 0.82), 2.2, true)


func _range_multiplier(skill_id: String) -> float:
	return runtime._multiplier(skill_id, "range_multiplier")
