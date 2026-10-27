extends GdUnitTestSuite
# Which pad drives which seat, read from the input map: seat N's shoot action is bound to one pad. The
# keyboard and pads with no seat belong to nobody.

func test_each_seat_has_its_own_pad() -> void:
	for seat in 6:
		assert_int(GameState.device_of(seat)).is_equal(seat)

func test_a_pad_finds_its_seat() -> void:
	assert_int(GameState.seat_of_device(3)).is_equal(3)

func test_a_pad_beyond_the_seats_has_none() -> void:
	assert_int(GameState.seat_of_device(7)).is_equal(-1)

func test_the_keyboard_has_no_seat() -> void:
	assert_int(GameState.seat_of_device(-1)).is_equal(-1)
