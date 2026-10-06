extends Node2D

## A poster explosion: see-through discs that overlap and expand, with a
## ring, instead of a starburst. Keeps AnimatedSprite2D's play() and
## animation_finished so the ship and asteroid code drive it unchanged.

signal animation_finished

const DURATION: float = 1.1

@export var radius: float = 70.0
## The third disc's ink: the pilot's colour for a ship, crimson for rock
var ink: Color = GameConfig.ENV_INKS[0]

var phase: float = 1.0

func play(_animation: StringName = &"") -> void:
	phase = 0.0
	queue_redraw()

func _process(delta):
	if phase >= 1.0:
		return
	phase = minf(phase + delta / DURATION, 1.0)
	queue_redraw()
	if phase >= 1.0:
		animation_finished.emit()

func _draw():
	if phase >= 1.0:
		return
	var g = radius * (0.25 + 0.75 * sqrt(phase))
	var fade = minf(1.0, 1.4 - phase * 1.4)
	var discs = [
		[GameConfig.HUE, 1.0, Vector2.ZERO, 0.8],
		[GameConfig.LIGHT, 0.66, Vector2(0.3, -0.22), 0.75],
		[ink, 0.42, Vector2(-0.34, 0.2), 0.7],
		[GameConfig.CREAM, 0.3, Vector2(0.05, 0.05), 0.95],
	]
	for d in discs:
		draw_circle(d[2] * g, g * d[1], Color(d[0], d[3] * fade))
	draw_arc(Vector2.ZERO, g * 1.35, 0, TAU, 64, Color(GameConfig.LIGHT, fade), 3.0, true)
