extends GdUnitTestSuite
# The left stick drives every menu as the D-pad does, on any pad, while seats and ships ignore it.

func stick(axis: JoyAxis, value: float, device := 2) -> InputEventJoypadMotion:
	var motion := InputEventJoypadMotion.new()
	motion.device = device
	motion.axis = axis
	motion.axis_value = value
	return motion

func test_the_left_stick_moves_through_menus() -> void:
	assert_bool(stick(JOY_AXIS_LEFT_X, -1.0).is_action_pressed("ui_left")).is_true()
	assert_bool(stick(JOY_AXIS_LEFT_X, 1.0).is_action_pressed("ui_right")).is_true()
	assert_bool(stick(JOY_AXIS_LEFT_Y, -1.0).is_action_pressed("ui_up")).is_true()
	assert_bool(stick(JOY_AXIS_LEFT_Y, 1.0).is_action_pressed("ui_down")).is_true()

func test_any_pad_can_use_it() -> void:
	assert_bool(stick(JOY_AXIS_LEFT_Y, 1.0, 5).is_action_pressed("ui_down")).is_true()

func test_a_light_touch_does_nothing() -> void:
	assert_bool(stick(JOY_AXIS_LEFT_X, 0.3).is_action_pressed("ui_right")).is_false()

func test_seat_and_ship_controls_ignore_the_left_stick() -> void:
	for seat in 6:
		for verb in ["shoot", "rotate_left", "rotate_right", "thrust", "pause", "options"]:
			var action: String = "%s%d" % [verb, seat] if verb not in ["pause", "options"] else verb
			for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
				for value in [-1.0, 1.0]:
					assert_bool(stick(axis, value, seat).is_action(action)) \
						.override_failure_message("%s reads the left stick" % action).is_false()
