shader_type canvas_item;
render_mode unshaded;

uniform sampler2D turbulence : repeat_enable, filter_linear;
uniform float age = 0.0;
uniform float variation = 0.0;
uniform float opacity = 1.0;
uniform int form = 0;
uniform vec2 hero_position = vec2(-100000.0);
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 uv = UV;
	vec2 flow = vec2(variation, age * 0.85);
	float large = texture(turbulence, uv * vec2(0.9, 0.7) + flow * 0.47).r;
	vec2 warped = uv + vec2(large - 0.5, large * 0.25) * 0.3;
	float detail = texture(turbulence, warped * 1.85 + flow).r;
	float fine = texture(turbulence, warped * 4.3 - flow * 0.65).r;
	float billow = large * 0.46 + detail * 0.46 + fine * 0.08;
	float heat;
	float alpha;
	vec3 color;
	if (form == 0) {
		// The rock travels downward; different texture speeds make the wake roll upward.
		float width = pow(max(uv.y, 0.0), 0.72) * 0.32;
		float axis = uv.x - 0.5 + (large - 0.5) * (1.0 - uv.y) * 0.38;
		float mass = 1.0 - abs(axis) / max(width, 0.001);
		float density = mass + billow * 0.95 - 0.57 - (1.0 - uv.y) * 0.33;
		alpha = smoothstep(0.02, 0.2, density) * smoothstep(0.015, 0.13, uv.y) * (1.0 - smoothstep(0.87, 0.99, uv.y));
		heat = clamp(density * 0.72 + uv.y * 0.36 + detail * 0.15, 0.0, 1.0);
	} else {
		vec2 q = uv * 2.0 - 1.0;
		float mass = 1.0 - length(q);
		float density = mass + billow * 0.7 - 0.3;
		alpha = smoothstep(0.01, 0.19, density) * (1.0 - smoothstep(0.83, 1.0, length(q)));
		heat = clamp(density * 0.78 + detail * 0.44 - uv.y * 0.13, 0.0, 1.0);
	}
	color = mix(vec3(0.43, 0.12, 0.06), vec3(0.96, 0.27, 0.045), smoothstep(0.02, 0.4, heat));
	color = mix(color, vec3(1.0, 0.68, 0.16), smoothstep(0.38, 0.72, heat));
	color = mix(color, vec3(1.0, 0.96, 0.67), smoothstep(0.7, 0.97, heat));
	if (form == 1) {
		float cooling = smoothstep(0.1, 0.42, age);
		float lit = texture(turbulence, warped * 1.85 + flow + vec2(-0.055, -0.045)).r - detail;
		vec3 ash = mix(vec3(0.35, 0.29, 0.27), vec3(0.78, 0.69, 0.52), clamp(0.4 + lit * 2.5 + large * 0.35, 0.0, 1.0));
		color = mix(color, ash, cooling);
		alpha *= mix(1.0, 0.5, cooling);
	}
	if (form == 2) {
		vec4 rock = texture(TEXTURE, UV);
		float molten = max(rock.r - rock.b, 0.0);
		color = rock.rgb * 1.16 + vec3(0.18, 0.07, 0.0) * molten * detail;
		alpha = rock.a;
	}
	float hero_mask = smoothstep(0.78, 1.2, length((world_position - hero_position - vec2(0.0, -20.0)) / vec2(28.0, 55.0)));
	COLOR = vec4(color, alpha * opacity * hero_mask);
}
