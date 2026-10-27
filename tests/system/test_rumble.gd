extends RoundSuite
# Pads rumble: hard for the pilot who dies, a light tick for the one whose shot landed and for picking up a
# power-up. Nobody else's pad moves, and a dummy's pad never does.

func speed() -> float:
	return 4.0

func before_test() -> void:
	super()
	for device in 8:
		Input.stop_joy_vibration(device)

func strength(device: int) -> Vector2:
	return Input.get_joy_vibration_strength(device)

func test_dying_rumbles_hard() -> void:
	await new_round([0, 1, 2])
	await fire(0, 2)
	assert_float(strength(2).y).is_equal(GameConfig.RUMBLE_DEATH.strong)

func test_landing_a_shot_ticks_lightly() -> void:
	await new_round([0, 1, 2])
	await fire(0, 2)
	assert_vector(strength(0)).is_equal(Vector2(GameConfig.RUMBLE_TICK.weak, GameConfig.RUMBLE_TICK.strong))

func test_onlookers_feel_nothing() -> void:
	await new_round([0, 1, 2])
	await fire(0, 2)
	assert_vector(strength(1)).is_equal(Vector2.ZERO)

func test_crashing_into_an_asteroid_rumbles_only_the_pilot() -> void:
	await new_round([0, 1])
	ship(1).destroy()
	assert_float(strength(1).y).is_equal(GameConfig.RUMBLE_DEATH.strong)
	assert_vector(strength(0)).is_equal(Vector2.ZERO)

func test_picking_up_a_power_up_ticks() -> void:
	await new_round([0, 1])
	await calm()
	var powerup: Node = load("res://powerup.tscn").instantiate()
	powerup.position = ship(1).global_position
	scene().add_child(powerup)
	var picked: WeakRef = weakref(powerup)
	assert_bool(await wait_until(func(): return picked.get_ref() == null, 2.0)).is_true()
	assert_vector(strength(1)).is_equal(Vector2(GameConfig.RUMBLE_TICK.weak, GameConfig.RUMBLE_TICK.strong))

func test_a_dummys_pad_never_rumbles() -> void:
	GameState.start_session([0] as Array[int], [1] as Array[int])
	await open("res://main.tscn")
	await ships_launched()
	await fire(0, 1)
	assert_bool(ship(1).dead).is_true()
	assert_vector(strength(1)).is_equal(Vector2.ZERO)
