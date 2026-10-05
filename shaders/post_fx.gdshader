shader_type canvas_item;

// Full-screen pass: chromatic aberration (pulsed on explosions), scanlines
// and vignette.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float aberration = 0.0;        // screen pixels at the edges
uniform float scanline_alpha = 0.08;
uniform float scanline_spacing = 3.0;  // screen pixels
uniform float vignette = 0.45;

void fragment() {
	vec2 from_centre = SCREEN_UV - 0.5;
	vec2 offset = from_centre * 2.0 * aberration * SCREEN_PIXEL_SIZE;
	vec3 col;
	col.r = texture(screen_tex, SCREEN_UV + offset).r;
	col.g = texture(screen_tex, SCREEN_UV).g;
	col.b = texture(screen_tex, SCREEN_UV - offset).b;

	float scan = 1.0 - scanline_alpha * step(0.5, fract(FRAGCOORD.y / scanline_spacing));
	float vig = 1.0 - vignette * dot(from_centre, from_centre) * 2.0;
	COLOR = vec4(col * scan * vig, 1.0);
}
