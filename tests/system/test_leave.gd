extends RoundSuite
# Leaving a round mid-play for the lobby, without going through the round's own buttons, doesn't break.

func test_a_round_can_be_left_for_the_lobby_mid_play() -> void:
	await start_round([0, 1, 2])
	await open("res://menu.tscn")
	await frames(2)
	assert_str(scene().name).is_equal("Menu")
	assert_array(ships()).is_empty()
