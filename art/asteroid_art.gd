extends Node2D

## A flat two-tone asteroid in crimson or plum, no outline, lifted off the
## backdrop by a drop shadow. Its rough outline sits on the asteroid's
## square collision shape.

const RADIUS: float = 46.0
const POINTS: int = 9

var outline := PackedVector2Array()
var core := PackedVector2Array()
var ink: Color

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	ink = inks()[rng.randi() % 2]
	for i in POINTS:
		var p = Vector2.from_angle(TAU * i / POINTS) * RADIUS * (0.72 + rng.randf() * 0.36)
		outline.append(p)
		core.append(p * 0.6 - Vector2.ONE * RADIUS * 0.15)

## Crimson, and plum lifted a touch so it stays brighter than the hazed planets
static func inks() -> Array[Color]:
	return [GameConfig.ENV_INKS[0], GameConfig.ENV_INKS[6].lightened(GameConfig.PLUM_LIFT)]

func _draw():
	var shadow = PackedVector2Array()
	for p in outline:
		shadow.append(p + GameConfig.DROP_SHADOW)
	draw_colored_polygon(shadow, Color(GameConfig.GROUND.darkened(0.6), GameConfig.DROP_SHADOW_ALPHA))
	draw_colored_polygon(outline, ink.lerp(GameConfig.GROUND, 0.35))
	draw_colored_polygon(core, ink)
