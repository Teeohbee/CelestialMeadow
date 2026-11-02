extends RoundSuite
# Time Attack: picked in the match setup, endless respawns against the clock where kills score and crashes
# don't. Most kills at time up wins; a tie goes to sudden death with one life each.

func speed() -> float:
	return 4.0

# Time Attack chosen in the match setup, then pilots 0 and 1 seat and ready in the lobby
func launched_in_time_attack() -> void:
	await open("res://match_setup.tscn")
	await frames(1)
	await press("ui_up")
	await press("ui_up")
	await press("ui_up")
	await press("ui_right")
	while scene().selected != "Pick seats":
		await press("ui_down")
	await press("ui_accept")
	await settle()
	GameState.dummy_pilot = false
	for seat in [0, 1]:
		await press("shoot%d" % seat)
		await press("shoot%d" % seat)
	await seconds(GameConfig.TITLE_LAUNCH_DELAY + 0.2)
	await settle()

func time_attack(seats: Array[int] = [0, 1]) -> Node:
	return await new_round(seats, [], 1)

# Pilot 1 kills pilot 0 twice, pilot 0 crashes nothing
func lime_leads() -> Node:
	var round := await time_attack()
	ship(0).destroy(1)
	await respawned(0)
	ship(0).destroy(1)
	ship(1).destroy(-1)
	return round

func time_up(round: Node) -> void:
	round.mode.clock.start(0.05)
	await wait_until(func(): return round.mode.clock.is_stopped())
	await frames(1)

# Pilots 0 and 1 tie on a kill each with pilot 2 seated, and the clock runs out
func tied_at_time_up() -> Node:
	var round := await time_attack([0, 1, 2])
	ship(2).destroy(0)
	ship(0).destroy(1)
	await respawned(2)
	await respawned(0)
	await time_up(round)
	return round

func test_time_attack_is_the_second_mode() -> void:
	assert_str(GameState.MODES[1].name).is_equal("Time Attack")

func test_classic_is_the_default() -> void:
	await open("res://menu.tscn")
	await frames(1)
	assert_int(GameState.mode_index).is_equal(0)

func test_time_attack_from_match_setup_runs_the_round() -> void:
	await launched_in_time_attack()
	assert_str(scene().name).is_equal("Main")
	assert_str(scene().mode.name).is_equal("TimeAttack")

func test_the_clock_counts_down_from_two_minutes() -> void:
	await time_attack()
	assert_array(["2:00", "1:59"]).contains([scene().get_node("HUD").clock.text])

func test_ships_respawn_with_no_lives_limit() -> void:
	await time_attack()
	var pilot := ship(0)
	pilot.destroy(1)
	assert_bool(await respawned(0)).is_true()
	assert_object(ship(0)).is_same(pilot)

func test_kills_score_and_crashes_dont() -> void:
	var round := await lime_leads()
	assert_dict(round.mode.scores).is_equal({0: 0, 1: 2})

func test_the_hud_shows_kills() -> void:
	await lime_leads()
	assert_int(scene().get_node("HUD").scores.get(1)).is_equal(2)

func test_most_kills_wins_at_time_up() -> void:
	await time_up(await lime_leads())
	await results()
	assert_str(results_title()).is_equal("Lime Wins!")
	assert_array(GameState.wins).is_equal([0, 1, 0, 0, 0, 0])

func test_the_results_show_the_rounds_kills() -> void:
	await time_up(await lime_leads())
	var shown := await results()
	assert_str(shown.tally.get_child(1).get_node("Kills").text).is_equal("2 kills")

func test_a_rematch_keeps_the_mode() -> void:
	await time_up(await lime_leads())
	await results()
	await press("shoot0")
	await settle()
	assert_str(scene().name).is_equal("Main")
	assert_str(scene().mode.name).is_equal("TimeAttack")

func test_a_tie_starts_sudden_death_instead_of_ending() -> void:
	var round := await tied_at_time_up()
	assert_object(scene().get_node_or_null("Results")).is_null()
	assert_bool(round.mode.sudden_death).is_true()
	assert_bool(scene().get_node("HUD").banner.visible).is_true()

func test_only_the_tied_ships_remain_with_one_life_each() -> void:
	await tied_at_time_up()
	await frames(1)
	assert_array(alive()).is_equal([0, 1])
	assert_int(ship(0).lives).is_equal(1)
	assert_int(ship(1).lives).is_equal(1)

func test_the_last_ship_in_sudden_death_wins() -> void:
	await tied_at_time_up()
	ship(0).destroy(1)
	await results()
	assert_str(results_title()).is_equal("Lime Wins!")

func test_reaching_the_kill_target_wins_before_time_up() -> void:
	GameSettings.set_setting("kill_target", 2)
	await lime_leads()
	await results()
	assert_str(results_title()).is_equal("Lime Wins!")
	assert_array(GameState.wins).is_equal([0, 1, 0, 0, 0, 0])

func test_a_teams_kills_count_together_towards_the_target() -> void:
	GameSettings.set_setting("kill_target", 2)
	await new_round([0, 1, 2], [0, 0, 1, GameState.SOLO, GameState.SOLO, GameState.SOLO], 1)
	ship(2).destroy(0)
	await respawned(2)
	ship(2).destroy(1)
	await results()
	assert_str(results_title()).is_equal("Team Alpha Wins!")

func test_with_win_at_off_kills_never_end_the_round() -> void:
	await lime_leads()
	await seconds(1.0)
	assert_object(scene().get_node_or_null("Results")).is_null()

func test_the_hud_shows_the_kill_target() -> void:
	GameSettings.set_setting("kill_target", 10)
	await time_attack()
	var goal: Label = scene().get_node("HUD").goal
	assert_bool(goal.visible).is_true()
	assert_str(goal.text).is_equal("First to 10")

func test_the_hud_shows_no_target_when_win_at_is_off() -> void:
	await time_attack()
	assert_bool(scene().get_node("HUD").goal.visible).is_false()
