extends RefCounted

var player: Node2D
var effects: Node2D
var audio: Node
var ready := true
var recharge_at := 0.0
var blocks := 0
var damage_blocked := 0.0


func configure(player_node: Node2D, combat_effects: Node2D, audio_manager: Node) -> void:
	player = player_node
	effects = combat_effects
	audio = audio_manager
	ready = true
	recharge_at = 0.0
	blocks = 0
	damage_blocked = 0.0
	player.passive_active = true


func advance(_direction: Vector2, delta: float, elapsed: float) -> float:
	if not ready and elapsed >= recharge_at:
		ready = true
		effects.add_effect(player.position, 58.0, Color("70e8ff"), 0.36, "star_hit")
	player.passive_active = ready
	return delta


func try_absorb(enemy: Node, elapsed: float) -> bool:
	if not ready:
		return false
	ready = false
	recharge_at = elapsed + 24.0
	blocks += 1
	damage_blocked += enemy.damage
	player.passive_active = false
	audio.play_sfx("skill_frost_tide", -2.0, 1.08)
	effects.add_effect(player.position, 74.0, Color("70e8ff"), 0.42, "star_hit")
	var knockback_direction: Vector2 = player.position.direction_to(enemy.position)
	enemy.position += knockback_direction * 45.0
	enemy.apply_slow(0.35, 1.2, elapsed)
	return true


func status_text(elapsed: float) -> String:
	return "结界 READY" if ready else "结界 %ds" % maxi(0, ceili(recharge_at - elapsed))


func result_text() -> String:
	return "结界抵挡 %d 次 · %.0f 伤害" % [blocks, damage_blocked]
