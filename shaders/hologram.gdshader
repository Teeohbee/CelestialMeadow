shader_type canvas_item;

// Holographic projection: translucent, screen-space scanlines, bright rim and
// an occasional flicker/glitch. Tinted by the node's modulate/self_modulate.

uniform float rim_width = 6.0;         // in texture pixels
uniform float rim_strength = 2.0;      // > 1.0 blooms
uniform float body_alpha = 0.35;
uniform float body_strength = 1.0;
uniform float scanline_spacing = 4.0;  // screen pixels between lines
uniform float scanline_speed = 20.0;
uniform float flicker_amount = 0.15;
uniform float glitch_amount = 0.01;    // UV shift during a glitch band

varying vec4 tint;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void vertex() {
	tint = COLOR;
}

void fragment() {
	// Occasional horizontal glitch band
	float tick = floor(TIME * 8.0);
	float band = step(0.92, hash(tick)) * step(abs(SCREEN_UV.y - hash(tick + 1.0)), 0.04);
	vec2 uv = UV + vec2(band * glitch_amount * (hash(tick + 2.0) - 0.5) * 2.0, 0.0);

	vec4 tex = texture(TEXTURE, uv);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	vec2 px = TEXTURE_PIXEL_SIZE * rim_width;
	float min_alpha = 1.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * TAU / 8.0;
		min_alpha = min(min_alpha, texture(TEXTURE, uv + vec2(cos(angle), sin(angle)) * px).a);
	}
	float rim = tex.a * (1.0 - min_alpha);

	float scan = 0.65 + 0.35 * sin((FRAGCOORD.y + TIME * scanline_speed) * TAU / scanline_spacing);
	float flicker = 1.0 - flicker_amount * step(0.9, hash(floor(TIME * 15.0)));

	vec3 col = tint.rgb * (lum * body_strength * scan + rim * rim_strength);
	float alpha = clamp(tex.a * body_alpha * scan + rim, 0.0, 1.0);
	COLOR = vec4(col, alpha * flicker * tint.a);
}
