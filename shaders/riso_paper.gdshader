shader_type canvas_item;

// The sky: cream paper under a dense flood of dark ink, printed slightly
// unevenly. Stars are tiny knockouts showing the paper; nebulae are halftone
// knockouts printed in a second ink. Local (world) space so it moves with
// camera shake.

uniform vec4 paper : source_color = vec4(0.97, 0.955, 0.915, 1.0);
uniform vec4 flood : source_color = vec4(0.11, 0.13, 0.24, 1.0);     // black over blue
uniform vec4 nebula_a : source_color = vec4(0.463, 0.357, 0.655, 1.0); // riso Violet
uniform vec4 nebula_b : source_color = vec4(0.0, 0.514, 0.541, 1.0); // riso Teal
uniform float nebula_strength = 0.4;
uniform vec2 size = vec2(2048.0, 1208.0);
uniform float dot_cell = 12.0;
uniform float star_cell = 48.0;
uniform float star_density = 0.14;
uniform float unevenness = 0.08;
uniform float grain = 0.05;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float halftone(vec2 p, float amount) {
	vec2 cell = fract(p / dot_cell) - 0.5;
	float r = sqrt(clamp(amount, 0.0, 1.0)) * 0.62;
	return 1.0 - smoothstep(r - 0.06, r + 0.06, length(cell));
}

float blob(vec2 centre, float radius) {
	float n = value_noise(local_pos / 140.0) * 0.5;
	return clamp(1.0 - length(local_pos - centre * size) / (radius * size.x) - n * 0.4, 0.0, 1.0);
}

void fragment() {
	vec3 col = flood.rgb * (1.0 - unevenness * 0.5 + unevenness * value_noise(local_pos / 260.0));

	float a = blob(vec2(0.18, 0.22), 0.26) * nebula_strength;
	float b = blob(vec2(0.82, 0.78), 0.22) * nebula_strength;
	col = mix(col, paper.rgb * nebula_a.rgb, halftone(local_pos, a));
	col = mix(col, paper.rgb * nebula_b.rgb, halftone(local_pos + dot_cell * 0.5, b));

	vec2 cell = floor(local_pos / star_cell);
	if (hash(cell) < star_density) {
		vec2 pos = (cell + vec2(hash(cell + 1.7), hash(cell + 3.1))) * star_cell;
		float r = 0.8 + 2.2 * hash(cell + 5.3) * hash(cell + 7.9);
		col = mix(col, paper.rgb, 1.0 - smoothstep(r - 0.6, r + 0.6, length(local_pos - pos)));
	}

	col *= 1.0 - grain * hash(floor(local_pos));
	COLOR = vec4(col, 1.0);
}
