shader_type canvas_item;
render_mode blend_mix, unshaded;
#include "res://scripts/skills/skill_material.gdshaderinc"

uniform sampler2D motion_mask : filter_linear;
uniform float sweep_progress : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform bool reverse = false;
uniform float intensity : hint_range(0.0, 1.5) = 1.0;
uniform float motion_warp = 0.0;
uniform float impact : hint_range(0.0, 1.0) = 0.0;
uniform vec2 safe_center_uv = vec2(-2.0);
uniform vec2 safe_radius_uv = vec2(0.07);
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}


void fragment() {
	vec2 offset = UV - vec2(0.5);
	float turn = motion_warp * (length(offset) * 2.0 - 0.35);
	vec2 sample_uv = mat2(vec2(cos(turn), sin(turn)), vec2(-sin(turn), cos(turn))) * offset + vec2(0.5);
	vec4 source = texture(TEXTURE, sample_uv) * sprite_tint;
	float phase = pow(max(texture(motion_mask, sample_uv).r, 0.0), 0.4545);
	phase = reverse ? 1.0 - phase : phase;
	float revealed = smoothstep(phase - 0.045, phase + 0.018, sweep_progress);
	float front = (1.0 - smoothstep(0.018, 0.085, abs(phase - sweep_progress))) * (1.0 - smoothstep(0.94, 1.0, sweep_progress));
	float dissolve_cut = mix(-0.12, 1.08, dissolve_progress);
	vec3 flow = material_flow(sample_uv);
	float breakup = (flow.y - 0.5) * 2.0;
	float remaining = smoothstep(dissolve_cut - 0.06, dissolve_cut + 0.06, phase + breakup * 0.14 * dissolve_progress);
	float safe_hole = smoothstep(1.0, 1.3, length((UV - safe_center_uv) / safe_radius_uv));
	vec3 color = ice_surface(source.rgb, sample_uv, 0.66);
	color = mix(color, vec3(0.93, 0.99, 1.0), min((front * 0.32 + impact * 0.1) * intensity, 0.46));
	remaining *= mix(1.0, smoothstep(0.16, 0.57, flow.z), dissolve_progress);
	COLOR = vec4(color, source.a * revealed * remaining * safe_hole);
}
