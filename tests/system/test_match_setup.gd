extends GameSuite
# Match setup: the mode and its rules, chosen on a list before anyone takes a seat. Any pad drives it. Up and
# down pick a row, left and right change it (Mode and Teams wrap, numbers stop at their ends), A on Pick seats
# saves the match and goes to the lobby with that pad seated, B goes back to the title and View opens the
# options. It opens on the last match set up, with Pick seats selected.

func speed() -> float:
	return 4.0

var setup: Node
var mark := 0

func before_test() -> void:
	super()
	mark = Sound.next_player_index

func opened() -> Node:
	setup = await open("res://match_setup.tscn")
	await frames(2)
	played()
	return setup

func shown() -> Array:
	return setup.shown_rows().map(func(row): return row.name)

func value_of(row_name: String) -> String:
	return setup.get_row(row_name).value_label.text

# Up from Pick seats until this row is selected
func select(row_name: String) -> void:
	while setup.selected != row_name:
		await press("ui_up")
	played()

func played() -> Array:
	var names := []
	while mark != Sound.next_player_index:
		names.append(Sound.sounds.find_key(Sound.players[mark].stream))
		mark = (mark + 1) % Sound.players.size()
	return names

func test_it_opens_on_pick_seats() -> void:
	await opened()
	assert_str(setup.selected).is_equal("Pick seats")

func test_last_ship_standing_shows_lives() -> void:
	await opened()
	assert_array(shown()).is_equal(["Mode", "Teams", "Lives", "Pick seats"])
	assert_str(value_of("Mode")).is_equal("Last Ship Standing")
	assert_str(value_of("Teams")).is_equal("Off")
	assert_str(value_of("Lives")).is_equal("3")

func test_the_mode_row_explains_the_mode() -> void:
	await opened()
	assert_str(setup.get_row("Mode").blurb.text).is_equal("Last ship flying wins.")

func test_it_opens_on_the_last_match() -> void:
	GameSettings.set_setting("last_mode", 1)
	GameSettings.set_setting("teams", true)
	GameSettings.set_setting("time_minutes", 4)
	await opened()
	assert_array(shown()).is_equal(["Mode", "Teams", "Time", "Win at", "Pick seats"])
	assert_str(value_of("Mode")).is_equal("Time Attack")
	assert_str(value_of("Teams")).is_equal("On")
	assert_str(value_of("Time")).is_equal("4:00")

func test_up_reaches_each_row_in_turn() -> void:
	await opened()
	var visited := []
	for i in 3:
		await press("ui_up")
		visited.append(setup.selected)
	assert_array(visited).is_equal(["Lives", "Teams", "Mode"])
	assert_array(played()).is_equal(["focus", "focus", "focus"])

func test_only_the_selected_row_is_lit() -> void:
	await opened()
	await select("Teams")
	assert_bool(setup.get_row("Teams").selected).is_true()
	assert_bool(setup.get_row("Mode").selected).is_false()

func test_changing_the_mode_swaps_the_rule_row() -> void:
	await opened()
	await select("Mode")
	await press("ui_right")
	assert_str(value_of("Mode")).is_equal("Time Attack")
	assert_array(shown()).is_equal(["Mode", "Teams", "Time", "Win at", "Pick seats"])
	assert_str(value_of("Time")).is_equal("2:00")
	assert_str(value_of("Win at")).is_equal("Off")
	assert_str(setup.get_row("Mode").blurb.text).is_equal("Endless respawns. Most kills wins.")
	assert_array(played()).is_equal(["focus"])

func test_the_mode_wraps_round() -> void:
	await opened()
	await select("Mode")
	await press("ui_left")
	assert_str(value_of("Mode")).is_equal("Time Attack")
	await press("ui_right")
	assert_str(value_of("Mode")).is_equal("Last Ship Standing")

func test_teams_wrap_round() -> void:
	await opened()
	await select("Teams")
	await press("ui_left")
	assert_str(value_of("Teams")).is_equal("On")
	await press("ui_left")
	assert_str(value_of("Teams")).is_equal("Off")

func test_lives_stop_at_five_without_a_sound() -> void:
	await opened()
	await select("Lives")
	for i in 3:
		await press("ui_right")
	assert_str(value_of("Lives")).is_equal("5")
	assert_array(played()).is_equal(["focus", "focus"])

func test_time_stops_at_one_minute() -> void:
	GameSettings.set_setting("last_mode", 1)
	await opened()
	await select("Time")
	for i in 3:
		await press("ui_left")
	assert_str(value_of("Time")).is_equal("1:00")
	assert_array(played()).is_equal(["focus"])

func test_win_at_steps_by_five_kills_up_to_twenty() -> void:
	GameSettings.set_setting("last_mode", 1)
	await opened()
	await select("Win at")
	var seen := []
	for i in 5:
		await press("ui_right")
		seen.append(value_of("Win at"))
	assert_array(seen).is_equal(["5 kills", "10 kills", "15 kills", "20 kills", "20 kills"])
	assert_array(played()).is_equal(["focus", "focus", "focus", "focus"])

func test_win_at_stops_at_off() -> void:
	GameSettings.set_setting("last_mode", 1)
	GameSettings.set_setting("kill_target", 5)
	await opened()
	await select("Win at")
	await press("ui_left")
	await press("ui_left")
	assert_str(value_of("Win at")).is_equal("Off")
	assert_array(played()).is_equal(["focus"])

func test_pick_seats_saves_the_kill_target() -> void:
	GameSettings.set_setting("last_mode", 1)
	await opened()
	await select("Win at")
	await press("ui_right")
	await press("ui_right")
	await select("Pick seats")
	await press("ui_accept")
	assert_int(GameSettings.get_setting("kill_target")).is_equal(10)

func test_a_on_a_value_row_does_nothing() -> void:
	await opened()
	await select("Lives")
	await press("ui_accept")
	assert_str(value_of("Lives")).is_equal("3")
	assert_object(scene()).is_same(setup)
	assert_bool(SceneManager.is_changing_scene).is_false()

func test_nothing_saves_until_pick_seats() -> void:
	await opened()
	await select("Lives")
	await press("ui_right")
	assert_int(GameSettings.get_setting("lives")).is_equal(3)

func test_pick_seats_saves_the_match() -> void:
	await opened()
	await select("Teams")
	await press("ui_right")
	await select("Mode")
	await press("ui_right")
	await select("Time")
	await press("ui_right")
	await select("Pick seats")
	await press("ui_accept")
	assert_int(GameSettings.get_setting("last_mode")).is_equal(1)
	assert_bool(GameSettings.get_setting("teams")).is_true()
	assert_int(GameSettings.get_setting("time_minutes")).is_equal(3)
	assert_int(GameState.mode_index).is_equal(1)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(scratch_path))
	assert_int(int(saved.settings.time_minutes)).is_equal(3)

func test_pick_seats_goes_to_the_lobby() -> void:
	await opened()
	await press("ui_accept")
	assert_array(played()).is_equal(["confirm"])
	await settle()
	assert_str(scene().name).is_equal("Menu")

func test_the_pad_that_picks_seats_is_seated() -> void:
	await opened()
	await pad(JOY_BUTTON_A, 3)
	await settle()
	assert_int(scene().cards[3].state).is_equal(1)
	assert_array(scene().cards.map(func(c): return c.state)).is_equal([0, 0, 0, 1, 0, 0])

func test_picking_seats_twice_changes_scene_once() -> void:
	await opened()
	var before := swaps
	await press("ui_accept")
	await press("ui_accept")
	await settle()
	assert_int(swaps - before).is_equal(1)

func test_b_goes_back_to_the_title() -> void:
	await opened()
	await pad(JOY_BUTTON_B, 2)
	assert_array(played()).is_equal(["back"])
	await settle()
	assert_str(scene().name).is_equal("Title")

func test_view_opens_the_options_over_it() -> void:
	await opened()
	await pad(JOY_BUTTON_BACK, 1)
	assert_bool(setup.options.visible).is_true()

func test_the_options_take_every_press() -> void:
	await opened()
	await press("options")
	await press("ui_up")
	await pad(JOY_BUTTON_B, 0)
	assert_bool(setup.options.visible).is_false()
	assert_str(setup.selected).is_equal("Pick seats")
	assert_object(scene()).is_same(setup)
	assert_bool(SceneManager.is_changing_scene).is_false()

func test_the_corner_prompts_show_pad_buttons() -> void:
	await opened()
	assert_str(setup.options_prompt.text).contains("{view}")
	assert_str(setup.back_prompt.text).contains("{b}")
	assert_str(setup.hint.text).contains("{dpad_up_down}").contains("{dpad_left_right}")

func test_the_rows_are_centred_on_screen() -> void:
	await opened()
	await frames(1)
	var screen := get_tree().root.get_visible_rect()
	assert_float(setup.get_row("Mode").get_global_rect().get_center().x).is_equal_approx(screen.get_center().x, 2.0)
