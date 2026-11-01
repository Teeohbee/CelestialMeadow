extends GdUnitTestSuite
# Ship controls on each pilot's own pad: the left stick steers (left/right, analog, past a small deadzone)
# alongside the D-pad, and B thrusts as well as RT. The stick only reaches steering, never the seat
# controls the lobby and results read (test_menu_stick).

func stick(value: float, device: int) -> InputEventJoypadMotion:
	var motion := InputEventJoypadMotion.new()
	motion.device = device
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = value
	return motion

func test_each_pads_stick_steers_its_own_ship() -> void:
	for seat in 6:
		assert_bool(stick(-1.0, seat).is_action("steer_left%d" % seat)).is_true()
		assert_bool(stick(1.0, seat).is_action("steer_right%d" % seat)).is_true()
		assert_bool(stick(1.0, seat).is_action("steer_right%d" % ((seat + 1) % 6))).is_false()

func test_a_resting_stick_doesnt_steer() -> void:
	assert_float(stick(0.1, 0).get_action_strength("steer_right0")).is_equal(0.0)

func test_steering_is_analog() -> void:
	var strength := stick(0.6, 0).get_action_strength("steer_right0")
	assert_float(strength).is_greater(0.0)
	assert_float(strength).is_less(1.0)

func test_b_thrusts_on_each_pad() -> void:
	for seat in 6:
		var b := InputEventJoypadButton.new()
		b.device = seat
		b.button_index = JOY_BUTTON_B
		b.pressed = true
		assert_bool(b.is_action_pressed("thrust%d" % seat)).is_true()
		assert_bool(b.is_action_pressed("thrust%d" % ((seat + 1) % 6))).is_false()

func test_rt_is_still_the_thrust_shown() -> void:
	assert_str(load("res://seat_card.gd").action_glyph("thrust0")).is_equal("{rt}")
