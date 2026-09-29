shader_type canvas_item;
render_mode unshaded;
#include "res://scripts/skills/skill_material.gdshaderinc"

uniform float sweep_progress : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform bool reverse = false;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec2 safe_center_uv = vec2(0.5);
uniform vec2 safe_radius_uv = vec2(0.06);
uniform float region_start = 0.0;
uniform float bend = 0.0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec2 local_uv = vec2((UV.x - region_start) * 2.0, UV.y);
	vec3 flow = material_flow(vec2(reverse ? 1.0 - local_uv.x : local_uv.x, local_uv.y));
	vec2 bent_uv = local_uv + vec2(bend * pow(1.0 - local_uv.y, 2.0), 0.0);
	bent_uv += (flow.xy - vec2(0.5)) * vec2(0.023, 0.014) * (1.0 - local_uv.y);
	vec2 sample_uv = vec2(region_start + clamp(bent_uv.x, 0.001, 0.999) * 0.5, bent_uv.y);
	vec4 color = texture(TEXTURE, sample_uv) * sprite_tint;
	float side_path = reverse ? bent_uv.x : 1.0 - bent_uv.x;
	float path = clamp((1.0 - bent_uv.y) * 0.76 + side_path * 0.24, 0.0, 0.98);
	float reveal = smoothstep(path - 0.08, path + 0.015, sweep_progress);
	float edge = 1.0 - smoothstep(0.0, 0.055, abs(path - sweep_progress));
	float fracture = (flow.y - 0.5) * 2.0;
	float dissolve_path = bent_uv.y * 0.7 + (1.0 - side_path) * 0.3 + fracture * 0.13;
	float dissolve = smoothstep(dissolve_path - 0.06, dissolve_path + 0.06, mix(-0.2, 1.2, dissolve_progress));
	float center_safety = smoothstep(1.0, 1.25, length((local_uv - safe_center_uv) / safe_radius_uv));
	color.rgb = feather_heat(color.rgb, flow, 0.68);
	color.rgb = mix(color.rgb, vec3(1.0, 0.96, 0.72), edge * min(intensity * 0.16, 0.22));
	color.a *= mix(1.0, smoothstep(0.14, 0.57, flow.z), dissolve_progress);
	color.a *= reveal * (1.0 - dissolve) * center_safety;
	COLOR = color;
}
