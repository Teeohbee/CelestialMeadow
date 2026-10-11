extends Node2D

## A flat two-tone asteroid in crimson or plum, no outline. Its rough
## outline sits on the asteroid's square collision shape.

const RADIUS: float = 46.0
const POINTS: int = 9

var outline := PackedVector2Array()
var core := PackedVector2Array()
var ink: Color

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	ink = GameConfig.ENV_INKS[6] if rng.randf() < 0.5 else GameConfig.ENV_INKS[0]
	for i in POINTS:
		var p = Vector2.from_angle(TAU * i / POINTS) * RADIUS * (0.72 + rng.randf() * 0.36)
		outline.append(p)
		core.append(p * 0.6 - Vector2.ONE * RADIUS * 0.15)

func _draw():
	draw_colored_polygon(outline, ink.lerp(GameConfig.GROUND, 0.35))
	draw_colored_polygon(core, ink)
