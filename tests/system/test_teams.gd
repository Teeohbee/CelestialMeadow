extends RoundSuite
# Teams: a match setting. With it off everyone flies solo. With it on every seated pilot is on Alpha, Beta or
# Gamma: a joiner goes to the smallest side (lowest on a tie), D-pad left/right on their own card changes it
# and unreadies everyone, and a round needs two sides. In Last Ship Standing the last side flying wins, every
# member credited; in Time Attack kills add up per team and tied teams all go to sudden death. Friendly fire is
# in test_ff.gd.

const S := GameState.SOLO

func speed() -> float:
	return 4.0

func card(seat: int) -> Node:
	return scene().cards[seat]

func lobby(teams_on: bool) -> Node:
	GameSettings.set_setting("teams", teams_on)
	var menu := await open("res://menu.tscn")
	GameState.dummy_pilot = false
	await frames(2)
	return menu

# Pilots 0-3 seated in the lobby, in order
func seated_lobby(teams_on := true) -> void:
	await lobby(teams_on)
	for seat in 4:
		await press("shoot%d" % seat)

func ready_all() -> void:
	for seat in 4:
		await press("shoot%d" % seat)

func launch() -> void:
	await seconds(GameConfig.TITLE_LAUNCH_DELAY + 0.2)
	await settle()

func alpha_v_beta(mode_index := 0) -> Node:
	return await new_round([0, 1, 2, 3], [0, 0, 1, 1, S, S], mode_index)

func test_with_teams_off_everyone_is_solo_with_no_team_row() -> void:
	await seated_lobby(false)
	assert_array(GameState.teams).is_equal([S, S, S, S, S, S])
	assert_bool(card(0).team_label.visible).is_false()

func test_with_teams_off_the_d_pad_doesnt_pick_a_team() -> void:
	await seated_lobby(false)
	await press("rotate_right0")
	assert_int(GameState.teams[0]).is_equal(S)

func test_joiners_fill_the_smallest_side_lowest_first() -> void:
	await seated_lobby()
	assert_array(GameState.teams.slice(0, 4)).is_equal([0, 1, 2, 0])
	assert_str(card(1).team_label.text).is_equal("Team Beta")
	assert_bool(card(1).team_label.visible).is_true()

func test_a_joiner_takes_the_side_someone_left() -> void:
	await seated_lobby()
	await press("back1")
	await press("shoot5")
	assert_int(GameState.teams[5]).is_equal(1)

func test_leaving_clears_the_team() -> void:
	await seated_lobby()
	await press("back2")
	assert_int(GameState.teams[2]).is_equal(S)

func test_d_pad_right_cycles_through_the_three_teams_with_no_solo() -> void:
	await seated_lobby()
	var seen := []
	for i in 3:
		await press("rotate_right0")
		seen.append(GameState.teams[0])
	assert_array(seen).is_equal([1, 2, 0])

func test_d_pad_left_goes_the_other_way() -> void:
	await seated_lobby()
	await press("rotate_left0")
	assert_int(GameState.teams[0]).is_equal(2)
	assert_str(card(0).team_label.text).is_equal("Team Gamma")

func test_only_your_own_card_changes() -> void:
	await seated_lobby()
	await press("rotate_right1")
	assert_array(GameState.teams.slice(0, 4)).is_equal([0, 2, 2, 0])

func test_unseated_players_cant_pick_a_team() -> void:
	await seated_lobby()
	await press("rotate_right4")
	assert_int(GameState.teams[4]).is_equal(S)

func test_a_ready_pilot_keeps_their_team() -> void:
	await seated_lobby()
	await press("shoot0")
	await press("rotate_right0")
	assert_int(GameState.teams[0]).is_equal(0)

func test_changing_team_unreadies_everyone() -> void:
	await seated_lobby()
	await ready_all()
	await press("shoot0")
	await press("back0")
	await press("rotate_right0")
	assert_int(card(1).state).is_equal(1)
	assert_int(card(3).state).is_equal(1)

func test_the_trigger_no_longer_picks_a_team() -> void:
	await seated_lobby()
	await press("thrust0")
	assert_int(GameState.teams[0]).is_equal(0)

func test_all_on_one_team_doesnt_launch() -> void:
	await lobby(true)
	await press("shoot0")
	await press("shoot1")
	await press("rotate_left1")
	await press("shoot0")
	await press("shoot1")
	await launch()
	assert_str(scene().name).is_equal("Menu")
	assert_str(scene().status.text).is_equal("Pick at least two sides")

func test_two_sides_launch_and_keep_their_teams() -> void:
	await seated_lobby()
	await ready_all()
	await launch()
	assert_str(scene().name).is_equal("Main")
	assert_array(GameState.teams.slice(0, 4)).is_equal([0, 1, 2, 0])

func test_a_returning_crew_keeps_their_teams() -> void:
	GameSettings.set_setting("teams", true)
	GameState.start_session([0, 1, 2] as Array[int])
	GameState.teams = [1, 1, 0, S, S, S] as Array[int]
	await lobby(true)
	assert_array(GameState.teams.slice(0, 3)).is_equal([1, 1, 0])

func test_a_returning_crew_with_teams_turned_off_is_solo() -> void:
	GameState.start_session([0, 1] as Array[int])
	GameState.teams = [1, 0, S, S, S, S] as Array[int]
	await lobby(false)
	assert_array(GameState.teams).is_equal([S, S, S, S, S, S])

func test_a_returning_crew_with_teams_turned_on_is_sorted_onto_sides() -> void:
	GameState.start_session([0, 1, 2] as Array[int])
	await lobby(true)
	assert_array(GameState.teams.slice(0, 3)).is_equal([0, 1, 2])

func test_team_rings_show_in_the_arena() -> void:
	await alpha_v_beta()
	assert_bool(ship(0).has_node("Ship/TeamRing")).is_true()

func test_a_team_with_a_ship_left_is_still_in() -> void:
	await alpha_v_beta()
	kill([0])
	await eliminated([0])
	assert_str(results_title()).is_equal("none")

func test_the_last_team_flying_wins_and_is_named() -> void:
	await alpha_v_beta()
	kill([0])
	await eliminated([0])
	kill([2, 3])
	var shown := await results()
	assert_str(results_title()).is_equal("Team Alpha Wins!")
	assert_str(shown.subtitle.text).is_equal("Red & Lime")

func test_every_member_gets_the_win_even_the_dead() -> void:
	await alpha_v_beta()
	kill([0])
	await eliminated([0])
	kill([2, 3])
	await results()
	assert_array(GameState.wins.slice(0, 4)).is_equal([1, 1, 0, 0])

func test_a_pair_and_a_solo_left_is_no_win_yet() -> void:
	await new_round([0, 1, 2, 3], [0, 0, S, S, S, S])
	kill([2])
	await eliminated([2])
	assert_str(results_title()).is_equal("none")

func test_a_pair_beats_solos() -> void:
	await new_round([0, 1, 2, 3], [0, 0, S, S, S, S])
	kill([2])
	await eliminated([2])
	kill([3])
	await results()
	assert_str(results_title()).is_equal("Team Alpha Wins!")

func test_the_hud_shows_team_totals() -> void:
	await alpha_v_beta(1)
	ship(2).destroy(0)
	ship(3).destroy(1)
	ship(0).destroy(2)
	assert_str(scene().get_node("HUD").side_scores.text).is_equal("Alpha 2  -  Beta 1")

func test_most_team_kills_wins() -> void:
	var round := await alpha_v_beta(1)
	ship(2).destroy(0)
	ship(3).destroy(1)
	ship(0).destroy(2)
	round.mode.clock.start(0.05)
	await results()
	assert_str(results_title()).is_equal("Team Alpha Wins!")

# Alpha and Beta a kill each, then the clock runs out
func tied_teams() -> Node:
	var round := await alpha_v_beta(1)
	ship(2).destroy(0)
	ship(0).destroy(3)
	await respawned(2)
	await respawned(0)
	round.mode.clock.start(0.05)
	await wait_until(func(): return round.mode.sudden_death)
	return round

func test_tied_teams_all_go_to_sudden_death() -> void:
	var round := await tied_teams()
	assert_bool(round.mode.sudden_death).is_true()
	assert_array(alive()).is_equal([0, 1, 2, 3])

func test_the_last_team_in_sudden_death_wins() -> void:
	await tied_teams()
	kill([2, 3])
	await results()
	assert_str(results_title()).is_equal("Team Alpha Wins!")
