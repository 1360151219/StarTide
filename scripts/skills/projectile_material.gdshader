shader_type canvas_item;
render_mode unshaded;
#include "res://scripts/skills/skill_material.gdshaderinc"

uniform bool fiery = false;
uniform bool wake = false;
uniform float variation = 0.0;
uniform vec2 hero_position = vec2(-100000.0);
varying vec4 sprite_tint;
varying vec2 world_position;

void vertex() {
	sprite_tint = COLOR;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 uv = UV;
	vec3 flow = material_flow(uv * vec2(0.85, 0.55) + vec2(variation, 0.0));
	if (wake) {
		float axis = uv.y - 0.5 + (flow.x - 0.5) * (1.0 - uv.x) * 0.25;
		float width = pow(uv.x, 0.65) * (fiery ? 0.3 : 0.18);
		float density = 1.0 - abs(axis) / max(width, 0.001) + flow.y * 0.8 - 0.67;
		float alpha = smoothstep(0.03, 0.25, density) * smoothstep(0.02, 0.17, uv.x) * (1.0 - smoothstep(0.77, 0.98, uv.x));
		vec3 color = fiery ? feather_heat(vec3(1.0, 0.65, 0.12) * (density * 0.5 + 0.5), flow, 1.0) : mix(vec3(0.06, 0.45, 0.63), vec3(0.74, 0.96, 1.0), clamp(density, 0.0, 1.0));
		COLOR = vec4(color, alpha * sprite_tint.a);
	} else {
		uv.y += fiery ? (flow.y - 0.5) * 0.055 * pow(1.0 - uv.x, 2.0) : 0.0;
		vec4 source = texture(TEXTURE, uv) * sprite_tint;
		vec3 color = fiery ? feather_heat(source.rgb, flow, 0.56) : ice_surface(source.rgb, uv, 0.25);
		COLOR = vec4(color, source.a);
	}
	COLOR.a *= smoothstep(0.8, 1.2, length((world_position - hero_position - vec2(0, -20)) / vec2(22, 44)));
}
