extends GameSuite
# UI sounds: each press in the title, lobby and results plays the sound for what it did - confirm, seat,
# ready, back, focus, a tick a second for the launch countdown - and a press that does nothing is silent.

func speed() -> float:
	return 4.0

var mark := 0

func before_test() -> void:
	super()
	mark = Sound.next_player_index

# The sounds played since the last call, read off the pool in the order it hands out players. Each step
# plays far fewer than the pool size.
func played() -> Array:
	var names := []
	while mark != Sound.next_player_index:
		names.append(Sound.sounds.find_key(Sound.players[mark].stream))
		mark = (mark + 1) % Sound.players.size()
	return names

func lobby(dummy_pilot := false) -> void:
	await open("res://menu.tscn")
	GameState.dummy_pilot = dummy_pilot
	await frames(2)
	played()

func test_a_title_press_confirms() -> void:
	await open("res://title.tscn")
	await seconds(GameConfig.TITLE_INTRO_TIME + 0.2)
	played()
	await press("shoot0")
	assert_array(played()).is_equal(["confirm"])

func test_arriving_seated_from_the_title_is_silent() -> void:
	await open("res://title.tscn")
	await seconds(GameConfig.TITLE_INTRO_TIME + 0.2)
	await press("shoot0")
	played()
	await settle()
	await frames(1)
	assert_array(played()).is_empty()

func test_taking_a_seat_plays_seat() -> void:
	await lobby()
	await press("shoot1")
	assert_array(played()).is_equal(["seat"])

func test_readying_plays_ready() -> void:
	await lobby()
	await press("shoot1")
	played()
	await press("shoot1")
	assert_array(played()).is_equal(["ready"])

func test_a_lone_ready_pilot_against_a_dummy_starts_the_countdown_ticking() -> void:
	await lobby(true)
	await press("shoot0")
	played()
	await press("shoot0")
	assert_array(played()).is_equal(["ready", "tick"])

func test_unreadying_and_leaving_play_back() -> void:
	await lobby()
	await press("shoot0")
	await press("shoot0")
	played()
	await press("rotate_left0")
	assert_array(played()).is_equal(["back"])
	await press("rotate_left0")
	assert_array(played()).is_equal(["back"])

func test_nothing_to_back_out_of_is_silent() -> void:
	await lobby()
	await press("rotate_left0")
	assert_array(played()).is_empty()

func test_changing_mode_plays_focus() -> void:
	await lobby()
	await press("shoot1")
	played()
	await press("rotate_right1")
	assert_array(played()).is_equal(["focus"])
	await press("rotate_right1")
	assert_array(played()).is_equal(["focus"])

func test_changing_team_plays_focus() -> void:
	await lobby()
	await press("shoot1")
	played()
	await press("thrust1")
	assert_array(played()).is_equal(["focus"])
	await press("thrust1")
	assert_array(played()).is_equal(["focus"])

func test_an_empty_seat_cant_change_mode_so_its_silent() -> void:
	await lobby()
	await press("rotate_right2")
	assert_array(played()).is_empty()

func test_the_second_pilot_readying_starts_the_countdown() -> void:
	await lobby()
	await press("shoot0")
	await press("shoot0")
	await press("shoot1")
	await press("shoot1")
	assert_array(played()).is_equal(["seat", "ready", "seat", "ready", "tick"])

func test_the_countdown_ticks_each_second_then_launch_confirms() -> void:
	await lobby()
	for seat in [0, 1]:
		await press("shoot%d" % seat)
		await press("shoot%d" % seat)
	played()
	await seconds(GameConfig.TITLE_LAUNCH_DELAY + 0.3)
	var launch := ["tick"] + played()
	assert_int(launch.count("tick")).is_equal(ceili(GameConfig.TITLE_LAUNCH_DELAY))
	assert_str(launch.back()).is_equal("confirm")

func round_results() -> Node:
	await start_round([0, 1])
	kill([1])
	var shown := await results()
	played()
	return shown

func test_moving_between_results_buttons_plays_focus() -> void:
	await round_results()
	await press("rotate_right0")
	assert_array(played()).is_equal(["focus"])
	await press("rotate_left0")
	assert_array(played()).is_equal(["focus"])

func test_pressing_towards_the_focused_button_is_silent() -> void:
	await round_results()
	await press("rotate_right0")
	played()
	await press("rotate_right0")
	assert_array(played()).is_empty()

func test_choosing_rematch_confirms_once() -> void:
	await round_results()
	await press("shoot0")
	assert_array(played()).is_equal(["confirm"])
	await press("shoot0")
	assert_array(played()).is_empty()
