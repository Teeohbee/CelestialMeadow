extends Control

## The Grand Tour dart for menus: a still ship, nose up, centred in the control

const ShipArt = preload("res://art/ship_art.gd")

var art := ShipArt.new()
var ink: Color = Color.WHITE:
	set(value):
		ink = value
		art.ink = value
		art.queue_redraw()

func _init():
	art.show_trail = false
	art.rotation = -PI / 2
	add_child(art)
	resized.connect(_place)

func _ready():
	_place()

func _place():
	art.position = size * 0.5 + Vector2(0, 4)
	art.scale = Vector2.ONE * minf(size.x, size.y) / 80.0
