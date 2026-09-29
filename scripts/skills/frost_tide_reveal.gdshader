shader_type canvas_item;
render_mode blend_mix, unshaded;
#include "res://scripts/skills/skill_material.gdshaderinc"

uniform float wave_progress : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform float freeze_amount : hint_range(0.0, 1.0) = 0.0;
uniform float intensity : hint_range(0.0, 1.5) = 1.0;
uniform vec2 safe_center_uv = vec2(-2.0);
uniform vec2 safe_radius_uv = vec2(0.03);


void fragment() {
	vec4 source = COLOR;
	float radial = length(UV - vec2(0.5)) * 2.0;
	float crest = smoothstep(0.7, 0.96, radial);
	float front = crest * (0.72 + (1.0 - wave_progress) * 0.28);
	float dissolve_edge = mix(-0.18, 1.42, dissolve_progress);
	vec3 flow = material_flow(UV);
	float fracture = (flow.y - 0.5) * 2.0;
	float remaining = smoothstep(dissolve_edge - 0.055, dissolve_edge + 0.055, radial + fracture * dissolve_progress * 0.15);
	float safe_hole = smoothstep(1.0, 1.3, length((UV - safe_center_uv) / safe_radius_uv));
	vec3 color = ice_surface(source.rgb, UV, 0.72);
	color = mix(color, vec3(0.9, 0.99, 1.0), front * min(intensity * 0.1, 0.16));
	remaining *= mix(1.0, smoothstep(0.18, 0.59, flow.z), dissolve_progress);
	color += vec3(0.02, 0.12, 0.16) * crest * intensity * freeze_amount * 0.08;
	COLOR = vec4(color, source.a * remaining * safe_hole);
}
