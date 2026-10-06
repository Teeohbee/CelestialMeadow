shader_type canvas_item;
render_mode blend_mul;

// Risograph print: the sprite is printed as flat ink (its modulate colour),
// shaded with screen-space halftone dots in a second ink, with a misregistered
// copy of the silhouette in that second ink. Multiplied onto the paper below,
// so overlapping prints mix like real ink. Output white = no ink.

uniform vec4 second_ink : source_color = vec4(0.196, 0.333, 0.643, 1.0); // riso Medium Blue
uniform vec2 misregister = vec2(5.0, 5.0);  // texture pixels
uniform float fill = 0.95;                  // coverage of the main ink
uniform float shade_strength = 0.85;        // halftone from the sprite's dark areas
uniform float offset_strength = 0.9;        // coverage of the misregistered silhouette
uniform float knockout = 1.0;               // 1 = offset only prints where the main ink doesn't
uniform bool shade_in_main_ink = false;     // halftone shading in the main ink instead of the second
uniform float dot_cell = 7.0;               // halftone cell size in screen pixels
uniform float dot_angle = 15.0;             // degrees

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

float halftone(vec2 p, float amount) {
	float a = radians(dot_angle);
	p = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a))) * p;
	vec2 cell = fract(p / dot_cell) - 0.5;
	float r = sqrt(clamp(amount, 0.0, 1.0)) * 0.62;
	return 1.0 - smoothstep(r - 0.08, r + 0.08, length(cell));
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float body = step(0.5, tex.a);

	float offset_alpha = step(0.5, texture(TEXTURE, UV - misregister * TEXTURE_PIXEL_SIZE).a);
	float offset_cov = offset_alpha * mix(1.0, 1.0 - body, knockout) * offset_strength;
	float shade_cov = body * halftone(FRAGCOORD.xy, (1.0 - lum) * shade_strength);

	vec3 main_ink;
	vec3 second;
	if (shade_in_main_ink) {
		main_ink = mix(vec3(1.0), tint.rgb, max(body * fill, shade_cov));
		second = mix(vec3(1.0), second_ink.rgb, offset_cov);
	} else {
		main_ink = mix(vec3(1.0), tint.rgb, body * fill);
		second = mix(vec3(1.0), second_ink.rgb, max(offset_cov, shade_cov));
	}
	COLOR = vec4(mix(vec3(1.0), main_ink * second, tint.a), 1.0);
}
