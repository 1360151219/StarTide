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
	result_card.scale = Vector2(0.96, 0.96)
	result_card.modulate.a = 1.0
	for node in content_nodes:
		if node is CanvasItem:
			node.modulate.a = 0.0
	for button in buttons:
		button.modulate.a = 0.0
		button.disabled = true
	var reveal_tween := host.create_tween().set_parallel(true)
	reveal_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(result_card, "scale", Vector2.ONE, 0.28)
	var delays := [0.04, 0.04, 0.16, 0.38, 0.38, 0.58, 0.58]
	for index in range(content_nodes.size()):
		var node: Node = content_nodes[index]
		if node is CanvasItem:
			reveal_tween.tween_property(node, "modulate:a", 1.0, 0.2).set_delay(delays[mini(index, delays.size() - 1)])
	for button in buttons:
		reveal_tween.tween_property(button, "modulate:a", 1.0, 0.2).set_delay(0.78)
	reveal_tween.tween_callback(_enable_buttons.bind(buttons)).set_delay(0.98)
	if not won:
		return reveal_tween
	victory_crest.scale = Vector2(0.92, 0.92)
	victory_crest.modulate.a = 0.12
	reveal_tween.tween_property(victory_crest, "scale", Vector2.ONE, 0.42)
	reveal_tween.tween_property(victory_crest, "modulate:a", 0.3, 0.36)
	for index in range(celebration_stars.size()):
		var star := celebration_stars[index]
		star.modulate.a = 0.72
		star.scale = Vector2(0.72, 0.72)
		var star_tween := host.create_tween().set_parallel(true)
		star_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var delay := 0.12 + index * 0.05
		star_tween.tween_property(star, "modulate:a", 0.92, 0.22).set_delay(delay)
		star_tween.tween_property(star, "scale", Vector2.ONE, 0.26).set_delay(delay)
	return reveal_tween


static func _enable_buttons(buttons: Array[Button]) -> void:
	for button in buttons:
		button.disabled = false
