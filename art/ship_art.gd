extends Node2D

## A Grand Tour dart: cream fuselage and swept wings, with a stripe and
## portholes in the pilot's ink. Behind it a flat round-ended trail points
## back along the direction of travel, longer the faster the ship goes.
## Faces +x; sized to the old 64px sprite so the hitbox still fits.

const L: float = 38.0
const OFFSET: float = -8.0  # centres the dart on the collision circle
const TRAIL_MIN_SPEED: float = 20.0
const TRAIL_PER_SPEED: float = 0.4

var ink: Color = Color.WHITE
var thrusting: bool = false
## Velocity in world space; empty for a ship that never moves, e.g. a seat card
var velocity: Vector2 = Vector2.ZERO
var show_trail: bool = true

func _process(_delta):
	if show_trail:
		queue_redraw()

func _draw():
	if show_trail:
		draw_trail()
	var x = OFFSET
	var cream = GameConfig.CREAM
	var wing = cream.lerp(GameConfig.GROUND, 0.2)
	draw_colored_polygon(PackedVector2Array([Vector2(x + L * 0.1, 0), Vector2(x - L * 0.55, L * 0.62), Vector2(x - L * 0.32, 0)]), wing)
	draw_colored_polygon(PackedVector2Array([Vector2(x + L * 0.1, 0), Vector2(x - L * 0.55, -L * 0.62), Vector2(x - L * 0.32, 0)]), wing)
	draw_colored_polygon(fuselage(x), cream)
	draw_rect(Rect2(x - L * 0.46, -L * 0.17, L * 0.16, L * 0.34), ink)
	for i in 4:
		draw_circle(Vector2(x + L * (0.02 + i * 0.17), 0), L * 0.06, ink)
	if thrusting:
		Poster.bar(self, Vector2(x - L * 0.62, 0), Vector2(x - L * 1.05, 0), L * 0.2, cream)

func fuselage(x: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var nose = Vector2(x + L * 1.1, 0)
	var tail_top = Vector2(x - L * 0.6, -L * 0.16)
	var tail_bottom = Vector2(x - L * 0.6, L * 0.16)
	for i in 9:  # quadratic curves from the nose to each tail corner
		pts.append(quad(nose, Vector2(x + L * 0.5, L * 0.22), tail_bottom, i / 8.0))
	for i in 9:
		pts.append(quad(tail_top, Vector2(x + L * 0.5, -L * 0.22), nose, i / 8.0))
	return pts

func quad(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(c, t).lerp(c.lerp(b, t), t)

func draw_trail():
	var speed = velocity.length()
	if speed < TRAIL_MIN_SPEED:
		return
	var length = minf(speed * TRAIL_PER_SPEED, L * 6.0)
	# Back along the direction of travel, in this node's rotated space
	var back = (-velocity / speed).rotated(-global_rotation)
	var side = back.orthogonal()
	var start = Vector2(OFFSET, 0)
	Poster.bar(self, start, start + back * length, L * 0.32, Color(ink, 0.9))
	var thin = Color(ink.lerp(GameConfig.CREAM, 0.5), 0.6)
	for s in [-1.0, 1.0]:
		var o = start + side * L * 0.4 * s + back * L * 0.1
		Poster.bar(self, o, o + back * length * 0.55, L * 0.1, thin)
