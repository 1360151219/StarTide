extends Node2D

const PhoenixHeartVisual = preload("res://scripts/skills/phoenix_heart_visual.gd")

var runtime: Node
var player: Node2D
var phoenix_node: Node2D
var phoenix_visual_id := -1


func configure(skill_runtime: Node, player_node: Node2D) -> void:
	runtime = skill_runtime
	player = player_node


func refresh() -> void:
	queue_redraw()
	if runtime.phoenix_visual.is_empty():
		if phoenix_node != null:
			phoenix_node.queue_free()
			phoenix_node = null
			phoenix_visual_id = -1
		return
	var visual_id := int(runtime.phoenix_visual["visual_id"])
	if phoenix_node == null or phoenix_visual_id != visual_id:
		if phoenix_node != null:
			phoenix_node.queue_free()
		phoenix_node = PhoenixHeartVisual.new()
		phoenix_visual_id = visual_id
		add_child(phoenix_node)
		phoenix_node.configure(runtime.phoenix_visual, player)
	else:
		phoenix_node.refresh(runtime.phoenix_visual)


func _draw() -> void:
	if runtime.levels.get("phoenix_heart", 0) <= 0 or runtime.phoenix_timer <= 0.0 or runtime.phoenix_timer > 0.3:
		return
	var charge: float = 1.0 - runtime.phoenix_timer / 0.3
	for side in [-1.0, 1.0]:
		for index in range(3):
			var center: Vector2 = player.position + Vector2(side * lerpf(54.0, 25.0, charge), 12.0 - index * 10.0)
			var feather := PackedVector2Array([center + Vector2(-side * 8.0, 6.0), center, center + Vector2(side * (8.0 + index * 3.0), -8.0)])
			draw_polyline(feather, Color(0.28, 0.08, 0.14, charge * 0.8), 4.0, true)
			draw_polyline(feather, Color(1.0, 0.76, 0.3, charge * 0.9), 1.8, true)
