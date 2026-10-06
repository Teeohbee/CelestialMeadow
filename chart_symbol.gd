extends Node2D

## An astronomical symbol in an engraved roundel, drawn in ink with gold.
## Used for power-ups: the Sun for the shield, a comet for rapid fire and
## Mercury, the messenger, for speed.

enum Symbol { SUN, COMET, MERCURY }

@export var symbol: Symbol = Symbol.SUN

const RADIUS: float = 17.0

func _draw():
	var ink = GameConfig.CHART_INK
	var gold = GameConfig.CHART_GOLD
	draw_circle(Vector2.ZERO, RADIUS, GameConfig.CHART_PAPER)
	draw_circle(Vector2.ZERO, RADIUS, ink, false, 1.8, true)
	draw_circle(Vector2.ZERO, RADIUS + 3.5, ink, false, 0.8, true)
	match symbol:
		Symbol.SUN:
			for i in 12:
				var dir = Vector2.from_angle(i * TAU / 12.0)
				draw_line(dir * 8.5, dir * (13.5 if i % 2 == 0 else 11.5), ink, 1.2, true)
			draw_circle(Vector2.ZERO, 7.0, gold)
			draw_circle(Vector2.ZERO, 7.0, ink, false, 1.4, true)
			draw_circle(Vector2.ZERO, 1.8, ink)
		Symbol.COMET:
			var head = Vector2(5.0, -5.0)
			for i in 4:
				var spread = (i - 1.5) * 0.16
				var tail = head + Vector2.from_angle(PI * 0.75 + spread) * (13.0 + (i % 2) * 3.0)
				draw_line(head, tail, ink, 1.1, true)
			draw_circle(head, 4.5, gold)
			draw_circle(head, 4.5, ink, false, 1.3, true)
		Symbol.MERCURY:
			draw_arc(Vector2(0.0, -9.0), 5.0, 0.15 * PI, 0.85 * PI, 16, ink, 1.6, true)
			draw_circle(Vector2(0.0, -2.0), 4.5, gold)
			draw_circle(Vector2(0.0, -2.0), 4.5, ink, false, 1.6, true)
			draw_line(Vector2(0.0, 2.5), Vector2(0.0, 12.0), ink, 1.6, true)
			draw_line(Vector2(-4.0, 8.0), Vector2(4.0, 8.0), ink, 1.6, true)
