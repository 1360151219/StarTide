// Shared material motion; age comes from the combat clock, never global TIME.
uniform sampler2D turbulence : repeat_enable, filter_linear;
uniform sampler2D crystal_material : filter_linear_mipmap;
uniform float age = 0.0;

vec3 material_flow(vec2 uv) {
	float broad = texture(turbulence, uv * 0.75 + vec2(age * 0.17, -age * 0.35)).r;
	vec2 warped = uv + vec2(broad - 0.5, broad * 0.2) * 0.18;
	float rolling = texture(turbulence, warped * 1.6 + vec2(-age * 0.28, age * 0.8)).r;
	float fine = texture(turbulence, warped * 3.9 - vec2(age * 0.8, age * 0.3)).r;
	return vec3(broad, rolling, fine);
}

vec3 ice_surface(vec3 source, vec2 uv, float strength) {
	vec3 flow = material_flow(uv);
	float relief = texture(turbulence, uv * 1.6 + vec2(-0.06 - age * 0.28, 0.04 + age * 0.8)).r - flow.y;
	float light = dot(source, vec3(0.21, 0.72, 0.07));
	float depth = clamp(light * 0.7 + flow.x * 0.32 + relief * 0.7, 0.0, 1.0);
	vec3 glass = mix(vec3(0.035, 0.25, 0.39), vec3(0.5, 0.85, 0.94), smoothstep(0.2, 0.88, depth));
	// The solid interior of the shared crystal supplies real painted facets, not another outline.
	vec2 facet_uv = vec2(0.28, 0.45) + fract(uv * vec2(1.7, 1.2) + flow.xy * 0.025) * vec2(0.34, 0.08);
	vec3 facets = texture(crystal_material, facet_uv).rgb;
	glass = mix(glass, facets * (0.72 + depth * 0.4), 0.36);
	float glint = smoothstep(0.63, 0.86, flow.z + relief * 0.7) * smoothstep(0.55, 0.9, light);
	glass = mix(glass, vec3(0.9, 0.99, 1.0), glint * 0.7);
	return mix(source, glass, strength);
}

vec3 feather_heat(vec3 source, vec3 flow, float strength) {
	float light = dot(source, vec3(0.28, 0.62, 0.1));
	float heat = clamp(light * 0.73 + flow.y * 0.5 - 0.16, 0.0, 1.0);
	vec3 flame = mix(vec3(0.4, 0.055, 0.03), vec3(1.0, 0.26, 0.035), smoothstep(0.12, 0.4, heat));
	flame = mix(flame, vec3(1.0, 0.72, 0.22), smoothstep(0.35, 0.67, heat));
	flame = mix(flame, vec3(1.0, 0.96, 0.73), smoothstep(0.64, 0.86, heat));
	return mix(source, flame, strength);
}
