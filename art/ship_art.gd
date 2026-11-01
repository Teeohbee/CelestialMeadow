extends Node2D

## A Grand Tour dart: cream fuselage and swept wings, with a stripe and
## portholes in the pilot's ink. Behind it a flat round-ended trail follows
## the path the tail took, so it bends through a turn, longer the faster the
## ship goes. Faces +x; sized to the old 64px sprite so the hitbox still fits.

const L: float = 38.0
const OFFSET: float = -8.0  # centres the dart on the collision circle
const TRAIL_MIN_SPEED: float = 20.0
const TRAIL_PER_SPEED: float = 0.4
## A frame's move further than this is a wrap round the screen, not flight
const TRAIL_WRAP_JUMP: float = 400.0
## Where the trail and its two thin side streaks leave the ship
const TRAIL_EMITTERS: Array[Vector2] = [Vector2(OFFSET, 0), Vector2(OFFSET - L * 0.1, -L * 0.4), Vector2(OFFSET - L * 0.1, L * 0.4)]

var ink: Color = Color.WHITE
var thrusting: bool = false
## Velocity in world space; empty for a ship that never moves, e.g. a seat card
var velocity: Vector2 = Vector2.ZERO
var show_trail: bool = true
## The trail and its side streaks, drawn behind the ship
var trail: Line2D
var streaks: Array[Line2D] = []
## Newest first, each the emitters' world positions that frame
var history: Array = []

func _ready():
	if not show_trail:
		return
	trail = trail_line(L * 0.32)
	for s in 2:
		streaks.append(trail_line(L * 0.1))

func trail_line(width: float) -> Line2D:
	var line = Line2D.new()
	# Not top_level: that would let it use world points, but draws it over the ship
	line.show_behind_parent = true
	line.width = width
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(line)
	return line

func _process(_delta):
	if show_trail:
		update_trail()
		queue_redraw()

func _draw():
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

func update_trail():
	var speed = velocity.length()
	if speed < TRAIL_MIN_SPEED:
		history.clear()
	else:
		var now = TRAIL_EMITTERS.map(func(e): return to_global(e))
		if not history.is_empty() and now[0].distance_to(history[0][0]) > TRAIL_WRAP_JUMP:
			history.clear()
		history.push_front(now)
	var length = minf(speed * TRAIL_PER_SPEED, L * 6.0)
	# History is in world space so it stays put as the ship turns; the lines draw in the ship's own
	var to_ship = get_global_transform().affine_inverse()
	trail.points = to_ship * path_back(0, length)
	trail.default_color = Color(ink, 0.9)
	trail.visible = trail.points.size() > 1
	for i in streaks.size():
		streaks[i].points = to_ship * path_back(i + 1, length * 0.55)
		streaks[i].default_color = Color(ink.lerp(GameConfig.CREAM, 0.5), 0.6)
		streaks[i].visible = trail.visible
	# Keep just enough history for the longest line
	while history.size() > trail.points.size() + 1:
		history.pop_back()

## One emitter's path back from now, cut off at length along the way
func path_back(emitter: int, length: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var left = length
	for frame in history:
		var p: Vector2 = frame[emitter]
		if not pts.is_empty():
			var step = pts[-1].distance_to(p)
			if step >= left:
				pts.append(pts[-1].move_toward(p, left))
				break
			left -= step
		pts.append(p)
	return pts
