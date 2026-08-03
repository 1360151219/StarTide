class_name ResultRevealAnimator
extends RefCounted


static func play(
	host: Node,
	previous_tween: Tween,
	result_card: Panel,
	victory_crest: TextureRect,
	celebration_stars: Array[Label],
	won: bool
) -> Tween:
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	result_card.scale = Vector2(0.96, 0.96)
	result_card.modulate.a = 1.0
	var reveal_tween := host.create_tween().set_parallel(true)
	reveal_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(result_card, "scale", Vector2.ONE, 0.3)
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
