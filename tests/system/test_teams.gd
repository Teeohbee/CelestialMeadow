extends RoundSuite
# Teams: seated pilots pick one with thrust in the lobby, and a round needs two sides. In Last Ship Standing
# the last side flying wins, every member credited; in Time Attack kills add up per team and tied teams all
# go to sudden death. Friendly fire is in test_ff.gd.

const S := GameState.SOLO

func card_team(seat: int) -> String:
	return scene().cards[seat].team_label.text

# Pilots 0-3 seated in the lobby, all solo
func seated_lobby() -> void:
	await open("res://menu.tscn")
	GameState.dummy_pilot = false
	await frames(2)
	for seat in 4:
		await press("shoot%d" % seat)

func ready_all() -> void:
	for seat in 4:
		await press("shoot%d" % seat)

# Everyone on Alpha and ready
func one_team_lobby() -> void:
	await seated_lobby()
	for seat in 4:
		await press("thrust%d" % seat)
	await ready_all()

func launch() -> void:
	await seconds(GameConfig.TITLE_LAUNCH_DELAY + 0.2)
	await settle()

func alpha_v_beta(mode_index := 0) -> Node:
	return await new_round([0, 1, 2, 3], [0, 0, 1, 1, S, S], mode_index)

func test_everyone_starts_solo() -> void:
	await seated_lobby()
	assert_array(GameState.teams).is_equal([S, S, S, S, S, S])
	assert_str(card_team(0)).is_equal("Free for all")

func test_thrust_joins_alpha() -> void:
	await seated_lobby()
	await press("thrust0")
	assert_int(GameState.teams[0]).is_equal(0)
	assert_str(card_team(0)).is_equal("Team Alpha")

func test_unseated_players_cant_pick_a_team() -> void:
	await seated_lobby()
	await press("thrust4")
	assert_int(GameState.teams[4]).is_equal(S)

func test_all_on_one_team_doesnt_launch() -> void:
	await one_team_lobby()
	await launch()
	assert_str(scene().name).is_equal("Menu")
	assert_str(scene().status.text).is_equal("Pick at least two sides")

func test_changing_team_unreadies_everyone() -> void:
	await one_team_lobby()
	await press("thrust2")
	assert_int(scene().cards[0].state).is_equal(1)

func test_two_sides_launch_and_keep_their_teams() -> void:
	await one_team_lobby()
	await press("thrust2")
	await press("thrust3")
	await ready_all()
	await launch()
	assert_str(scene().name).is_equal("Main")
	assert_array(GameState.teams.slice(0, 4)).is_equal([0, 0, 1, 1])

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
