extends Node2D

## The engraved plate printed on the paper: a graticule of right ascension
## and declination, the graduated ecliptic, constellation figures with
## magnitude-graded star symbols, and a neatline border with a degree scale.
## Conventions follow the copperplate atlases of Hevelius (1690),
## Doppelmayr (1742) and Bode (1801). Drawn once; nothing here animates.

const FIELD_STAR_COUNT: int = 260
const FIELD_STAR_SEED: int = 1690

# Constellations in screen fractions. Each star is [x, y, magnitude];
# lines join star indices. Shapes follow the real asterisms, loosely placed.
const CONSTELLATIONS: Array = [
	{
		"name": "Ursa Major", "label": Vector2(0.43, 0.215),
		"stars": [[0.29, 0.10, 2], [0.29, 0.175, 2], [0.36, 0.19, 2], [0.37, 0.13, 3], [0.43, 0.115, 2], [0.49, 0.105, 2], [0.55, 0.145, 2]],
		"lines": [[0, 1], [1, 2], [2, 3], [3, 0], [3, 4], [4, 5], [5, 6]],
	},
	{
		"name": "Orion", "label": Vector2(0.185, 0.70),
		"stars": [[0.14, 0.40, 1], [0.22, 0.415, 2], [0.165, 0.52, 2], [0.18, 0.51, 2], [0.195, 0.50, 2], [0.15, 0.63, 3], [0.225, 0.62, 1], [0.18, 0.335, 4]],
		"lines": [[0, 7], [7, 1], [0, 2], [1, 4], [2, 3], [3, 4], [2, 5], [4, 6]],
	},
	{
		"name": "Lyra", "label": Vector2(0.655, 0.965),
		"stars": [[0.615, 0.80, 1], [0.64, 0.835, 4], [0.66, 0.895, 3], [0.635, 0.92, 3], [0.615, 0.865, 4]],
		"lines": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 1]],
	},
	{
		"name": "Cygnus", "label": Vector2(0.86, 0.50),
		"stars": [[0.80, 0.54, 1], [0.80, 0.645, 2], [0.80, 0.80, 3], [0.735, 0.625, 3], [0.865, 0.665, 3], [0.70, 0.59, 4], [0.905, 0.72, 4]],
		"lines": [[0, 1], [1, 2], [3, 1], [1, 4], [5, 3], [4, 6]],
	},
	{
		"name": "Cassiopeia", "label": Vector2(0.86, 0.29),
		"stars": [[0.78, 0.13, 2], [0.815, 0.21, 2], [0.85, 0.165, 3], [0.89, 0.225, 3], [0.925, 0.155, 3]],
		"lines": [[0, 1], [1, 2], [2, 3], [3, 4]],
	},
	{
		"name": "Corona Borealis", "label": Vector2(0.47, 0.93),
		"stars": [[0.40, 0.86, 4], [0.415, 0.82, 4], [0.44, 0.80, 2], [0.47, 0.80, 4], [0.495, 0.815, 4], [0.51, 0.85, 4]],
		"lines": [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5]],
	},
	{
		"name": "Delphinus", "label": Vector2(0.625, 0.41),
		"stars": [[0.60, 0.30, 3], [0.625, 0.285, 3], [0.64, 0.315, 4], [0.615, 0.33, 4], [0.59, 0.37, 4]],
		"lines": [[0, 1], [1, 2], [2, 3], [3, 0], [3, 4]],
	},
]

var ink: Color = GameConfig.CHART_INK
var gold: Color = GameConfig.CHART_GOLD
var font: Font = preload("res://fonts/IMFellEnglish-Italic.ttf")
var size: Vector2

func _ready():
	size = get_viewport_rect().size
	queue_redraw()

func _draw():
	_draw_graticule()
	_draw_ecliptic()
	_draw_field_stars()
	for constellation in CONSTELLATIONS:
		_draw_constellation(constellation)
	_draw_neatline()

# Parallels of declination and hour circles for a pole far below the plate,
# as on a conic chart section
func _draw_graticule():
	var pole = Vector2(size.x * 0.5, size.y * 2.4)
	var line = Color(ink, 0.16)
	var r = size.y * 1.5
	while r < size.y * 3.5:
		draw_arc(pole, r, -PI * 0.5 - 0.6, -PI * 0.5 + 0.6, 128, line, 1.0, true)
		r += size.y * 0.19
	var a = -0.55
	while a <= 0.56:
		var dir = Vector2.from_angle(-PI * 0.5 + a)
		draw_line(pole + dir * size.y * 1.3, pole + dir * size.y * 3.6, line, 1.0, true)
		a += 0.085
	_draw_hour_numerals(pole)

func _draw_hour_numerals(pole: Vector2):
	var numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"]
	var i = 0
	var a = -0.55
	while a <= 0.56:
		var dir = Vector2.from_angle(-PI * 0.5 + a)
		# Where this hour circle meets the top inner neatline
		var t = (pole.y - 30.0) / -dir.y
		var x = pole.x + dir.x * t
		if x > 40.0 and x < size.x - 40.0 and i % 2 == 0:
			draw_string(font, Vector2(x - 20.0, 38.0), numerals[i], HORIZONTAL_ALIGNMENT_CENTER, 40.0, 15, Color(ink, 0.55))
		i += 1
		a += 0.085

# The ecliptic as a narrow graduated band crossing the plate obliquely,
# ticked every degree with longer marks every fifth and tenth
func _draw_ecliptic():
	var a = Vector2(-120.0, size.y * 0.86)
	var b = Vector2(size.x + 120.0, size.y * 0.24)
	var radius = 3200.0
	var mid = (a + b) * 0.5
	var half = a.distance_to(b) * 0.5
	var normal = (b - a).normalized().orthogonal()
	# Centre below the chord so the band bows up across the plate
	var centre = mid - normal * sqrt(radius * radius - half * half)
	var start = (a - centre).angle()
	var end = start + wrapf((b - centre).angle() - start, -PI, PI)
	if end < start:
		var swap = start
		start = end
		end = swap
	var band = 9.0
	var line = Color(ink, 0.45)
	draw_arc(centre, radius - band * 0.5, start, end, 256, line, 1.2, true)
	draw_arc(centre, radius + band * 0.5, start, end, 256, line, 1.2, true)
	var step = 9.0 / radius
	var n = 0
	var t = start
	while t < end:
		var dir = Vector2.from_angle(t)
		var len = band if n % 5 == 0 else band * 0.5
		var inner = centre + dir * (radius - band * 0.5)
		if n % 2 == 0 or n % 5 == 0:
			draw_line(inner, inner + dir * len, line, 1.0, true)
		n += 1
		t += step
	var label_t = lerp(start, end, 0.62)
	var label_pos = centre + Vector2.from_angle(label_t) * (radius + band + 6.0)
	draw_set_transform(label_pos, label_t + PI * 0.5)
	draw_string(font, Vector2(-60.0, -4.0), "Ecliptica", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 20, Color(ink, 0.55))
	draw_set_transform(Vector2.ZERO)

func _draw_field_stars():
	var rng = RandomNumberGenerator.new()
	rng.seed = FIELD_STAR_SEED
	for i in FIELD_STAR_COUNT:
		var p = Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var roll = rng.randf()
		var magnitude = 6 if roll < 0.62 else (5 if roll < 0.92 else 4)
		_draw_star(p, magnitude, 0.75)

func _draw_constellation(constellation: Dictionary):
	var points: Array[Vector2] = []
	for star in constellation.stars:
		points.append(Vector2(star[0], star[1]) * size)
	for pair in constellation.lines:
		_draw_dotted(points[pair[0]], points[pair[1]], Color(ink, 0.4))
	for i in points.size():
		_draw_star(points[i], constellation.stars[i][2], 1.0)
	var label = constellation.label * size
	draw_string(font, label - Vector2(150.0, 0.0), constellation.name, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 22, Color(ink, 0.5))

# Figures in the later atlases are joined by dotted lines that stop short of
# each star so the symbol stays clean
func _draw_dotted(from: Vector2, to: Vector2, color: Color):
	var length = from.distance_to(to)
	var dir = (to - from) / length
	var d = 12.0
	while d < length - 12.0:
		draw_circle(from + dir * d, 1.1, color, true, -1.0, true)
		d += 6.0

# Magnitude classes as the engravers drew them: the brightest are many-rayed
# stars heightened in gold, fading to plain dots for the sixth magnitude
func _draw_star(p: Vector2, magnitude: int, fade: float):
	var colour = Color(ink, 0.85 * fade)
	match magnitude:
		1:
			var pts = _star_points(p, 8, 13.0, 8.0, 3.2)
			draw_colored_polygon(pts, gold)
			pts.append(pts[0])
			draw_polyline(pts, colour, 1.2, true)
			draw_circle(p, 2.2, colour, true, -1.0, true)
		2:
			var pts = _star_points(p, 8, 9.0, 6.0, 2.4)
			draw_colored_polygon(pts, gold)
			pts.append(pts[0])
			draw_polyline(pts, colour, 1.0, true)
		3:
			draw_colored_polygon(_star_points(p, 6, 6.5, 6.5, 1.9), colour)
		4:
			draw_colored_polygon(_star_points(p, 5, 4.5, 4.5, 1.5), colour)
		5:
			draw_circle(p, 1.6, colour, true, -1.0, true)
		_:
			draw_circle(p, 1.0, Color(colour, colour.a * 0.8), true, -1.0, true)

# Rays alternate between a long and a short length, as in engraved symbols
func _star_points(p: Vector2, rays: int, long_ray: float, short_ray: float, inner: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in rays * 2:
		var a = -PI * 0.5 + i * PI / rays
		var r = inner
		if i % 2 == 0:
			r = long_ray if (i / 2) % 2 == 0 else short_ray
		pts.append(p + Vector2.from_angle(a) * r)
	return pts

# Double-ruled border with a degree scale of alternating filled bars between
# the rules
func _draw_neatline():
	var outer = Rect2(Vector2(6.0, 6.0), size - Vector2(12.0, 12.0))
	var inner = outer.grow(-10.0)
	draw_rect(outer, ink, false, 2.4, true)
	draw_rect(inner, ink, false, 1.0, true)
	var scale_rect = outer.grow(-5.0)
	draw_rect(scale_rect, Color(ink, 0.6), false, 0.8, true)
	var bar = 30.0
	var x = outer.position.x
	var i = 0
	while x < outer.end.x:
		if i % 2 == 0:
			var w = min(bar, outer.end.x - x)
			draw_rect(Rect2(x, outer.position.y, w, 5.0), ink)
			draw_rect(Rect2(x, scale_rect.end.y, w, 5.0), ink)
		x += bar
		i += 1
	var y = outer.position.y
	i = 0
	while y < outer.end.y:
		if i % 2 == 0:
			var h = min(bar, outer.end.y - y)
			draw_rect(Rect2(outer.position.x, y, 5.0, h), ink)
			draw_rect(Rect2(scale_rect.end.x, y, 5.0, h), ink)
		y += bar
		i += 1
