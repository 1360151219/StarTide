shader_type canvas_item;
render_mode unshaded;

uniform float age = 0.0;
uniform float front = 0.78;
uniform float opacity = 1.0;
uniform float variation = 0.0;
uniform bool warning = false;

void fragment() {
	vec2 q = (UV * 2.0 - 1.0) * 1.12;
	float r = length(q);
	float coarse = texture(TEXTURE, UV * 1.3 + vec2(variation, -age * 0.1)).r;
	float detail = texture(TEXTURE, UV * 3.1 - vec2(age * 0.19, variation)).r;
	float noise = coarse * 0.65 + detail * 0.35;
	vec3 color;
	float alpha;
	if (warning) {
		float warm = pow(max(0.0, 1.0 - r), 2.0);
		color = mix(vec3(0.28, 0.16, 0.1), vec3(1.0, 0.63, 0.16), coarse);
		alpha = warm * 0.22 * opacity;
	} else {
		// The front is tied to the actual damage radius, not the slower drifting ash.
		float rolling = exp(-pow((r - front * 0.81 + (noise - 0.5) * 0.22) / 0.17, 2.0));
		float broken = smoothstep(0.28 + age * 0.28, 0.58 + age * 0.2, noise);
		float rim = rolling * broken * (1.0 - smoothstep(0.04, 0.58, age));
		float scorch = pow(max(0.0, 1.0 - r / 0.72), 1.1) * smoothstep(0.28, 0.57, noise);
		float flash = (1.0 - smoothstep(0.0, 0.07, age)) * pow(max(0.0, 1.0 - r), 0.8);
		color = mix(vec3(0.3, 0.2, 0.15), vec3(0.79, 0.64, 0.39), clamp(rim * 2.0, 0.0, 1.0));
		color = mix(color, vec3(1.0, 0.82, 0.35), flash);
		alpha = (rim * 0.67 + scorch * 0.24 + flash * 0.5) * opacity;
	}
	COLOR = vec4(color, alpha * (1.0 - smoothstep(0.95, 1.0, r)));
}
