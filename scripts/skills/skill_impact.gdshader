shader_type canvas_item;
render_mode unshaded;
#include "res://scripts/skills/skill_material.gdshaderinc"

uniform bool fiery = false;
uniform float progress = 0.0;
uniform float opacity = 1.0;
uniform vec2 hero_position = vec2(-100000.0);
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	vec3 flow = material_flow(UV);
	float density = 1.0 - length(q) + (flow.x * 0.45 + flow.y * 0.55) * 0.86 - 0.52;
	float alpha = smoothstep(0.0, 0.24, density) * (1.0 - smoothstep(0.72, 1.0, length(q)));
	vec3 color;
	if (fiery) {
		float heat = clamp(density * 0.85 + flow.y * 0.42, 0.0, 1.0);
		color = feather_heat(vec3(1.0, 0.85, 0.5) * heat, flow, 1.0);
		float cooling = smoothstep(0.055, 0.21, age);
		color = mix(color, mix(vec3(0.42, 0.24, 0.15), vec3(0.76, 0.61, 0.42), flow.x), cooling * 0.8);
	} else {
		color = mix(vec3(0.13, 0.49, 0.64), vec3(0.83, 0.97, 1.0), clamp(density * 0.78 + flow.z * 0.5, 0.0, 1.0));
		alpha *= 0.5;
	}
	float protection = smoothstep(0.8, 1.2, length((world_position - hero_position - vec2(0, -18)) / vec2(26, 48)));
	COLOR = vec4(color, alpha * opacity * protection * (1.0 - smoothstep(0.25, 1.0, progress)));
}
