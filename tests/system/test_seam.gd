extends RoundSuite
# The seam between ships and the round's rules: a kill credits the shooter, a crash credits nobody, and classic
# rules run the round unless a mode says otherwise.

var deaths: Array = []

func speed() -> float:
	return 4.0

func watch_deaths() -> void:
	deaths.clear()
	for flying in ships():
		flying.killed.connect(func(victim, killer): deaths.append([victim, killer]))

func test_a_bullet_credits_the_shooter() -> void:
	await start_round([0, 1, 2])
	watch_deaths()
	await fire(1, 0)
	assert_array(deaths).is_equal([[0, 1]])

func test_no_shooter_credits_nobody() -> void:
	await start_round([0, 1, 2])
	watch_deaths()
	ship(2).destroy()
	assert_array(deaths).is_equal([[2, -1]])

func test_classic_rules_run_the_round() -> void:
	await start_round([0, 1, 2])
	assert_object(scene().get_node_or_null("LastShipStanding")).is_not_null()
