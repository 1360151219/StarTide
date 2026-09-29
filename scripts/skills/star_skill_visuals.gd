extends Node2D

const FrostSlashVisual = preload("res://scripts/skills/frost_slash_visual.gd")
const FrostTideVisual = preload("res://scripts/skills/frost_tide_visual.gd")

var runtime: Node
var player: Node2D
var slash_nodes: Dictionary = {}
var tide_node: Node2D
var tide_visual_id := -1


func configure(skill_runtime: Node, player_node: Node2D) -> void:
	runtime = skill_runtime
	player = player_node


func refresh() -> void:
	_sync_frost_slashes()
	_sync_frost_tide()
	queue_redraw()


func _draw() -> void:
	if runtime.levels.get("frost_tide", 0) <= 0 or runtime.pulse_timer <= 0.0 or runtime.pulse_timer > 0.3:
		return
	var charge: float = 1.0 - runtime.pulse_timer / 0.3
	for index in range(6):
		var direction := Vector2.from_angle(index * TAU / 6.0)
		var tangent := direction.orthogonal()
		var center: Vector2 = player.position + direction * lerpf(58.0, 36.0, charge)
		var crystal := PackedVector2Array([center - direction * 7.0, center + tangent * 3.0, center + direction * 7.0, center - tangent * 3.0, center - direction * 7.0])
		draw_polyline(crystal, Color(0.03, 0.27, 0.38, charge * 0.8), 3.5, true)
		draw_polyline(crystal, Color(0.66, 0.96, 1.0, charge * 0.9), 1.5, true)


func _sync_frost_slashes() -> void:
	var live_ids := {}
	for slash in runtime.slash_visuals:
		var visual_id := int(slash["visual_id"])
		live_ids[visual_id] = true
		if not slash_nodes.has(visual_id):
			var visual := FrostSlashVisual.new()
			slash_nodes[visual_id] = visual
			add_child(visual)
			visual.configure(slash, player)
		else:
			slash_nodes[visual_id].refresh(slash)
	for visual_id in slash_nodes.keys():
		if live_ids.has(visual_id):
			continue
		slash_nodes[visual_id].queue_free()
		slash_nodes.erase(visual_id)


func _sync_frost_tide() -> void:
	if runtime.pulse_visual.is_empty():
		if tide_node != null:
			tide_node.queue_free()
			tide_node = null
		tide_visual_id = -1
		return
	var visual_id := int(runtime.pulse_visual["visual_id"])
	if tide_node == null or tide_visual_id != visual_id:
		if tide_node != null:
			tide_node.queue_free()
		tide_node = FrostTideVisual.new()
		tide_visual_id = visual_id
		add_child(tide_node)
		tide_node.configure(runtime.pulse_visual, player)
	else:
		tide_node.refresh(runtime.pulse_visual)
