// The backdrop: slow swirling paint in five tones (three bands, a crest and a streak of a
// contrasting accent), with Arlecchino's diamond seams showing faintly through and a few
// sparkles twinkling. Smooth (HD): it's drawn small off-screen and scaled up, which is cheap
// and soft. Feel drives `phase` (scoring spins it faster without a jump), tweens the five
// colours for the mood and the town, and `flash` lights it up on big moments.
// Reduce motion stops `phase`, which holds the picture still.
shader_type canvas_item;

uniform vec4 c0 : source_color = vec4(0.063, 0.027, 0.098, 1.0);
uniform vec4 c1 : source_color = vec4(0.196, 0.078, 0.286, 1.0);
uniform vec4 c2 : source_color = vec4(0.431, 0.133, 0.392, 1.0);
uniform vec4 c3 : source_color = vec4(0.753, 0.271, 0.486, 1.0);
uniform vec4 c4 : source_color = vec4(0.227, 0.651, 0.729, 1.0);
uniform vec4 flash : source_color = vec4(1.0, 0.8, 0.4, 0.0);
uniform float phase = 0.0;
uniform float twist = 3.0;
uniform float seams = 0.025;
uniform float sparkle = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 uv = UV * vec2(aspect, 1.0);
	vec2 c = uv - vec2(aspect * 0.5, 0.5);
	float t = phase;
	float r = length(c);
	float a = atan(c.y, c.x) + twist * r * (1.0 + 0.25 * sin(t * 0.5)) - t * 0.7;
	vec2 p = vec2(cos(a), sin(a)) * r * 4.0;
	for (int i = 1; i < 5; i++) {
		float n = float(i);
		p += vec2(sin(p.y * 0.8 * n + t * 1.0 * n), cos(p.x * 0.7 * n - t * 0.8 * n)) * (0.75 / n);
	}
	float v = 0.5 + 0.5 * sin(p.x * 1.2 + p.y * 0.9 + t * 1.5);
	float w = 0.5 + 0.5 * sin(p.x * 0.7 - p.y * 1.4 - t * 1.1 + r * 4.0);
	vec3 col = mix(c0.rgb, c1.rgb, smoothstep(0.15, 0.4, v));
	col = mix(col, c2.rgb, smoothstep(0.45, 0.68, v));
	col = mix(col, c3.rgb, smoothstep(0.8, 0.92, v) * 0.85);
	col = mix(col, c4.rgb, smoothstep(0.86, 0.97, w) * 0.7);

	vec2 q = uv * vec2(1.0, 1.0 / 1.4) * 9.0;
	vec2 f = fract(vec2(q.x + q.y, q.x - q.y));
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	col += seams * (1.0 - smoothstep(0.0, 0.05, edge));

	vec2 grid = uv * 30.0;
	vec2 cell = floor(grid);
	float h = hash(cell);
	if (h > 0.982) {
		vec2 g = fract(grid) - 0.5;
		float twinkle = pow(0.5 + 0.5 * sin(t * 3.0 + h * 80.0), 3.0);
		float star = smoothstep(0.28, 0.0, abs(g.x) + abs(g.y));
		col += vec3(1.0, 0.93, 0.75) * star * twinkle * sparkle * 0.55;
	}
	col = mix(col, flash.rgb, flash.a);
	COLOR = vec4(col, 1.0);
}
