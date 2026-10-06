extends Control

## One life in the HUD: a star of the second magnitude, washed in the
## player's pigment and outlined in ink.

var color: Color = GameConfig.CHART_GOLD

func _ready():
	custom_minimum_size = Vector2(24, 24)

func _draw():
	var c = size * 0.5
	var pts = PackedVector2Array()
	for i in 16:
		var r = 3.6
		if i % 2 == 0:
			r = 11.5 if (i / 2) % 2 == 0 else 7.5
		pts.append(c + Vector2.from_angle(-PI * 0.5 + i * PI / 8.0) * r)
	draw_colored_polygon(pts, color)
	pts.append(pts[0])
	draw_polyline(pts, GameConfig.CHART_INK, 1.4, true)
