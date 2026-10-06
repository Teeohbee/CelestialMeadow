shader_type canvas_item;

// Cream riso paper: fibre grain plus two faint halftone washes in opposite
// corners. Local (world) space so it moves with camera shake.

uniform vec4 paper : source_color = vec4(0.97, 0.955, 0.915, 1.0);
uniform vec4 wash_a : source_color = vec4(1.0, 0.91, 0.0, 1.0);     // riso Yellow, top-left
uniform vec4 wash_b : source_color = vec4(0.196, 0.333, 0.643, 1.0); // riso Medium Blue, bottom-right
uniform float wash_a_strength = 0.55;
uniform float wash_b_strength = 0.3;
uniform float wash_radius = 0.3;  // fraction of width
uniform vec2 size = vec2(2048.0, 1208.0);
uniform float dot_cell = 14.0;
uniform float grain = 0.04;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float halftone(vec2 p, float amount) {
	vec2 cell = fract(p / dot_cell) - 0.5;
	float r = sqrt(clamp(amount, 0.0, 1.0)) * 0.62;
	return 1.0 - smoothstep(r - 0.06, r + 0.06, length(cell));
}

void fragment() {
	float a = max(0.0, 1.0 - length(local_pos) / (size.x * wash_radius));
	float b = max(0.0, 1.0 - length(size - local_pos) / (size.x * wash_radius));
	vec3 col = paper.rgb;
	col *= mix(vec3(1.0), wash_a.rgb, halftone(local_pos, a) * wash_a_strength);
	col *= mix(vec3(1.0), wash_b.rgb, halftone(local_pos + dot_cell * 0.5, b) * wash_b_strength);
	col *= 1.0 - grain * hash(floor(local_pos));
	COLOR = vec4(col, 1.0);
}
