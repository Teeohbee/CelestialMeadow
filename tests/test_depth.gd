extends GdUnitTestSuite
# Planets sit behind the play: every planet disc is nearer the ground colour than any asteroid ink.

func distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()

func test_planet_discs_are_nearer_the_ground_than_any_asteroid() -> void:
	var planet: Node = auto_free(load("res://planet.tscn").instantiate())
	var nearest_asteroid := 9.0
	for ink in load("res://art/asteroid_art.gd").inks():
		nearest_asteroid = minf(nearest_asteroid, distance(ink, GameConfig.GROUND))
	# The discs are what fills the screen
	var furthest_planet := 0.0
	for design in planet.INKS.values():
		furthest_planet = maxf(furthest_planet, distance(planet.ink(design[0]), GameConfig.GROUND))
	assert_float(furthest_planet).is_less(nearest_asteroid)
