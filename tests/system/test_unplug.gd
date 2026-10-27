extends GameSuite
# Pads that come and go. Mid-round, unplugging a seated pilot's pad pauses the game and the panel asks for it
# back in that pilot's ink; plugging it in clears the ask but leaves the game paused for someone to resume.
# Pads with no pilot (no seat, an empty seat, a dummy's) don't pause anything, nor does unplugging on the
# results or mid screen change. In the lobby, an unplugged pad's seat empties.

var pause_menu: Control

func speed() -> float:
	return 4.0

# Tells everyone listening, as Godot does; no pads are really connected headless
func unplug(device: int) -> void:
	Input.joy_connection_changed.emit(device, false)
	await frames(1)

func plug_in(device: int) -> void:
	Input.joy_connection_changed.emit(device, true)
	await frames(1)

func round_with(seats: Array[int], dummies: Array[int] = []) -> void:
	await start_round(seats, dummies)
	pause_menu = scene().get_node("PauseMenu/UI")

func test_unplugging_a_pilots_pad_pauses_and_asks_for_it() -> void:
	await round_with([0, 1])
	await unplug(1)
	assert_bool(get_tree().paused).is_true()
	assert_bool(pause_menu.visible).is_true()
	assert_str(pause_menu.paused_by.text).is_equal("Plug in Lime's controller")
	assert_object(pause_menu.panel.get_theme_stylebox("panel").border_color).is_equal(GameConfig.PLAYER_COLORS[1])

func test_two_pads_out_are_both_asked_for() -> void:
	await round_with([0, 1, 2])
	await unplug(2)
	await unplug(1)
	assert_str(pause_menu.paused_by.text).is_equal("Plug in Tangerine's & Lime's controllers")

func test_plugging_back_in_clears_the_ask_but_stays_paused() -> void:
	await round_with([0, 1])
	await unplug(1)
	await plug_in(1)
	assert_bool(get_tree().paused).is_true()
	assert_bool(pause_menu.visible).is_true()
	assert_str(pause_menu.paused_by.text).not_contains("Plug in")

func test_one_back_of_two_still_asks_for_the_other() -> void:
	await round_with([0, 1, 2])
	await unplug(1)
	await unplug(2)
	await plug_in(1)
	assert_str(pause_menu.paused_by.text).is_equal("Plug in Tangerine's controller")

func test_unplugging_while_paused_asks_for_it() -> void:
	await round_with([0, 1])
	await pad(JOY_BUTTON_START, 0)
	await unplug(1)
	assert_bool(pause_menu.visible).is_true()
	assert_str(pause_menu.paused_by.text).is_equal("Plug in Lime's controller")

func test_you_can_still_resume_with_a_pad_out() -> void:
	await round_with([0, 1])
	await unplug(1)
	await pad(JOY_BUTTON_START, 0)
	assert_bool(get_tree().paused).is_false()

func test_pads_without_a_pilot_dont_pause() -> void:
	await round_with([0], [1])
	await unplug(1)
	await unplug(4)
	await unplug(7)
	assert_bool(get_tree().paused).is_false()

func test_unplugging_on_results_leaves_them_be() -> void:
	await round_with([0, 1])
	kill([1])
	await results()
	await unplug(0)
	assert_bool(pause_menu.visible).is_false()

func test_unplugging_mid_change_does_nothing() -> void:
	var round := await start_round([0, 1])
	SceneManager.go_to("res://main.tscn")
	await frames(1)
	await unplug(1)
	assert_bool(round.get_node("PauseMenu/UI").visible).is_false()
	await settle()
	assert_bool(get_tree().paused).is_false()

func test_in_the_lobby_an_unplugged_pads_seat_empties() -> void:
	var menu := await open("res://menu.tscn")
	await frames(2)
	await press("shoot2")
	await press("shoot3")
	await press("shoot3")
	await unplug(2)
	await unplug(3)
	assert_array(menu.seated_players()).is_empty()
	assert_str(menu.status.text).contains("unplugged")

func test_in_the_lobby_an_empty_seats_pad_changes_nothing() -> void:
	var menu := await open("res://menu.tscn")
	await frames(2)
	await press("shoot2")
	await unplug(4)
	assert_array(menu.seated_players()).is_equal([2])
