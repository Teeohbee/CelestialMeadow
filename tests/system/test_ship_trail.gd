extends GameSuite
# The thruster trail follows the path the ship's tail actually took, so it bends through a turn instead of
# swinging round as one stiff bar. It's as long as the old one (longer the faster you go), starts afresh
# when the ship wraps round the screen or stops, and a seat card's ship has none.

const ShipArt = preload("res://art/ship_art.gd")

var ship: Node2D

func spawn(show_trail := true) -> void:
	ship = Node2D.new()
	ship.set_script(ShipArt)
	ship.show_trail = show_trail
	add_child(auto_free(ship))
	await frames(1)

# One frame per step, the ship facing and moving along each heading
func fly(points: Array, speed: float) -> void:
	for i in range(1, points.size()):
		var heading: Vector2 = (points[i] - points[i - 1]).normalized()
		ship.global_position = points[i]
		ship.global_rotation = heading.angle()
		ship.velocity = heading * speed
		await frames(1)

func straight(from: Vector2, step: Vector2, count: int) -> Array:
	var points := []
	for i in count:
		points.append(from + step * i)
	return points

func arc(centre: Vector2, radius: float, count: int, turn: float) -> Array:
	var points := []
	for i in count:
		points.append(centre + Vector2.from_angle(turn * i / count) * radius)
	return points

# A line's points where they land on screen
func world(line: Line2D) -> PackedVector2Array:
	return line.get_global_transform() * line.points

func trail_length() -> float:
	var pts := world(ship.trail)
	var length := 0.0
	for i in range(1, pts.size()):
		length += pts[i].distance_to(pts[i - 1])
	return length

func test_a_straight_trail_runs_back_from_the_tail_as_long_as_before() -> void:
	await spawn()
	await fly(straight(Vector2(200, 500), Vector2(10, 0), 40), 300.0)
	var pts := world(ship.trail)
	assert_float(pts[0].distance_to(ship.to_global(Vector2(ShipArt.OFFSET, 0)))).is_less(0.5)
	for p in pts:
		assert_float(p.y).is_equal_approx(500.0, 0.5)
		assert_float(p.x).is_less_equal(pts[0].x)
	assert_float(trail_length()).is_equal_approx(300.0 * ShipArt.TRAIL_PER_SPEED, 1.0)

func test_the_trail_is_capped_at_full_speed() -> void:
	await spawn()
	await fly(straight(Vector2(100, 500), Vector2(20, 0), 60), 2000.0)
	assert_float(trail_length()).is_equal_approx(ShipArt.L * 6.0, 1.0)

func test_through_a_turn_the_trail_bends_along_the_path() -> void:
	await spawn()
	var centre := Vector2(900, 500)
	await fly(arc(centre, 150.0, 30, PI), 400.0)
	var pts := world(ship.trail)
	# Every point sits on the circle the tail flew round, so none of it cuts across the chord
	var tail_radius := ship.to_global(Vector2(ShipArt.OFFSET, 0)).distance_to(centre)
	for p in pts:
		assert_float(p.distance_to(centre)).is_equal_approx(tail_radius, 4.0)
	assert_int(pts.size()).is_greater(3)

func test_the_side_streaks_bend_too_and_are_shorter() -> void:
	await spawn()
	await fly(arc(Vector2(900, 500), 150.0, 30, PI), 400.0)
	for streak in ship.streaks:
		var pts := world(streak)
		assert_int(pts.size()).is_greater(2)
		assert_float(pts[0].distance_to(pts[-1])).is_less(trail_length())

func test_wrapping_round_the_screen_starts_the_trail_afresh() -> void:
	await spawn()
	await fly(straight(Vector2(1700, 500), Vector2(10, 0), 20), 300.0)
	await fly([Vector2(1890, 500), Vector2(10, 500), Vector2(20, 500)], 300.0)
	var pts := world(ship.trail)
	for p in pts:
		assert_float(p.x).is_less(100.0)

func test_a_stopped_ship_has_no_trail() -> void:
	await spawn()
	await fly(straight(Vector2(200, 500), Vector2(10, 0), 20), 300.0)
	ship.velocity = Vector2.ZERO
	await frames(1)
	assert_bool(ship.trail.visible).is_false()
	# Setting off again doesn't join up with where it stopped
	await fly(straight(Vector2(800, 200), Vector2(10, 0), 3), 300.0)
	assert_float(world(ship.trail)[-1].distance_to(Vector2(800, 200))).is_less(30.0)

# show_behind_parent does nothing on a top_level line, which draws over the ship, so the lines must be
# ordinary children; the round in v0.6.0 had the trail across the fuselage
func test_the_trail_and_streaks_sit_behind_the_ship() -> void:
	await spawn()
	for line in [ship.trail] + ship.streaks:
		assert_bool(line.top_level).is_false()
		assert_bool(line.show_behind_parent).is_true()

# The ship turns while the trail stays where the tail went, not swinging round with it
func test_turning_on_the_spot_leaves_the_trail_where_it_was() -> void:
	await spawn()
	await fly(straight(Vector2(200, 500), Vector2(10, 0), 30), 300.0)
	ship.global_rotation = PI / 2
	await frames(1)
	# Only the newest point moved with the tail; the rest still lie along the line it flew
	var pts := world(ship.trail)
	for i in range(1, pts.size()):
		assert_float(pts[i].y).is_equal_approx(500.0, 0.5)

func test_a_seat_cards_ship_has_no_trail() -> void:
	await spawn(false)
	assert_object(ship.trail).is_null()
