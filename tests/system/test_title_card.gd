extends GameSuite
# The title screen: after the splash it sits on the arena backdrop, ignores presses until the intro is done, then
# any press goes to the match setup, and a player's shoot button takes their seat in the lobby after it. B, Menu
# or Esc ask before quitting, with Stay focused.

func speed() -> float:
	return 4.0

func seats() -> Array:
	return scene().cards.map(func(c): return c.state)

func asteroids() -> int:
	return scene().get_node("Backdrop").get_children().filter(func(c): return c.is_in_group("asteroids")).size()

# Opens the title and waits out the intro
func ready_title() -> void:
	await open("res://title.tscn")
	await seconds(GameConfig.TITLE_INTRO_TIME + 0.2)

func test_no_godot_logo_on_boot() -> void:
	assert_bool(ProjectSettings.get_setting("application/boot_splash/show_image")).is_false()

func test_it_boots_on_the_ground_colour_not_black() -> void:
	var splash: Color = ProjectSettings.get_setting("application/boot_splash/bg_color")
	assert_str(splash.to_html()).is_equal(GameConfig.GROUND.to_html())

func test_the_title_sits_on_the_arena_backdrop_with_grain() -> void:
	var title := await open("res://title.tscn")
	assert_bool(title.has_node("ArenaBackdrop")).is_true()
	assert_bool(title.has_node("Grain")).is_true()
	assert_bool(title.has_node("Background")).is_false()

func test_the_title_fades_through_the_ground_colour() -> void:
	var title := await open("res://title.tscn")
	assert_str(title.fade.color.to_html()).is_equal(GameConfig.GROUND.to_html())

func test_asteroids_drift_behind_the_title() -> void:
	await open("res://title.tscn")
	await frames(2)
	assert_int(asteroids()).is_greater(0)

func test_presses_during_the_intro_are_ignored() -> void:
	await open("res://title.tscn")
	await press("shoot1")
	await seconds(GameConfig.TITLE_INTRO_TIME + 0.2)
	await settle()
	assert_str(scene().name).is_equal("Title")

func test_the_prompt_shows_after_the_intro() -> void:
	await ready_title()
	assert_bool(scene().prompt.visible).is_true()
	assert_str(scene().prompt.text).is_equal("Press any button")

func asking_to_quit() -> bool:
	return scene().quit_confirm.visible

func test_esc_asks_before_quitting_and_doesnt_leave() -> void:
	await ready_title()
	await key(KEY_ESCAPE)
	await settle()
	assert_str(scene().name).is_equal("Title")
	assert_bool(asking_to_quit()).is_true()

func test_b_asks_before_quitting_with_stay_focused() -> void:
	await ready_title()
	await pad(JOY_BUTTON_B, 3)
	assert_bool(asking_to_quit()).is_true()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(scene().stay_button)

func test_menu_asks_too() -> void:
	await ready_title()
	await pad(JOY_BUTTON_START, 1)
	assert_bool(asking_to_quit()).is_true()

func test_b_again_stays() -> void:
	await ready_title()
	await pad(JOY_BUTTON_B, 3)
	await pad(JOY_BUTTON_B, 3)
	assert_bool(asking_to_quit()).is_false()
	assert_str(scene().name).is_equal("Title")

func test_a_on_stay_stays() -> void:
	await ready_title()
	await pad(JOY_BUTTON_B, 0)
	await pad(JOY_BUTTON_A, 0)
	await settle()
	assert_bool(asking_to_quit()).is_false()
	assert_str(scene().name).is_equal("Title")

func test_right_moves_to_quit() -> void:
	await ready_title()
	await pad(JOY_BUTTON_B, 0)
	await pad(JOY_BUTTON_DPAD_RIGHT, 0)
	assert_str(get_viewport().gui_get_focus_owner().name).is_equal("ConfirmQuitButton")

func test_a_press_goes_to_match_setup() -> void:
	await ready_title()
	await press("shoot2")
	await settle()
	assert_str(scene().name).is_equal("MatchSetup")

func test_a_shoot_press_seats_that_player_in_the_lobby() -> void:
	await ready_title()
	await press("shoot2")
	await settle()
	await press("ui_accept")
	await settle()
	assert_str(scene().name).is_equal("Menu")
	assert_array(seats()).is_equal([0, 0, 1, 0, 0, 0])

func test_a_then_a_reaches_the_lobby_on_the_last_match() -> void:
	GameSettings.set_setting("last_mode", 1)
	await ready_title()
	await pad(JOY_BUTTON_A, 0)
	await settle()
	await pad(JOY_BUTTON_A, 0)
	await settle()
	assert_str(scene().name).is_equal("Menu")
	assert_int(GameState.mode_index).is_equal(1)
	assert_array(seats()).is_equal([1, 0, 0, 0, 0, 0])

func test_match_setup_still_has_its_asteroids() -> void:
	await ready_title()
	await press("shoot2")
	await settle()
	assert_int(asteroids()).is_greater(0)

func test_any_other_key_just_continues() -> void:
	await ready_title()
	await key(KEY_ENTER)
	await settle()
	assert_str(scene().name).is_equal("MatchSetup")
	assert_int(GameState.join_on_arrival).is_equal(-1)
