extends RoundSuite
# Wanted: Time Attack with a price on the leader. Whoever alone has the most kills is Wanted, marked on their
# ship and their HUD corner, and shooting them scores the bounty instead of one. A tie for the lead means
# nobody is Wanted.

const WANTED := 2

func speed() -> float:
	return 4.0

func wanted(seats: Array[int] = [0, 1]) -> Node:
	return await new_round(seats, [], WANTED)

func marked(number: int) -> bool:
	return ship(number).get_node("Ship").has_node("WantedMark")

func test_wanted_follows_time_attack() -> void:
	assert_str(GameState.MODES[WANTED].name).is_equal("Wanted")
	assert_array(GameState.MODES[WANTED].rules).is_equal(["time_minutes"])

func test_nobody_is_wanted_at_the_start() -> void:
	var round := await wanted()
	assert_int(round.mode.wanted).is_equal(-1)
	assert_bool(marked(0) or marked(1)).is_false()

func test_the_first_kill_makes_the_killer_wanted() -> void:
	var round := await wanted()
	ship(0).destroy(1)
	assert_int(round.mode.wanted).is_equal(1)
	assert_bool(marked(1)).is_true()
	assert_int(scene().get_node("HUD").wanted).is_equal(1)

func test_shooting_the_wanted_ship_scores_the_bounty() -> void:
	var round := await wanted()
	ship(0).destroy(1)
	await respawned(0)
	ship(1).destroy(0)
	assert_dict(round.mode.scores).is_equal({0: GameConfig.WANTED_BOUNTY, 1: 1})

func test_the_mark_moves_to_the_new_leader() -> void:
	var round := await wanted()
	ship(0).destroy(1)
	await respawned(0)
	ship(1).destroy(0)
	assert_int(round.mode.wanted).is_equal(0)
	assert_bool(marked(0)).is_true()
	assert_bool(marked(1)).is_false()

func test_a_tie_for_the_lead_means_nobody_is_wanted() -> void:
	var round := await wanted([0, 1, 2])
	ship(0).destroy(1)
	await respawned(0)
	ship(0).destroy(2)
	assert_int(round.mode.wanted).is_equal(-1)
	assert_bool(marked(1) or marked(2)).is_false()
	assert_int(scene().get_node("HUD").wanted).is_equal(-1)

func test_win_at_doesnt_apply() -> void:
	GameSettings.set_setting("kill_target", 2)
	var round := await wanted()
	for i in 2:
		ship(0).destroy(1)
		await respawned(0)
	assert_int(round.mode.scores[1]).is_equal(2)
	await seconds(1.0)
	assert_object(scene().get_node_or_null("Results")).is_null()
	assert_bool(scene().get_node("HUD").goal.visible).is_false()

func test_the_results_count_points() -> void:
	var round := await wanted()
	ship(0).destroy(1)
	await respawned(0)
	ship(1).destroy(0)
	round.mode.clock.start(0.05)
	var shown := await results()
	assert_str(results_title()).is_equal("Red Wins!")
	assert_str(shown.tally.get_child(0).get_node("Kills").text).is_equal("3 points")
	assert_str(shown.tally.get_child(1).get_node("Kills").text).is_equal("1 point")
