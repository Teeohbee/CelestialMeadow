shader_type canvas_item;

// Copperplate engraving with hand-applied watercolour, as on a tinted plate
// from an antique atlas. The sprite becomes:
// - a ruled ink outline
// - parallel engraved lines whose width swells with the sprite's darkness,
//   cross-hatched in the deepest shadow
// - an optional wash of colour laid on by hand: slightly out of register
//   with the outline, ragged at the edge, with pigment pooling at the rim
// Line sizes are in screen pixels so they read the same at every scale.

uniform vec4 ink : source_color = vec4(0.165, 0.125, 0.086, 1.0);
uniform vec4 paper : source_color = vec4(0.91, 0.863, 0.753, 1.0);
uniform vec4 wash_color : source_color = vec4(1.0);
uniform bool wash_from_tint = true;      // wash in the node's modulate colour
uniform bool wash_from_texture = false;  // wash in the art's own colours, faded
uniform float wash_strength = 0.85;
uniform vec2 wash_offset = vec2(1.5, 1.0);   // screen px out of register
uniform float wash_bleed = 1.5;              // screen px of ragged edge
uniform float wash_outside = 0.6;            // opacity of wash spilling past the outline
uniform float line_spacing = 5.5;            // screen px between engraved lines
uniform float line_angle = 0.0;              // degrees, in the sprite's own space
uniform float cross_angle = 70.0;            // degrees between hatch and cross-hatch
uniform float base_density = 0.12;           // light ruling over every surface
uniform float shade_strength = 1.0;          // from the sprite's darkness
uniform float cross_threshold = 0.65;
uniform float outline_px = 1.4;
uniform bool sphere_shading = false;         // shade as a lit sphere (planets)
uniform vec2 light_dir = vec2(-0.6, -0.55);
uniform float sphere_strength = 0.9;

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

// Coverage of engraved lines at angle `deg`, each `width` (0..1) of the
// spacing. Lines waver slightly, as a hand-pushed burin does.
float ruling(vec2 px, float scale, float deg, float width) {
	float a = radians(deg);
	vec2 dir = vec2(-sin(a), cos(a));
	float spacing = line_spacing * scale;
	float q = dot(px, dir) / spacing + (value_noise(px / (spacing * 6.0)) - 0.5) * 0.35;
	float d = abs(fract(q + 0.5) - 0.5) * 2.0;
	float aa = 1.2 / line_spacing;  // about half a screen pixel
	return 1.0 - smoothstep(width - aa, width + aa, d);
}

#define BODY(uv) smoothstep(0.35, 0.65, texture(TEXTURE, uv).a)

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	// Texture pixels per screen pixel, whatever the node's scale or rotation
	float scale = max(0.0001, 0.5 * (length(dFdx(px)) + length(dFdy(px))));
	vec2 one = scale * TEXTURE_PIXEL_SIZE;

	float body = BODY(UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	// Ruled outline just inside the silhouette
	float o = outline_px;
	float least = 1.0;
	for (int i = 0; i < 8; i++) {
		vec2 dir = vec2(cos(float(i) * TAU / 8.0), sin(float(i) * TAU / 8.0));
		least = min(least, BODY(UV + dir * o * one));
	}
	float outline = body * (1.0 - least);

	// Shading: darkness of the art plus, for planets, the unlit side
	float shade = base_density + (1.0 - lum) * shade_strength;
	if (sphere_shading) {
		vec2 n = (UV - 0.5) * 2.0;
		float nz = sqrt(max(0.0, 1.0 - dot(n, n)));
		float lit = dot(normalize(vec3(n, nz)), normalize(vec3(light_dir, 0.7)));
		shade += smoothstep(0.45, -0.35, lit) * sphere_strength;
	}
	shade = clamp(shade, 0.0, 1.4);
	float lines = ruling(px, scale, line_angle, min(shade, 1.0) * 0.55);
	float cross_amount = clamp((shade - cross_threshold) / (1.4 - cross_threshold), 0.0, 1.0);
	lines = max(lines, ruling(px, scale, line_angle + cross_angle, cross_amount * 0.5));
	lines *= body;

	// Watercolour wash: out of register, ragged, darker where it pools
	float wash = 0.0;
	if (wash_from_tint || wash_from_texture || wash_color.rgb != vec3(1.0)) {
		vec2 jitter = vec2(value_noise(px / (6.0 * scale)), value_noise(px / (6.0 * scale) + 17.0)) - 0.5;
		vec2 wuv = UV - (wash_offset + jitter * wash_bleed * 2.0) * one;
		wash = BODY(wuv);
		float ring = 0.0;
		for (int i = 0; i < 4; i++) {
			vec2 dir = vec2(cos(float(i) * TAU / 4.0 + 0.4), sin(float(i) * TAU / 4.0 + 0.4));
			ring += BODY(wuv + dir * 3.0 * one);
		}
		float rim = clamp(1.0 - ring * 0.25, 0.0, 1.0) * wash;
		vec3 pigment = wash_color.rgb;
		if (wash_from_tint) {
			pigment = tint.rgb;
		}
		if (wash_from_texture) {
			pigment = mix(vec3(lum), tex.rgb, 0.7);
		}
		float k = wash_strength * (0.85 + 0.25 * value_noise(px / (14.0 * scale))) + rim * 0.25;
		vec3 washed = paper.rgb * mix(vec3(1.0), pigment, clamp(k, 0.0, 1.0));
		vec3 base = mix(paper.rgb, washed, wash);
		COLOR.rgb = base;
	} else {
		COLOR.rgb = paper.rgb;
	}

	COLOR.rgb = mix(COLOR.rgb, ink.rgb, max(lines * 0.9, outline));
	float alpha = max(body, wash * wash_outside);
	COLOR.a = alpha * tint.a;
}
