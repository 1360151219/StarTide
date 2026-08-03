extends RefCounted

const UPGRADE_RESUME_GRACE := 1.5

var opening_movement_observed := false


func reset() -> void:
	opening_movement_observed = false


func combat_ready(direction: Vector2, elapsed: float, level: LevelConfig) -> bool:
	if direction.length_squared() >= 0.04:
		opening_movement_observed = true
	return opening_movement_observed or elapsed >= level.opening_tutorial_grace


func prepare_upgrade_resume(elapsed: float, damage_resolver: RefCounted) -> void:
	damage_resolver.grant_invulnerability(elapsed, UPGRADE_RESUME_GRACE)
