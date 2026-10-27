extends GameSuite
# The options overlay in the lobby: any pad's View opens it, the D-pad picks a row and changes it live and
# saved, volumes stop at 0 and 10 and 0 mutes, fullscreen toggles, B, Esc, Back or View close it, and while
# it's open it takes every press so nobody joins and nothing launches behind it.

var menu: Node
var options: Control

# A real pad button, so every action bound to it fires together
func pad(button: JoyButton, device := 0) -> void:
	var down := InputEventJoypadButton.new()
	down.device = device
	down.button_index = button
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up: InputEventJoypadButton = down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame

func bus_db(bus_name: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))

func lobby() -> void:
	menu = await open("res://menu.tscn")
	await frames(2)
	options = menu.get_node("Options")

func opened() -> void:
	await lobby()
	await pad(JOY_BUTTON_BACK, 3)

func row_name() -> String:
	return options.rows[options.selected].name

func test_the_lobby_has_options_closed() -> void:
	await lobby()
	assert_bool(options.visible).is_false()

func test_the_corner_hint_shows_view() -> void:
	await lobby()
	assert_bool(menu.get_node("OptionsButton").visible).is_true()
	assert_str(menu.options_prompt.text).contains("{view}")

func test_any_pads_view_opens_options_on_music() -> void:
	await opened()
	assert_bool(options.visible).is_true()
	assert_str(row_name()).is_equal("Music")

func test_options_cover_the_screen_with_the_panel_centred() -> void:
	await opened()
	await frames(1)
	var screen := get_tree().root.get_visible_rect()
	assert_vector(options.size).is_equal(screen.size)
	assert_float(options.panel.get_global_rect().get_center().distance_to(screen.get_center())).is_less(2.0)

func test_d_pad_left_turns_music_down_live() -> void:
	await opened()
	await pad(JOY_BUTTON_DPAD_LEFT, 0)
	assert_int(GameSettings.get_setting("music_volume")).is_equal(7)
	assert_float(bus_db("Music")).is_equal_approx(linear_to_db(0.7), 0.001)

func test_a_pads_d_pad_goes_to_options_not_the_lobby() -> void:
	await opened()
	await pad(JOY_BUTTON_DPAD_LEFT, 0)
	assert_int(menu.combo_steps[0]).is_equal(0)

func test_another_pads_d_pad_right_turns_it_back_up_and_saves() -> void:
	await opened()
	await pad(JOY_BUTTON_DPAD_LEFT, 0)
	await pad(JOY_BUTTON_DPAD_RIGHT, 2)
	assert_int(GameSettings.get_setting("music_volume")).is_equal(8)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(scratch_path))
	assert_int(int(saved.settings.music_volume)).is_equal(8)

func test_d_pad_down_selects_sounds() -> void:
	await opened()
	await pad(JOY_BUTTON_DPAD_DOWN, 1)
	assert_str(row_name()).is_equal("Sounds")

func test_sound_bottoms_out_at_zero_and_mutes() -> void:
	await opened()
	await press("ui_down")
	for i in 12:
		await press("ui_left")
	assert_int(GameSettings.get_setting("sound_volume")).is_equal(0)
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index("Sounds"))).is_true()
	await press("ui_right")
	assert_int(GameSettings.get_setting("sound_volume")).is_equal(1)

func test_a_on_options_doesnt_take_a_seat() -> void:
	await opened()
	await pad(JOY_BUTTON_A, 4)
	assert_int(menu.cards[4].state).is_equal(0)

func test_fullscreen_comes_after_sounds() -> void:
	await opened()
	await press("ui_down")
	await press("ui_down")
	assert_str(row_name()).is_equal("Fullscreen")

func test_right_toggles_fullscreen_and_the_row_shows_it() -> void:
	await opened()
	await press("ui_down")
	await press("ui_down")
	await press("ui_right")
	assert_bool(GameSettings.get_setting("fullscreen")).is_false()
	assert_str(options.values[options.selected].text).is_equal("Off")

func test_a_and_left_toggle_fullscreen_too() -> void:
	await opened()
	await press("ui_down")
	await press("ui_down")
	await press("ui_accept")
	assert_bool(GameSettings.get_setting("fullscreen")).is_false()
	await press("ui_left")
	assert_bool(GameSettings.get_setting("fullscreen")).is_true()

func test_up_from_music_wraps_to_back() -> void:
	await opened()
	await press("ui_up")
	assert_str(row_name()).is_equal("Back")

func test_back_closes_options() -> void:
	await opened()
	await press("ui_up")
	await press("ui_accept")
	assert_bool(options.visible).is_false()

func test_tab_opens_options() -> void:
	await lobby()
	await press("options")
	assert_bool(options.visible).is_true()

func test_b_closes_options_without_asking_to_quit() -> void:
	await opened()
	await pad(JOY_BUTTON_B, 5)
	assert_bool(options.visible).is_false()
	assert_bool(menu.quit_confirm.visible).is_false()

func test_esc_closes_options_only() -> void:
	await opened()
	await press("ui_cancel")
	assert_bool(options.visible).is_false()
	assert_bool(menu.quit_confirm.visible).is_false()

func test_view_again_closes_options() -> void:
	await lobby()
	await press("options")
	await press("options")
	assert_bool(options.visible).is_false()

func test_nothing_launches_while_options_are_open() -> void:
	await lobby()
	GameState.dummy_pilot = true
	await press("shoot0")
	await press("shoot0")
	await press("options")
	await seconds(GameConfig.TITLE_LAUNCH_DELAY + 0.5)
	assert_object(scene()).is_same(menu)
	assert_bool(SceneManager.is_changing_scene).is_false()
	assert_str(menu.status.text).not_contains("Launching")
