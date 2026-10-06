shader_type canvas_item;

// Hand-made laid paper, the kind 17th and 18th century star atlases were
// printed on: faint laid lines and chain lines from the paper mould, uneven
// tone, foxing spots and edges browned by age. World space, so it moves with
// camera shake.

uniform vec4 paper : source_color = vec4(0.91, 0.863, 0.753, 1.0);
uniform vec4 toning : source_color = vec4(0.62, 0.47, 0.25, 1.0);   // age browning at the edges
uniform vec4 foxing : source_color = vec4(0.55, 0.36, 0.18, 1.0);
uniform vec2 size = vec2(2048.0, 1208.0);
uniform float mottle = 0.06;
uniform float laid_spacing = 3.5;
uniform float laid_strength = 0.025;
uniform float chain_spacing = 96.0;
uniform float chain_strength = 0.04;
uniform float edge_toning = 0.42;
uniform float fox_density = 0.035;

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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * value_noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = local_pos;
	vec3 col = paper.rgb * (1.0 - mottle + 2.0 * mottle * fbm(p / 180.0));

	// Mould marks: fine laid lines one way, sparse chain lines the other,
	// both wavering slightly as wire does
	float laid = abs(fract((p.y + value_noise(p / 40.0) * 2.0) / laid_spacing) - 0.5);
	col *= 1.0 - laid_strength * smoothstep(0.3, 0.5, laid);
	float chain = abs(fract((p.x + value_noise(p / 90.0) * 6.0) / chain_spacing) - 0.5) * chain_spacing;
	col *= 1.0 - chain_strength * (1.0 - smoothstep(0.6, 1.8, chain));

	// Browning towards the edges, irregular like real toning
	vec2 uv = p / size;
	float edge = length((uv - 0.5) * vec2(1.0, 0.8)) * 1.5;
	edge = smoothstep(0.45, 1.05, edge + (fbm(p / 120.0) - 0.5) * 0.25);
	col = mix(col, col * toning.rgb, edge * edge_toning);

	// Foxing: sparse rusty spots with a darker rim
	vec2 cell = floor(p / 140.0);
	if (hash(cell) < fox_density * 4.0) {
		vec2 centre = (cell + vec2(hash(cell + 1.3), hash(cell + 2.9))) * 140.0;
		float r = 3.0 + 14.0 * hash(cell + 4.1) * hash(cell + 6.7);
		float d = length(p - centre) / r + (value_noise(p / 5.0) - 0.5) * 0.5;
		float spot = 1.0 - smoothstep(0.7, 1.0, d);
		float rim = spot * smoothstep(0.4, 0.9, d);
		col = mix(col, col * foxing.rgb, spot * 0.25 + rim * 0.2);
	}

	COLOR = vec4(col, 1.0);
}
