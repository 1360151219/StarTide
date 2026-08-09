extends RefCounted

var camera: Camera2D
var damage_flash: ColorRect
var shake_time := 0.0
var shake_strength := 0.0


func configure(run_camera: Camera2D, flash: ColorRect) -> void:
	camera = run_camera
	damage_flash = flash


func trigger_player_hit(damage: float) -> void:
	shake_time = 0.18
	shake_strength = clampf(3.5 + damage * 0.24, 4.5, 8.0)
	damage_flash.color = Color(0.85, 0.035, 0.08, 0.16)


func advance(delta: float, elapsed: float) -> void:
	damage_flash.color.a = move_toward(damage_flash.color.a, 0.0, delta * 1.75)
	shake_time = maxf(0.0, shake_time - delta)
	if shake_time > 0.0:
		var falloff := shake_time / 0.18
		camera.offset = Vector2(sin(elapsed * 91.0), cos(elapsed * 73.0)) * shake_strength * falloff
	else:
		camera.offset = camera.offset.move_toward(Vector2.ZERO, delta * 90.0)
