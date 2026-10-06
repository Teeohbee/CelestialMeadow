shader_type canvas_item;

// Film grain over the whole frame, redrawn a dozen times a second
uniform float strength = 0.22;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float frame = floor(TIME * 12.0);
	float n = hash(floor(FRAGCOORD.xy) + frame * vec2(17.0, 31.0));
	COLOR = vec4(vec3(step(0.5, n)), abs(n - 0.5) * strength * 0.5);
}
