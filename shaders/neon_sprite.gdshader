shader_type canvas_item;

// Turns a sprite into a neon sign: bright outline plus glowing interior detail,
// tinted by the node's modulate/self_modulate so existing colour code still works.

uniform float outline_width = 4.0;    // in texture pixels
uniform float glow_strength = 2.5;    // > 1.0 so the WorldEnvironment glow blooms it
uniform float detail_strength = 0.8;  // brightness of internal edges (sprite detail)
uniform float fill_strength = 0.12;   // faint body so shapes aren't hollow

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	float min_alpha = 1.0;
	float lum_diff = 0.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * TAU / 8.0;
		vec4 n = texture(TEXTURE, UV + vec2(cos(angle), sin(angle)) * px);
		min_alpha = min(min_alpha, n.a);
		lum_diff = max(lum_diff, abs(lum - dot(n.rgb, vec3(0.299, 0.587, 0.114))) * n.a);
	}

	float edge = tex.a * (1.0 - min_alpha);
	float detail = tex.a * smoothstep(0.08, 0.3, lum_diff) * detail_strength;
	float line = max(edge, detail);

	vec3 col = tint.rgb * (line * glow_strength + fill_strength);
	COLOR = vec4(col, clamp(line + tex.a * fill_strength, 0.0, 1.0) * tint.a);
}
