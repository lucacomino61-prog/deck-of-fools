// The light CRT look: scanlines and a soft vignette laid over the screen as a dark veil.
// Unlike the full CRT it doesn't copy the screen, so it costs almost nothing.
shader_type canvas_item;

uniform float scanline = 0.12;
uniform float vignette = 0.3;

void fragment() {
	vec2 c = SCREEN_UV * 2.0 - 1.0;
	float period = max(2.0, floor(1.0 / SCREEN_PIXEL_SIZE.y / 240.0));
	float line = scanline * step(period * 0.6, mod(FRAGCOORD.y, period));
	float edge = vignette * dot(c, c) * 0.5;
	COLOR = vec4(0.0, 0.0, 0.0, 1.0 - (1.0 - line) * (1.0 - edge));
}
