extends GameSuite
# The base suite's reset: whatever one test leaves behind, the next starts clean. These run in order, each
# leaving a mess for the one after to check.

func test_a_test_saves_a_mode_and_leaves_a_change_in_flight() -> void:
	await open("res://menu.tscn")
	GameSettings.set_setting("last_mode", 1)
	GameState.mode_index = 1
	GameState.players.assign([0, 3])
	GameState.join_on_arrival = 2
	get_tree().paused = true
	SceneManager.go_to("res://title.tscn")
	assert_bool(SceneManager.is_changing_scene).is_true()

func test_the_next_test_sees_the_default_mode() -> void:
	assert_int(GameSettings.get_setting("last_mode")).is_equal(0)
	assert_int(GameState.mode_index).is_equal(0)

func test_the_next_test_sees_a_fresh_game_state() -> void:
	assert_array(GameState.players).is_empty()
	assert_int(GameState.join_on_arrival).is_equal(-1)

func test_the_next_test_starts_with_no_screen_and_nothing_moving() -> void:
	assert_object(scene()).is_null()
	assert_bool(SceneManager.is_changing_scene).is_false()
	assert_bool(get_tree().paused).is_false()

func test_settings_save_to_a_scratch_file_not_the_players() -> void:
	assert_str(GameSettings.save_file_path).is_equal(scratch_path)
	assert_str(scratch_path).is_not_equal("user://settings.json")
