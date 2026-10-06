shader_type canvas_item;

// Risograph print on a dark ink flood. The sky is a solid flood of dark ink;
// each sprite is a knockout (a hole in the flood showing cream paper) with
// its inks printed into the hole. The hole is trapped slightly out of
// register, so a sliver of bare paper shows on one side and ink spills onto
// the flood on the other. Inks multiply with whatever they print over.

uniform vec4 paper : source_color = vec4(0.97, 0.955, 0.915, 1.0);
uniform vec4 flood : source_color = vec4(0.11, 0.13, 0.24, 1.0);         // must match the background flood
uniform vec4 second_ink : source_color = vec4(0.196, 0.333, 0.643, 1.0); // riso Medium Blue
uniform vec2 trap = vec2(-4.0, -4.0);       // knockout hole offset from the ink, texture pixels
uniform vec2 misregister = vec2(5.0, 5.0);  // second-ink silhouette offset, texture pixels
uniform float fill = 0.95;                  // coverage of the main ink
uniform float shade_strength = 0.85;        // halftone from the sprite's dark areas
uniform float offset_strength = 0.9;        // coverage of the misregistered silhouette
uniform bool shade_in_main_ink = false;     // halftone shading in the main ink instead of the second
uniform bool halftone_knockout = false;     // knock out a halftone of the sprite instead of a solid hole (background objects)
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

float silhouette(sampler2D tex, vec2 uv) {
	return step(0.5, texture(tex, uv).a);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float body = step(0.5, tex.a);

	float offset_cov = silhouette(TEXTURE, UV - misregister * TEXTURE_PIXEL_SIZE) * (1.0 - body) * offset_strength;
	float shade_cov = body * halftone(FRAGCOORD.xy, (1.0 - lum) * shade_strength);

	float hole;
	float alpha;
	vec3 main_ink;
	vec3 second;
	if (halftone_knockout) {
		hole = body * halftone(FRAGCOORD.xy, fill + lum * shade_strength);
		alpha = hole;
		main_ink = tint.rgb;
		second = mix(vec3(1.0), second_ink.rgb, offset_cov);
	} else {
		hole = silhouette(TEXTURE, UV - trap * TEXTURE_PIXEL_SIZE);
		alpha = max(hole, max(body, step(0.001, offset_cov)));
		if (shade_in_main_ink) {
			main_ink = mix(vec3(1.0), tint.rgb, max(body * fill, shade_cov));
			second = mix(vec3(1.0), second_ink.rgb, offset_cov);
		} else {
			main_ink = mix(vec3(1.0), tint.rgb, body * fill);
			second = mix(vec3(1.0), second_ink.rgb, max(offset_cov, shade_cov));
		}
	}

	vec3 base = mix(flood.rgb, paper.rgb, hole);
	COLOR = vec4(base * main_ink * second, alpha * tint.a);
}
