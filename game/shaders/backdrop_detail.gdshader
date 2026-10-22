// The backdrop's fine detail, drawn at the screen's full resolution over the soft swirl
// (which is painted small and scaled up): Arlecchino's diamond seams, twinkling sparkles, a
// fine film grain that keeps the paint from looking flat, and a vignette that pulls the eye
// to the middle. Cheap: no loops. Output is premultiplied, so it can both darken (vignette,
// dark grain) and add light (seams, sparkles, light grain) in one pass.
shader_type canvas_item;
render_mode blend_premul_alpha;

uniform float phase = 0.0;
uniform float seams = 0.045;
uniform float sparkle = 1.0;
uniform float grain = 0.035;
uniform float vignette = 0.42;
uniform vec4 flash : source_color = vec4(1.0, 0.8, 0.4, 0.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 uv = UV * vec2(aspect, 1.0);

	// Diamond seams, antialiased at any resolution.
	vec2 q = uv * vec2(1.0, 1.0 / 1.4) * 9.0;
	vec2 f = fract(vec2(q.x + q.y, q.x - q.y));
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float w = fwidth(q.x + q.y) * 1.2;
	float seam = (1.0 - smoothstep(0.0, w, edge)) * seams;

	// Sparkles: a few cells of a fine grid twinkle as four-pointed stars.
	vec2 grid = uv * 30.0;
	vec2 cell = floor(grid);
	float h = hash(cell);
	float star = 0.0;
	if (h > 0.982) {
		vec2 g = fract(grid) - 0.5;
		float twinkle = pow(0.5 + 0.5 * sin(phase * 3.0 + h * 80.0), 3.0);
		float cross = max(smoothstep(0.035, 0.0, abs(g.x)) * smoothstep(0.32, 0.0, abs(g.y)),
			smoothstep(0.035, 0.0, abs(g.y)) * smoothstep(0.32, 0.0, abs(g.x)));
		float core = smoothstep(0.12, 0.0, length(g));
		star = (cross * 0.8 + core) * twinkle * sparkle * 0.6;
	}

	// Film grain, re-rolled a few times a second.
	float n = hash(FRAGCOORD.xy + floor(phase * 6.0) * vec2(17.0, 31.0)) - 0.5;

	// Vignette: darker toward the corners.
	vec2 c = UV - 0.5;
	float v = smoothstep(0.35, 0.95, length(c * vec2(1.0, 0.9)) * 1.35) * vignette;

	vec3 light = vec3(1.0, 0.93, 0.78) * (seam + star) + vec3(max(n, 0.0) * grain);
	float dark = clamp(v + max(-n, 0.0) * grain, 0.0, 1.0);
	light += flash.rgb * flash.a * 0.25;
	COLOR = vec4(light, dark);
}
