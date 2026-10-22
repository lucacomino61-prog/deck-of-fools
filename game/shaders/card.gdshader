// A card face: a fake 3D tilt toward the pointer (the far edge shrinks, as in perspective),
// a soft highlight that slides with the tilt, and the foil of special editions:
// 1 Silvered (a cool metallic sweep), 2 Opaline (pink-pearl shimmer), 3 Prismatic (a moving
// rainbow), 4 Shadow (a dark sheen).
// A card with a sway index (0 or more) also sways and wobbles gently on its own, here from
// TIME, so a resting card costs the CPU nothing; `tilt` only changes while the pointer is on
// the card.
shader_type canvas_item;

uniform vec2 tilt = vec2(0.0);
uniform vec2 card_size = vec2(60.0, 84.0);
uniform int foil = 0;
uniform float sway = -1.0;
uniform float shine = 1.0;

varying vec2 local_uv;
varying vec2 total_tilt;

void vertex() {
	vec2 c = card_size * 0.5;
	vec2 p = VERTEX - c;
	total_tilt = tilt;
	if (sway >= 0.0) {
		total_tilt += vec2(sin(TIME * 1.1 + sway), cos(TIME * 0.8 + sway * 1.3)) * 0.18;
		float a = sin(TIME * 1.6 + sway * 0.9) * 0.025;
		p = vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
	}
	float depth = 1.0 + (p.x / card_size.x) * total_tilt.x * 0.16 + (p.y / card_size.y) * total_tilt.y * 0.16;
	VERTEX = c + p / depth;
	local_uv = UV;
}

vec3 hue(float h) {
	return clamp(abs(fract(h + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 col = base.rgb;
	vec2 uv = local_uv - 0.5;
	// The highlight: a broad diagonal band that moves opposite the tilt.
	float band = dot(uv, normalize(vec2(1.0, -0.7))) + total_tilt.x * 0.35 - total_tilt.y * 0.25;
	float gloss = smoothstep(0.22, 0.0, abs(band)) * 0.16 * shine * length(total_tilt + vec2(0.15));
	if (foil == 1) {
		float sweep = smoothstep(0.3, 0.0, abs(band * 1.4)) ;
		col = mix(col, col * 0.85 + vec3(0.55, 0.62, 0.7) * 0.35, 0.35) + sweep * 0.22;
	} else if (foil == 2) {
		vec3 pearl = mix(vec3(1.0, 0.75, 0.9), vec3(0.75, 0.9, 1.0), 0.5 + 0.5 * sin(band * 9.0 + TIME * 0.8));
		col = mix(col, col * pearl * 1.15, 0.45);
	} else if (foil == 3) {
		vec3 rainbow = hue(band * 1.6 + uv.y * 0.6 + TIME * 0.12);
		col = mix(col, col * 0.6 + rainbow * 0.55, 0.42);
	} else if (foil == 4) {
		col = mix(col, col * vec3(0.55, 0.5, 0.7), 0.4) + smoothstep(0.25, 0.0, abs(band)) * 0.1;
	}
	COLOR = vec4(col + gloss, base.a) * COLOR;
}
