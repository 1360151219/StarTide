class_name ResultRevealAnimator
extends RefCounted


static func play(
	host: Node,
	previous_tween: Tween,
	result_card: Panel,
	victory_crest: TextureRect,
	celebration_stars: Array[Control],
	content_nodes: Array[Node],
	buttons: Array[Button],
	won: bool
) -> Tween:
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	var full_canvas := result_card.get_node_or_null("FullCanvas") as CanvasItem
	var first_beat_canvas := result_card.get_node_or_null("FirstBeatCanvas") as CanvasItem
	result_card.scale = Vector2.ONE
	result_card.modulate.a = 1.0
	if full_canvas != null:
		full_canvas.modulate.a = 0.0
	if first_beat_canvas != null:
		first_beat_canvas.modulate.a = 1.0
	for index in range(content_nodes.size()):
		var initial_node := content_nodes[index]
		if initial_node is CanvasItem:
			initial_node.modulate.a = 1.0 if index < 4 else 0.0
	for button in buttons:
		button.modulate.a = 0.0
		button.disabled = true
	var reveal_tween := host.create_tween().set_parallel(true)
	reveal_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if full_canvas != null:
		reveal_tween.tween_property(full_canvas, "modulate:a", 1.0, 0.18).set_delay(0.10)
	if first_beat_canvas != null:
		reveal_tween.tween_property(first_beat_canvas, "modulate:a", 0.0, 0.12).set_delay(0.24)
	var secondary_delays := [0.14, 0.22, 0.30]
	for index in range(4, content_nodes.size()):
		var secondary_node: Node = content_nodes[index]
		if secondary_node is CanvasItem:
			var delay: float = float(secondary_delays[mini(index - 4, secondary_delays.size() - 1)])
			reveal_tween.tween_property(secondary_node, "modulate:a", 1.0, 0.16).set_delay(delay)
	for index in range(buttons.size()):
		reveal_tween.tween_property(buttons[index], "modulate:a", 1.0, 0.16).set_delay(0.36 + index * 0.08)
	reveal_tween.tween_callback(_enable_buttons.bind(buttons)).set_delay(0.60)
	if not won:
		return reveal_tween
	victory_crest.scale = Vector2(0.84, 0.84)
	victory_crest.modulate.a = 0.18
	reveal_tween.tween_property(victory_crest, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	reveal_tween.tween_property(victory_crest, "modulate:a", 0.34, 0.16)
	for index in range(celebration_stars.size()):
		var star := celebration_stars[index]
		star.modulate.a = 0.0
		star.scale = Vector2(0.72, 0.72)
		var delay := 0.06 + index * 0.035
		reveal_tween.tween_property(star, "modulate:a", 0.88, 0.16).set_delay(delay)
		reveal_tween.tween_property(star, "scale", Vector2.ONE, 0.18).set_delay(delay).set_trans(Tween.TRANS_BACK)
	return reveal_tween


static func _enable_buttons(buttons: Array[Button]) -> void:
	for button in buttons:
		button.disabled = false
