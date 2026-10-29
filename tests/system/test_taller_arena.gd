extends GameSuite
# A 16:10 screen gets a taller arena rather than black bars: the play space grows to fill it, the station and
# camera sit in its middle, asteroids enter round its edge, and the title's placed planets spread to fill it.

const TALL := Vector2(1920, 1200)

# An arena laid out for a screen size, the way its _ready does, before it joins the tree
func arena(size: Vector2) -> Node:
	var main: Node = auto_free(load("res://main.tscn").instantiate())
	main.lay_out(size)
	return main

func test_the_screen_expands_rather_than_letterboxing() -> void:
	assert_str(ProjectSettings.get_setting("display/window/stretch/aspect")).is_equal("expand")

func test_the_camera_and_station_centre_on_a_tall_arena() -> void:
	var main := arena(TALL)
	assert_vector(main.get_node("Camera2D").offset).is_equal(TALL * 0.5)
	assert_vector(main.get_node("SpaceStation").position).is_equal(TALL * 0.5)

func test_a_shaken_camera_settles_back_on_the_tall_centre() -> void:
	var round := await start_round([0, 1])
	round.lay_out(TALL)
	var camera: Camera2D = round.get_node("Camera2D")
	camera.shake()
	await seconds(2.0)
	assert_vector(camera.offset).is_equal_approx(TALL * 0.5, Vector2.ONE * 0.01)

func test_asteroids_enter_round_the_tall_edge() -> void:
	var curve: Curve2D = arena(TALL).get_node("AsteroidPath").curve
	var corners := []
	for i in curve.point_count:
		corners.append(curve.get_point_position(i))
	assert_array(corners).contains([Vector2(0, TALL.y), TALL])

func test_the_grain_covers_a_tall_arena() -> void:
	var grain: Rect2 = arena(TALL).get_node("Grain").get_rect()
	assert_bool(grain.encloses(Rect2(Vector2.ZERO, TALL))).is_true()

func test_the_title_planets_spread_down_a_tall_screen() -> void:
	var backdrop: Node2D = auto_free(load("res://backdrop.tscn").instantiate())
	var bottom: Node2D = backdrop.get_node("Planet4")
	var top: Node2D = backdrop.get_node("Planet1")
	var bottom_x := bottom.position.x
	var bottom_y := bottom.position.y
	var top_y := top.position.y
	backdrop.spread_to(TALL)
	assert_float(bottom.position.y).is_equal_approx(bottom_y * TALL.y / 1080.0, 0.01)
	assert_float(top.position.y).is_equal_approx(top_y * TALL.y / 1080.0, 0.01)
	assert_float(bottom.position.x).is_equal(bottom_x)

func test_a_16_9_screen_lays_out_as_before() -> void:
	var main := arena(Vector2(1920, 1080))
	assert_vector(main.get_node("Camera2D").offset).is_equal(Vector2(960, 540))
	assert_vector(main.get_node("SpaceStation").position).is_equal(Vector2(960, 540))
