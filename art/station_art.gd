extends Node2D

## The station as a Deep Space Atomic Clock dial: tick ring, dashed orbit,
## core and electron orbits. The two orbits lie along the station's four
## collision arms, so what you see is what you hit. Drawn in the body's
## space (which is scaled 1.5x), so it turns with the station.

const CORE: float = 34.0
const ORBIT_LONG: float = 80.0
const ORBIT_SHORT: float = 12.0
const TICK_OUTER: float = 102.0

var line_scale: float = 1.0

func _ready():
	line_scale = 1.0 / maxf(get_parent().scale.x, 0.01)

func _process(_delta):
	queue_redraw()

func _draw():
	var t = Time.get_ticks_msec() / 1000.0
	var cream = GameConfig.CREAM
	var w = line_scale
	for i in 24:
		var a = TAU * i / 24.0 + PI / 4.0
		var major = i % 6 == 0
		var inner = TICK_OUTER * (0.84 if major else 0.93)
		Poster.bar(self, Vector2.from_angle(a) * inner, Vector2.from_angle(a) * TICK_OUTER, (4.0 if major else 2.0) * w, GameConfig.LIGHT if major else Color(cream, 0.35))
	Poster.dashed_circle(self, Vector2.ZERO, CORE * 1.6, 6 * w, 7 * w, Color(cream, 0.3), 1.5 * w)
	draw_circle(Vector2.ZERO, CORE, GameConfig.DEEP)
	draw_circle(Vector2.ZERO, CORE * 0.8, Color(GameConfig.HUE, 0.45))
	for i in 2:
		var rot = PI / 4.0 + i * PI / 2.0
		var pts = PackedVector2Array()
		for j in 49:
			var a = TAU * j / 48.0
			pts.append(Vector2(cos(a) * ORBIT_LONG, sin(a) * ORBIT_SHORT).rotated(rot))
		draw_polyline(pts, Color(cream, 0.6), 1.5 * w, true)
		var e = t * 1.6 + i * 2.0
		draw_circle(Vector2(cos(e) * ORBIT_LONG, sin(e) * ORBIT_SHORT).rotated(rot), 4.5 * w, cream)
	draw_circle(Vector2.ZERO, CORE * 0.3, cream)
