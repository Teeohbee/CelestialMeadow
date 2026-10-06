shader_type canvas_item;

// A loose blot of watercolour laid behind a ship, in the node's modulate
// colour, so each player reads from across the room. Ragged edge, uneven
// density, and the darker rim where pigment dries at the edge of a wash.

uniform float strength = 0.5;
uniform float edge = 0.8;          // radius of the blot, 0..1 of the node
uniform float raggedness = 0.22;
uniform float rim = 0.55;

varying vec4 tint;

void vertex() {
	tint = COLOR;
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

void fragment() {
	vec2 c = (UV - 0.5) * 2.0;
	float r = length(c);
	float angle = atan(c.y, c.x);
	float wobble = value_noise(vec2(angle * 2.2, 3.0)) * 0.6 + value_noise(UV * 9.0) * 0.4;
	float e = edge * (1.0 - raggedness * 0.5 + raggedness * wobble);
	float inside = 1.0 - smoothstep(e - 0.02, e + 0.02, r);
	float pooled = smoothstep(e - 0.16, e - 0.02, r) * inside;
	float density = (0.55 + 0.35 * value_noise(UV * 5.0 + 7.0)) * inside + pooled * rim;
	COLOR = vec4(tint.rgb, clamp(density, 0.0, 1.0) * strength * tint.a);
}
