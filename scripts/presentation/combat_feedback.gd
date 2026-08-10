extends RefCounted

const PLAYER_HIT_DURATION := 0.16

var camera: Camera2D
var damage_flash: ColorRect
var shake_time := 0.0
var shake_strength := 0.0
var flash_time := 0.0
var flash_strength := 0.0


func configure(run_camera: Camera2D, flash: ColorRect) -> void:
	camera = run_camera
	damage_flash = flash
	flash_time = 0.0
	flash_strength = 0.0
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float directional_weight : hint_range(0.0, 1.0) = 0.0;
uniform vec2 impact_direction = vec2(0.0, -1.0);

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float edge_distance = max(abs(centered.x), abs(centered.y));
	float rim = smoothstep(0.48, 0.98, edge_distance);
	float center_clear = smoothstep(0.34, 0.78, length(centered));
	vec2 radial = normalize(centered + vec2(0.0001));
	vec2 direction = normalize(impact_direction + vec2(0.0001));
	float facing = smoothstep(-0.35, 0.82, dot(radial, direction));
	float directional = mix(1.0, mix(0.28, 1.0, facing), directional_weight);
	float corner_peak = smoothstep(0.62, 1.22, length(centered));
	float alpha = intensity * rim * center_clear * directional * mix(0.72, 1.0, corner_peak);
	COLOR = vec4(0.894, 0.357, 0.357, alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("intensity", 0.0)
	damage_flash.material = material
	damage_flash.color = Color.WHITE


func trigger_player_hit(damage: float, source_direction := Vector2.ZERO) -> void:
	shake_time = 0.18
	shake_strength = clampf(3.5 + damage * 0.24, 4.5, 8.0)
	flash_time = PLAYER_HIT_DURATION
	flash_strength = clampf(0.48 + damage * 0.006, 0.5, 0.64)
	var material := damage_flash.material as ShaderMaterial
	if material == null:
		return
	var has_direction := source_direction.length_squared() > 0.0001
	material.set_shader_parameter("directional_weight", 0.72 if has_direction else 0.0)
	if has_direction:
		material.set_shader_parameter("impact_direction", source_direction.normalized())
	material.set_shader_parameter("intensity", flash_strength)


func advance(delta: float, elapsed: float) -> void:
	flash_time = maxf(0.0, flash_time - delta)
	var material := damage_flash.material as ShaderMaterial
	if material != null:
		var remaining := flash_time / PLAYER_HIT_DURATION
		material.set_shader_parameter("intensity", flash_strength * remaining * remaining)
	shake_time = maxf(0.0, shake_time - delta)
	if shake_time > 0.0:
		var falloff := shake_time / 0.18
		camera.offset = Vector2(sin(elapsed * 91.0), cos(elapsed * 73.0)) * shake_strength * falloff
	else:
		camera.offset = camera.offset.move_toward(Vector2.ZERO, delta * 90.0)
