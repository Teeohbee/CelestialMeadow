class_name Poster

## Drawing helpers shared by the Grand Tour poster style: flat round-capped
## bars, dashed circles and tracked display type in Josefin Sans.

const FONT_FILE = preload("res://fonts/JosefinSans-Variable.ttf")
const WGHT: int = 2003265652  # OpenType 'wght' axis tag

static var _fonts: Dictionary = {}

## Josefin Sans at a weight (600 semibold, 700 bold) with extra tracking
static func font(weight: int = 600, tracking: int = 0) -> Font:
	var key = Vector2i(weight, tracking)
	if not _fonts.has(key):
		var f = FontVariation.new()
		f.base_font = FONT_FILE
		f.variation_opentype = {WGHT: weight}
		f.spacing_glyph = tracking
		_fonts[key] = f
	return _fonts[key]

## A filled bar with round ends, as one polygon so translucent bars don't
## darken where the caps meet the body
static func bar(ci: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var r = width * 0.5
	var dir = to - from
	if dir.length() < 0.01:
		ci.draw_circle(from, r, color)
		return
	var a = dir.angle()
	var pts = PackedVector2Array()
	for i in 9:
		pts.append(to + Vector2.from_angle(a - PI / 2 + PI * i / 8.0) * r)
	for i in 9:
		pts.append(from + Vector2.from_angle(a + PI / 2 + PI * i / 8.0) * r)
	ci.draw_colored_polygon(pts, color)

static func dashed_circle(ci: CanvasItem, center: Vector2, radius: float, dash: float, gap: float, color: Color, width: float) -> void:
	var step = (dash + gap) / radius
	var on = dash / radius
	var a = 0.0
	while a < TAU:
		ci.draw_arc(center, radius, a, minf(a + on, TAU), 6, color, width, true)
		a += step

static func circle_points(center: Vector2, radius: float, segments: int = 48) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in segments:
		pts.append(center + Vector2.from_angle(TAU * i / segments) * radius)
	return pts

## Text centred on x, baseline at y
static func text_centred(ci: CanvasItem, pos: Vector2, text: String, size: int, color: Color, weight: int = 600, tracking: int = 0) -> void:
	var f = font(weight, tracking)
	var w = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(f, pos - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
