extends RoundSuite
# No friendly fire: a teammate's bullet passes through, an opponent's kills.

func test_a_teammates_bullet_passes_through() -> void:
	await new_round([0, 1, 2], [0, 0, -1, -1, -1, -1])
	await fire(0, 1)
	assert_bool(ship(1).dead).is_false()

func test_an_opponents_bullet_kills() -> void:
	await new_round([0, 1, 2], [0, 0, -1, -1, -1, -1])
	await fire(0, 2)
	assert_bool(ship(2).dead).is_true()
