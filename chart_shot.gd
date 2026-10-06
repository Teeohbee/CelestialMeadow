extends Node2D

## A shot drawn as a chart's course line: a dotted trail in the player's
## pigment ending in an engraved arrowhead. Drawn in the bullet's space,
## with +x the direction of travel.

const DOTS: int = 6
const DOT_SPACING: float = 9.0

var color: Color = GameConfig.CHART_INK

func set_player(player_number: int):
	color = GameConfig.PLAYER_COLORS[player_number]
	queue_redraw()

func _draw():
	var ink = GameConfig.CHART_INK
	for i in DOTS:
		var radius = 2.6 - i * 0.3
		draw_circle(Vector2(-i * DOT_SPACING - 4.0, 0.0), radius, Color(color, 1.0 - i * 0.12), true, -1.0, true)
	var head = PackedVector2Array([Vector2(10.0, 0.0), Vector2(-1.0, 4.5), Vector2(1.5, 0.0), Vector2(-1.0, -4.5)])
	draw_colored_polygon(head, ink)
