shader_type canvas_item;

// Faint neon grid over a dark purple gradient, in local (world) space so it
// moves with camera shake.

uniform vec4 line_color : source_color = vec4(0.55, 0.2, 1.0, 1.0);
uniform float spacing = 64.0;
uniform float line_width = 1.2;
uniform int major_every = 4;
uniform float intensity = 0.14;
uniform vec4 top_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.07, 0.0, 0.12, 1.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float grid_line(vec2 p, float cell, float width) {
	vec2 d = abs(fract(p / cell + 0.5) - 0.5) * cell;
	return 1.0 - smoothstep(0.0, width, min(d.x, d.y));
}

void fragment() {
	float minor = grid_line(local_pos, spacing, line_width);
	float major = grid_line(local_pos, spacing * float(major_every), line_width * 1.5);
	float pulse = 0.85 + 0.15 * sin(TIME * 1.5);
	vec3 bg = mix(top_color.rgb, bottom_color.rgb, UV.y);
	vec3 lines = line_color.rgb * (minor * intensity + major * intensity * 2.0) * pulse;
	COLOR = vec4(bg + lines, 1.0);
}
