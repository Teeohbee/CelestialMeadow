extends RoundSuite
# In a round, a pilot's left stick turns their ship as the D-pad does, harder the further it's pushed, and
# nobody else's.

func speed() -> float:
	return 4.0

func push(value: float, device: int) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.device = device
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = value
	Input.parse_input_event(motion)

func after_test() -> void:
	for device in 6:
		push(0.0, device)
	await super()

func turned_by(number: int, value: float) -> float:
	var start: float = ship(number).rotation
	push(value, number)
	await seconds(0.3)
	push(0.0, number)
	return angle_difference(start, ship(number).rotation)

func test_pushing_right_turns_the_ship_right() -> void:
	await new_round([0, 1])
	await calm()
	assert_float(await turned_by(1, 1.0)).is_greater(0.2)

func test_pushing_left_turns_it_left() -> void:
	await new_round([0, 1])
	await calm()
	assert_float(await turned_by(1, -1.0)).is_less(-0.2)

func test_a_half_push_turns_less_than_a_full_one() -> void:
	await new_round([0, 1])
	await calm()
	var half := await turned_by(1, 0.55)
	await seconds(1.0)
	var full := await turned_by(1, 1.0)
	assert_float(half).is_greater(0.0)
	assert_float(half).is_less(full)

func test_only_that_pilots_ship_turns() -> void:
	await new_round([0, 1])
	await calm()
	var start: float = ship(0).rotation
	await turned_by(1, 1.0)
	assert_float(ship(0).rotation).is_equal_approx(start, 0.01)
