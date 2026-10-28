extends RoundSuite
# The match rules come from the saved settings: Last Ship Standing starts every ship on the lives setting and
# Time Attack runs its clock for the time setting, so a match can be set up before any screen offers it.

func speed() -> float:
	return 4.0

func lives_round(lives: int, seats: Array[int] = [0, 1]) -> Node:
	GameSettings.set_setting("lives", lives)
	return await new_round(seats)

func test_ships_start_on_the_lives_setting() -> void:
	await lives_round(5)
	for flying in ships():
		assert_int(flying.lives).is_equal(5)

func test_the_hud_shows_a_pill_for_each_life() -> void:
	await lives_round(5)
	var hud: Node = scene().get_node("HUD")
	assert_int(hud.lives[0]).is_equal(5)
	assert_int(hud.pill_slots[1]).is_equal(5)

func test_five_lives_keep_every_pilot_block_on_screen() -> void:
	await lives_round(5, [0, 1, 2, 3, 4, 5])
	var hud: Node = scene().get_node("HUD")
	var screen := get_tree().root.get_visible_rect()
	for pilot in hud.shown_players():
		assert_bool(screen.encloses(hud.block_rect(pilot))) \
			.override_failure_message("pilot %d block off screen: %s" % [pilot + 1, hud.block_rect(pilot)]).is_true()

func test_with_one_life_a_kill_ends_the_round() -> void:
	await lives_round(1)
	ship(0).destroy(1)
	await results()
	assert_str(results_title()).is_equal("Lime Wins!")

func test_a_rematch_keeps_the_lives() -> void:
	await lives_round(1)
	ship(0).destroy(1)
	await results()
	await press("shoot0")
	await settle()
	await ships_launched()
	assert_int(ship(0).lives).is_equal(1)

func time_attack_round(minutes: int) -> Node:
	GameSettings.set_setting("time_minutes", minutes)
	return await new_round([0, 1], [], 1)

func test_the_clock_runs_for_the_time_setting() -> void:
	var round := await time_attack_round(5)
	assert_float(round.mode.clock.wait_time).is_equal(300.0)
	assert_array(["5:00", "4:59"]).contains([scene().get_node("HUD").clock.text])

func test_one_minute_is_a_minute() -> void:
	var round := await time_attack_round(1)
	assert_float(round.mode.clock.wait_time).is_equal(60.0)
	assert_array(["1:00", "0:59"]).contains([scene().get_node("HUD").clock.text])

func test_a_rematch_keeps_the_time() -> void:
	var round := await time_attack_round(3)
	round.mode.end_round([1] as Array[int])
	await results()
	await press("shoot0")
	await settle()
	await ships_launched()
	assert_float(scene().mode.clock.wait_time).is_equal(180.0)
