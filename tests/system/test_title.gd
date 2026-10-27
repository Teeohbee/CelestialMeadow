extends GameSuite
# The lobby: each player takes a seat with their own shoot button, readies with it again and backs out with
# rotate left. Once two or more are seated and all ready, the round launches with exactly those seats. Esc
# asks before quitting. In debug, one pilot can launch against a dummy.

func seats() -> Array:
	return scene().cards.map(func(c): return c.state)

func status() -> String:
	return scene().status.text

# The lobby as a release build sees it: no dummy pilot
func lobby() -> Node:
	var menu := await open("res://menu.tscn")
	GameState.dummy_pilot = false
	await frames(2)
	return menu

func seat_and_ready(seat: int) -> void:
	await press("shoot%d" % seat)
	await press("shoot%d" % seat)

func launch() -> void:
	await seconds(GameConfig.TITLE_LAUNCH_DELAY + 0.2)
	await settle()

func test_all_seats_are_empty_on_first_boot() -> void:
	await lobby()
	assert_array(seats()).is_equal([0, 0, 0, 0, 0, 0])
	assert_str(status()).is_equal("Press {a} to take a seat")

func test_shoot_takes_a_seat() -> void:
	await lobby()
	await press("shoot3")
	assert_int(seats()[3]).is_equal(1)

func test_rotate_left_leaves_the_seat() -> void:
	await lobby()
	await press("shoot3")
	await press("rotate_left3")
	assert_int(seats()[3]).is_equal(0)

func test_a_second_shoot_readies() -> void:
	await lobby()
	await seat_and_ready(3)
	assert_int(seats()[3]).is_equal(2)

func test_one_ready_player_doesnt_launch() -> void:
	await lobby()
	await seat_and_ready(3)
	await launch()
	assert_str(scene().name).is_equal("Menu")
	assert_str(status()).is_equal("Waiting for another pilot")

func test_it_counts_ready_players() -> void:
	await lobby()
	await seat_and_ready(3)
	await press("shoot0")
	await seat_and_ready(5)
	await frames(1)
	assert_str(status()).is_equal("2 of 3 ready")

func test_esc_asks_before_quitting_with_stay_focused() -> void:
	var menu := await lobby()
	await press("ui_cancel")
	assert_bool(menu.quit_confirm.visible).is_true()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(menu.stay_button)

func test_seats_ignore_input_while_confirming() -> void:
	await lobby()
	await press("ui_cancel")
	await press("shoot1")
	assert_int(seats()[1]).is_equal(0)

func test_cancel_closes_the_quit_confirmation() -> void:
	var menu := await lobby()
	await press("ui_cancel")
	await press("ui_cancel")
	assert_bool(menu.quit_confirm.visible).is_false()

func test_all_ready_starts_the_launch() -> void:
	await lobby()
	await seat_and_ready(0)
	await seat_and_ready(3)
	await frames(1)
	assert_str(status()).starts_with("Launching")

func test_unreadying_cancels_the_launch() -> void:
	await lobby()
	await seat_and_ready(0)
	await seat_and_ready(3)
	await press("rotate_left3")
	await launch()
	assert_str(scene().name).is_equal("Menu")

func test_it_launches_once_all_are_ready_with_the_seated_players() -> void:
	await lobby()
	for seat in [0, 3, 5]:
		await seat_and_ready(seat)
	await launch()
	assert_str(scene().name).is_equal("Main")
	assert_array(GameState.players).is_equal([0, 3, 5])

func test_only_the_seated_players_spawn_and_show_on_the_hud() -> void:
	await lobby()
	for seat in [0, 3, 5]:
		await seat_and_ready(seat)
	await launch()
	await ships_launched()
	var spawned := ships().map(func(ship): return ship.player_number)
	spawned.sort()
	assert_array(spawned).is_equal([0, 3, 5])
	var shown: Array = scene().get_node("HUD").shown_players()
	shown.sort()
	assert_array(shown).is_equal([0, 3, 5])

func test_a_returning_crew_is_still_seated_but_not_ready() -> void:
	GameState.start_session([0, 3, 5] as Array[int])
	await lobby()
	assert_array(seats()).is_equal([1, 0, 0, 1, 0, 1])

func test_a_solo_pilot_isnt_ready_until_they_ready() -> void:
	await lobby()
	GameState.dummy_pilot = true
	await press("shoot2")
	await frames(1)
	assert_str(status()).is_equal("0 of 1 ready")

func test_a_ready_solo_pilot_launches_against_a_dummy() -> void:
	await lobby()
	GameState.dummy_pilot = true
	await seat_and_ready(2)
	await frames(1)
	assert_str(status()).ends_with("against a dummy")
	await launch()
	assert_str(scene().name).is_equal("Main")

func test_the_dummy_takes_the_first_free_seat() -> void:
	await lobby()
	GameState.dummy_pilot = true
	await seat_and_ready(2)
	await launch()
	assert_array(GameState.players).is_equal([0, 2])
	assert_array(GameState.dummies).is_equal([0])

func test_killing_the_dummy_wins_the_round() -> void:
	await start_round([2], [0])
	kill([0])
	var shown := await results()
	assert_object(shown).is_not_null()
	assert_str(shown.title.text).is_equal("Tangerine Wins!")

func test_back_in_the_lobby_only_the_human_is_seated() -> void:
	await start_round([2], [0])
	kill([0])
	await results()
	await press("rotate_right2")
	await press("shoot2")
	await settle()
	assert_array(seats()).is_equal([0, 0, 1, 0, 0, 0])
