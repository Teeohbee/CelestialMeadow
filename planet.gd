extends Node2D

## A Grand Tour planet: see-through disc with horizon stripes and a highlight,
## speed bars trailing off to the left, an optional ring and a tracked name.

enum Design { GREEN_RINGED, ORANGE, TEAL }

## Inks (indexes into GameConfig.ENV_INKS) for each design:
## disc, highlight, three trailing bars, ring (-1 for none)
const INKS: Dictionary = {
	Design.GREEN_RINGED: [4, 5, [2, 3, 1], 6],
	Design.ORANGE: [1, 0, [6, 0, 5], -1],
	Design.TEAL: [5, 3, [0, 2, 6], -1],
}

## Off when a scene picks the planet's design, size and position itself,
## as the title screen does
@export var randomise: bool = true
@export var radius: float = 120.0
@export var design: Design = Design.ORANGE
@export var show_name: bool = true
@export var planet_name: String = ""

static var name_bag: Array[String] = []
static var design_bag: Array = []

func _ready():
	if randomise:
		if design_bag.is_empty():
			design_bag = Design.values()
			design_bag.shuffle()
		design = design_bag.pop_back()
		radius = randf_range(80.0, 200.0)
		position = free_spot()
	if show_name and planet_name == "":
		planet_name = next_name()

static func next_name() -> String:
	if name_bag.is_empty():
		name_bag.assign(GameConfig.PLANET_NAMES)
		name_bag.shuffle()
	return name_bag.pop_back()

## Somewhere inside the bezel, clear of the station and other planets, so
## a planet and its name stay on screen
func free_spot() -> Vector2:
	add_to_group("planets")
	var screen_size = get_viewport_rect().size
	var margin = Vector2(radius + 40, radius + 60)
	var spot = Vector2.ZERO
	for attempt in 30:
		spot = Vector2(randf_range(margin.x, screen_size.x - margin.x), randf_range(margin.y, screen_size.y - margin.y))
		var clear = spot.distance_to(screen_size * 0.5) > radius + 160
		for other in get_tree().get_nodes_in_group("planets"):
			if other != self and spot.distance_to(other.position) < radius + other.radius + 40:
				clear = false
		if clear:
			break
	return spot

func ink(i: int) -> Color:
	return GameConfig.ENV_INKS[i]

func _draw():
	var inks = INKS[design]
	var r = radius
	var k = r / 165.0  # the lookbook's large planet
	var disc = Poster.circle_points(Vector2.ZERO, r, 64)

	# Speed bars running off to the left, behind the disc
	var bars = [[-0.3, 0.2], [0.0, 0.12], [0.3, 0.16]]
	for i in 3:
		var y = r * bars[i][0]
		Poster.bar(self, Vector2(-r * 3.0, y), Vector2(0, y), r * bars[i][1], Color(ink(inks[2][i]), 0.6))

	draw_colored_polygon(disc, Color(ink(inks[0]), 0.9))
	# Horizon stripes thicken towards the bottom, clipped to the disc
	for i in 6:
		var top = r * (0.1 + i * 0.15)
		var band = PackedVector2Array([Vector2(-r, top), Vector2(r, top), Vector2(r, top + (3 + i * 3.4) * k), Vector2(-r, top + (3 + i * 3.4) * k)])
		for poly in Geometry2D.intersect_polygons(band, disc):
			draw_colored_polygon(poly, Color(GameConfig.DEEP, 0.45))
	var highlight = Poster.circle_points(Vector2(-r * 0.28, -r * 0.28), r * 0.72, 64)
	for poly in Geometry2D.intersect_polygons(highlight, disc):
		draw_colored_polygon(poly, Color(ink(inks[1]), 0.55))

	if inks[3] >= 0:
		var ring = PackedVector2Array()
		for i in 65:
			var a = TAU * i / 64.0
			ring.append(Vector2(cos(a) * r * 1.7, sin(a) * r * 0.3).rotated(-0.45))
		draw_polyline(ring, Color(ink(inks[3]), 0.75), 18.0 * k, true)

	if show_name and planet_name != "":
		Poster.text_centred(self, Vector2(0, r + 34), planet_name.to_upper(), 15, Color(GameConfig.CREAM, 0.7), 600, 5)
