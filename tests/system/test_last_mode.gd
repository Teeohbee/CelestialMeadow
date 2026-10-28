extends GameSuite
# The last match is remembered: the match setup saves it when Pick seats is pressed, not as rows change, and
# opens on it next time, this session or the next. The lobby shows it as chips and can't change it.

func speed() -> float:
	return 4.0

func setup() -> Node:
	var screen := await open("res://match_setup.tscn")
	await frames(1)
	return screen

# Up from Pick seats to the Mode row and one along, to Time Attack
func flick_to_time_attack() -> void:
	while scene().selected != "Mode":
		await press("ui_up")
	await press("ui_right")

func pick_seats() -> void:
	while scene().selected != "Pick seats":
		await press("ui_down")
	await press("ui_accept")
	await settle()

func chips() -> Array:
	return scene().chips.get_children().map(func(chip): return chip.get_child(0).text)

func test_flicking_through_modes_doesnt_save() -> void:
	await setup()
	await flick_to_time_attack()
	assert_int(GameSettings.get_setting("last_mode")).is_equal(0)

func test_pick_seats_saves_the_mode_to_disk() -> void:
	await setup()
	await flick_to_time_attack()
	await pick_seats()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(scratch_path))
	assert_int(int(saved.settings.last_mode)).is_equal(1)

func test_the_lobby_shows_the_match_as_chips() -> void:
	await setup()
	await flick_to_time_attack()
	await pick_seats()
	assert_array(chips()).is_equal(["Time Attack", "Free for all", "2 min"])

func test_chips_show_teams_and_lives() -> void:
	GameSettings.set_setting("teams", true)
	GameSettings.set_setting("lives", 1)
	await open("res://menu.tscn")
	await frames(1)
	assert_array(chips()).is_equal(["Last Ship Standing", "Teams", "1 life"])

func test_a_seated_pilot_cant_change_the_mode_in_the_lobby() -> void:
	var menu := await open("res://menu.tscn")
	await frames(1)
	await press("shoot0")
	await press("rotate_right0")
	assert_int(GameState.mode_index).is_equal(0)
	assert_array(chips()).is_equal(["Last Ship Standing", "Free for all", "3 lives"])
	assert_object(scene()).is_same(menu)

func test_change_match_after_a_round_opens_on_it() -> void:
	await setup()
	await flick_to_time_attack()
	await pick_seats()
	GameState.dummy_pilot = true
	await press("shoot0")
	await press("shoot0")
	await seconds(GameConfig.TITLE_LAUNCH_DELAY + 0.2)
	await settle()
	assert_str(scene().name).is_equal("Main")
	scene().get_node("PauseMenu/UI")._on_change_match_button_pressed()
	await settle()
	assert_str(scene().get_row("Mode").value_label.text).is_equal("Time Attack")
