extends RefCounted

const StarShield = preload("res://scripts/passives/star_shield_passive.gd")
const EmberMomentum = preload("res://scripts/passives/ember_momentum_passive.gd")

var runtime: RefCounted


func configure(hero_id: String, player: Node2D, effects: Node2D, audio: Node) -> void:
	runtime = StarShield.new() if hero_id == "star_warden" else EmberMomentum.new()
	runtime.configure(player, effects, audio)


func advance(movement: Vector2, delta: float, elapsed: float) -> float:
	return runtime.advance(movement, delta, elapsed)


func try_absorb(enemy: Node, elapsed: float) -> bool:
	return runtime.try_absorb(enemy, elapsed)


func status_text(elapsed: float) -> String:
	return runtime.status_text(elapsed)


func result_text() -> String:
	return runtime.result_text()
