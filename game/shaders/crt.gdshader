// CRT look over the whole screen: a slight barrel curve, scanlines, a soft vignette and a
// touch of colour fringing. Reduce motion sets curvature to 0.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float curvature = 0.03;
uniform float scanline = 0.16;
uniform float vignette = 0.32;
uniform float aberration = 0.0012;

void fragment() {
	vec2 c = SCREEN_UV * 2.0 - 1.0;
	c *= 1.0 + curvature * dot(c, c);
	vec2 uv = c * 0.5 + 0.5;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 col;
		col.r = texture(screen_tex, uv + vec2(aberration, 0.0)).r;
		col.g = texture(screen_tex, uv).g;
		col.b = texture(screen_tex, uv - vec2(aberration, 0.0)).b;
		float period = max(2.0, floor(1.0 / SCREEN_PIXEL_SIZE.y / 240.0));
		col *= 1.0 - scanline * step(period * 0.6, mod(FRAGCOORD.y, period));
		col *= 1.0 - vignette * dot(c, c) * 0.5;
		COLOR = vec4(col * 1.06, 1.0);
	}
}
