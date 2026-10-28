extends GameSuite
# The results screen: it shows when a round ends, records the win, pauses the game behind it and locks its
# buttons for a moment so mashed shoots can't skip it. Then any player rotates to choose and shoots to
# confirm: Rematch keeps the session's wins, Change match goes to the match setup with the crew still seated,
# and Main Menu goes to the title and starts afresh.

func speed() -> float:
	return 4.0

# A three-player round where everyone in losers has just died
func round_over(losers: Array[int]) -> void:
	await start_round([0, 1, 2])
	kill(losers)
	await wait_until(func(): return scene().has_node("Results"))

func shown() -> Node:
	return scene().get_node_or_null("Results")

func test_starting_a_session_clears_the_wins() -> void:
	GameState.wins[0] = 9
	GameState.start_session([0, 1, 2] as Array[int])
	assert_array(GameState.wins).is_equal([0, 0, 0, 0, 0, 0])

func test_results_show_after_a_win() -> void:
	await round_over([1, 2])
	assert_object(shown()).is_not_null()

func test_the_winners_win_is_recorded() -> void:
	await round_over([1, 2])
	assert_array(GameState.wins).is_equal([1, 0, 0, 0, 0, 0])

func test_the_game_is_paused_behind_the_results() -> void:
	await round_over([1, 2])
	assert_bool(get_tree().paused).is_true()

func test_the_buttons_lock_straight_away() -> void:
	await round_over([1, 2])
	assert_bool(shown().rematch_button.disabled).is_true()

func test_mashed_shoot_is_ignored_during_the_lock() -> void:
	await round_over([1, 2])
	var locked := shown()
	await press("shoot1")
	assert_object(shown()).is_same(locked)
	assert_bool(locked.chosen).is_false()

func test_the_buttons_unlock_after_the_lock() -> void:
	await round_over([1, 2])
	var unlocked := await results()
	assert_bool(unlocked.rematch_button.disabled).is_false()

func test_rematch_is_focused_by_default() -> void:
	await round_over([1, 2])
	var unlocked := await results()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(unlocked.rematch_button)

func test_the_title_names_the_winners_colour() -> void:
	await round_over([1, 2])
	assert_str(shown().title.text).is_equal("Red Wins!")

func test_the_pause_key_is_ignored_on_results() -> void:
	await round_over([1, 2])
	await results()
	await press("pause")
	assert_bool(get_tree().paused).is_true()
	assert_bool(scene().get_node("PauseMenu/UI").visible).is_false()

func test_any_players_shoot_confirms_a_rematch() -> void:
	await round_over([1, 2])
	var old := scene()
	await results()
	await press("shoot2")
	await settle()
	assert_str(scene().name).is_equal("Main")
	assert_object(scene()).is_not_same(old)
	assert_object(shown()).is_null()
	assert_bool(get_tree().paused).is_false()
	assert_array(GameState.wins).is_equal([1, 0, 0, 0, 0, 0])

func test_a_draw_shows_results_and_records_no_win() -> void:
	await round_over([0, 1, 2])
	assert_str(shown().title.text).is_equal("Draw!")
	assert_array(GameState.wins).is_equal([0, 0, 0, 0, 0, 0])

func test_rotating_steps_along_the_buttons() -> void:
	await round_over([0, 1, 2])
	var unlocked := await results()
	await press("rotate_right1")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(unlocked.change_button)
	await press("rotate_right2")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(unlocked.menu_button)
	await press("rotate_right0")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(unlocked.menu_button)
	await press("rotate_left0")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(unlocked.change_button)

func test_change_match_goes_to_match_setup_unpaused() -> void:
	await round_over([1, 2])
	await results()
	await press("rotate_right1")
	await press("shoot1")
	await settle()
	assert_str(scene().name).is_equal("MatchSetup")
	assert_bool(get_tree().paused).is_false()

func test_after_change_match_the_crew_is_still_seated() -> void:
	await round_over([1, 2])
	await results()
	await press("rotate_right1")
	await press("shoot1")
	await settle()
	await press("ui_accept")
	await settle()
	assert_array(scene().cards.map(func(c): return c.state)).is_equal([1, 1, 1, 0, 0, 0])

func test_shooting_on_main_menu_goes_to_the_title_unpaused() -> void:
	await round_over([0, 1, 2])
	await results()
	await press("rotate_right1")
	await press("rotate_right1")
	await press("shoot1")
	await settle()
	assert_str(scene().name).is_equal("Title")
	assert_bool(get_tree().paused).is_false()

func test_main_menu_clears_the_seats_and_the_tally() -> void:
	await round_over([1, 2])
	await results()
	await press("rotate_right1")
	await press("rotate_right1")
	await press("shoot1")
	await settle()
	assert_array(GameState.players).is_empty()
	assert_array(GameState.wins).is_equal([0, 0, 0, 0, 0, 0])
